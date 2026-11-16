import assert from "node:assert/strict";
import type { AddressInfo } from "node:net";
import { after, before, describe, it } from "node:test";
import type { Server } from "node:http";
import { CronRunTracker, createApp, isAuthorizedHeader } from "../src/app";
import type { Message } from "firebase-admin/messaging";
import { runHitzeCron, type HitzeCronHttpResponse } from "../api/cron/hitze";
import { DAY_STATE_KEY, RedisCronStateStore, type StateUpdate } from "../api/cron/state";
import { createHarness, heatFeature, v2Messages } from "./helpers";

const SECRET = "test-secret-value";

async function start(developMode: boolean, runCron?: (signal: AbortSignal) => Promise<HitzeCronHttpResponse>) {
  const calls: AbortSignal[] = [];
  const app = createApp({
    cronSecret: SECRET,
    developMode,
    tracker: new CronRunTracker(),
    runCron:
      runCron ??
      (async (signal) => {
        calls.push(signal);
        return { status: 200, body: { ok: true } };
      }),
  });
  const server: Server = await new Promise((resolve) => {
    const listening = app.listen(0, "127.0.0.1", () => resolve(listening));
  });
  const base = `http://127.0.0.1:${(server.address() as AddressInfo).port}`;
  return { server, base, calls };
}

const auth = { Authorization: `Bearer ${SECRET}` };

describe("HTTP app", () => {
  let develop: Awaited<ReturnType<typeof start>>;
  let production: Awaited<ReturnType<typeof start>>;

  before(async () => {
    develop = await start(true);
    production = await start(false);
  });

  after(() => {
    develop.server.close();
    production.server.close();
  });

  it("constant-time bearer check", () => {
    assert.equal(isAuthorizedHeader(`Bearer ${SECRET}`, SECRET), true);
    assert.equal(isAuthorizedHeader(`Bearer ${SECRET}x`, SECRET), false);
    assert.equal(isAuthorizedHeader(SECRET, SECRET), false);
    assert.equal(isAuthorizedHeader(undefined, SECRET), false);
    assert.equal(isAuthorizedHeader("Bearer ", SECRET), false);
  });

  it("root page is minimal and carries security headers", async () => {
    for (const target of [develop, production]) {
      const response = await fetch(`${target.base}/`);
      const html = await response.text();
      assert.equal(response.status, 200);
      assert.equal(response.headers.get("x-powered-by"), null);
      assert.equal(response.headers.get("x-content-type-options"), "nosniff");
      assert.match(response.headers.get("content-security-policy") ?? "", /frame-ancestors 'none'/);
      assert.match(html, /HitzeV Backend/);
      assert.doesNotMatch(html, /develop|\/test|\/cron/);
    }
  });

  it("/health is cheap and public", async () => {
    const response = await fetch(`${production.base}/health`);
    assert.deepEqual(await response.json(), { ok: true });
  });

  it("POST /cron/hitze needs the secret", async () => {
    assert.equal((await fetch(`${production.base}/cron/hitze`, { method: "POST" })).status, 401);
    assert.equal(
      (await fetch(`${production.base}/cron/hitze`, { method: "POST", headers: { Authorization: "Bearer nope" } })).status,
      401
    );
    const ok = await fetch(`${production.base}/cron/hitze`, { method: "POST", headers: auth });
    assert.equal(ok.status, 200);
    assert.equal(production.calls.length, 1);
    assert.equal((await fetch(`${production.base}/cron/hitze`)).status, 404, "GET is not a trigger");
  });

  it("develop routes do not exist without develop mode", async () => {
    assert.equal((await fetch(`${production.base}/test/push/options`, { headers: auth })).status, 404);
    assert.equal((await fetch(`${production.base}/test/push/ui`)).status, 404);
  });

  it("develop data routes need the secret; HTML shells carry no data", async () => {
    assert.equal((await fetch(`${develop.base}/test/push/options`)).status, 401);
    assert.equal((await fetch(`${develop.base}/test/pushover/status`)).status, 401);
    assert.equal((await fetch(`${develop.base}/test/push`, { method: "POST" })).status, 401);

    const options = await fetch(`${develop.base}/test/push/options`, { headers: auth });
    const body = (await options.json()) as { municipalities: unknown[]; languages: string[] };
    assert.equal(body.municipalities.length, 2114);
    assert.equal(body.languages.length, 25);

    const page = await fetch(`${develop.base}/test/push/ui`);
    const html = await page.text();
    assert.equal(page.status, 200);
    assert.match(html, /<title>HitzeV Testversand<\/title>/);
    assert.match(html, /prefers-color-scheme: dark/);
    assert.doesNotMatch(html, /Breitenbrunn/);
  });

  it("bulk test send is limited and validated before contacting Firebase", async () => {
    const ids = Array.from({ length: 51 }, (_, index) => String(10101 + index));
    const response = await fetch(`${develop.base}/test/push/bulk`, {
      method: "POST",
      headers: { ...auth, "Content-Type": "application/json" },
      body: JSON.stringify({ municipalityIds: ids, format: "v2" }),
    });
    assert.equal(response.status, 400);
    const badFormat = await fetch(`${develop.base}/test/push`, {
      method: "POST",
      headers: { ...auth, "Content-Type": "application/json" },
      body: JSON.stringify({ municipalityId: "60101", format: "v3" }),
    });
    assert.equal(badFormat.status, 400);
  });

  it("oversized bodies get a JSON 413 without internals", async () => {
    const response = await fetch(`${develop.base}/test/push`, {
      method: "POST",
      headers: { ...auth, "Content-Type": "application/json" },
      body: JSON.stringify({ municipalityId: "x".repeat(100_000) }),
    });
    assert.equal(response.status, 413);
    assert.deepEqual(await response.json(), { errorCode: "PAYLOAD_TOO_LARGE", message: "Invalid request body." });
  });
});

describe("CronRunTracker", () => {
  it("waits for a run, then aborts it after the timeout", async () => {
    const tracker = new CronRunTracker();
    let abortedSeen = false;
    void tracker.track(
      new Promise<void>((resolve) => {
        tracker.signal.addEventListener("abort", () => {
          abortedSeen = true;
          setTimeout(resolve, 10);
        });
      })
    );
    const result = await tracker.drain(20, 500);
    assert.equal(result, "aborted");
    assert.equal(abortedSeen, true);
    assert.equal(tracker.isClosing, true);
  });

  it("returns idle when nothing runs", async () => {
    assert.equal(await new CronRunTracker().drain(10, 10), "idle");
  });

  const delay = (ms: number): Promise<void> => new Promise((resolve) => setTimeout(resolve, ms));

  function slowCron(persistDelayMs: number) {
    const h = createHarness({ fcmSendConcurrency: 2 });
    h.now = Date.parse("2026-07-07T06:00:00Z");
    h.features = [
      heatFeature("w1", 2, "2026-07-07T08:00:00Z", "2026-07-07T16:00:00Z", ["10101", "20101", "30101", "40101", "50101", "60101"]),
    ];
    const redisStore = new RedisCronStateStore(h.redis);
    let pendingPersists = 0;
    const store = Object.assign(Object.create(redisStore) as RedisCronStateStore, {
      persist: async (update: StateUpdate): Promise<void> => {
        pendingPersists += 1;
        await (Number.isFinite(persistDelayMs) ? delay(persistDelayMs) : new Promise<void>(() => undefined));
        await redisStore.persist(update);
        pendingPersists -= 1;
      },
    });
    const messaging = {
      send: async (message: Message): Promise<string> => {
        await delay(30);
        return h.messaging.send(message);
      },
    };
    const run = (signal: AbortSignal): Promise<HitzeCronHttpResponse> =>
      runHitzeCron({ ...h.deps(), store, messaging: () => messaging, signal });
    return { h, run, pendingPersists: () => pendingPersists };
  }

  it("after the abort, waits until in-flight sends have persisted their state", async () => {
    const tracker = new CronRunTracker();
    const { h, run, pendingPersists } = slowCron(80);
    const result = tracker.track(run(tracker.signal));
    const drain = await tracker.drain(10, 5_000);
    assert.equal(drain, "aborted");
    assert.equal(pendingPersists(), 0, "no persist pending when drain returns");

    const sentGkz = v2Messages(h.messaging).map((message) => message.data?.gkz).sort();
    const persistedGkz = h.redis.hashFields(DAY_STATE_KEY).map((key) => key.split("|")[0]);
    assert.ok(sentGkz.length > 0 && sentGkz.length < 6, `some but not all sent, got ${sentGkz.length}`);
    assert.deepEqual(persistedGkz, sentGkz, "every sent push has its state recorded");
    const body = (await result).body;
    assert.equal(body.deferredAborted, 6 - sentGkz.length);
  });

  it("gives up after the abort grace when a persist hangs", async () => {
    const tracker = new CronRunTracker();
    const { run } = slowCron(Number.POSITIVE_INFINITY);
    void tracker.track(run(tracker.signal));
    const started = Date.now();
    assert.equal(await tracker.drain(10, 100), "abandoned");
    assert.ok(Date.now() - started < 1_000);
  });
});
