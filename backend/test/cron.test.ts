import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import path from "node:path";
import { describe, it } from "node:test";
import type { TopicMessage } from "firebase-admin/messaging";
import { groupByGkzDay, type NormalizedWarning } from "../api/cron/feed";
import { DAY_STATE_KEY, LAST_PUSH_KEY, LEGACY_SENT_KEY } from "../api/cron/state";
import { createHarness, daysOf, heatFeature, legacyMessages, v2Messages } from "./helpers";

const GRAZ = "60101";

function onlyV2(harnessMessages: TopicMessage[]): TopicMessage {
  assert.equal(harnessMessages.length, 1, `expected exactly one v2 message, got ${harnessMessages.length}`);
  return harnessMessages[0];
}

describe("cron decision engine", () => {
  it("(a) same-day escalation yellow -> orange is sent as escalated", async () => {
    const h = createHarness();
    h.features = [heatFeature("w1", 1, "2026-07-07T08:00:00Z", "2026-07-07T16:00:00Z")];
    await h.runAt("2026-07-07T06:00:00Z");
    const first = onlyV2(v2Messages(h.messaging));
    assert.equal(first.data?.event, "new");

    h.features = [heatFeature("w1", 2, "2026-07-07T08:00:00Z", "2026-07-07T16:00:00Z")];
    const result = await h.runAt("2026-07-07T07:30:00Z");
    const second = onlyV2(v2Messages(h.messaging));
    assert.equal(second.data?.event, "escalated");
    assert.deepEqual(daysOf(second), [
      { date: "2026-07-07", level: 3, start: "2026-07-07T08:00:00Z", end: "2026-07-07T16:00:00Z" },
    ]);
    assert.equal(second.apns?.payload?.aps.alert && typeof second.apns.payload.aps.alert === "object"
      ? second.apns.payload.aps.alert.title
      : null, "Hitzewarnung verschärft");
    assert.equal((result.body.events as Record<string, number>).escalated, 1);

    // A second escalation the same day is sent again (escalations are never rate-limited).
    h.features = [heatFeature("w1", 3, "2026-07-07T08:00:00Z", "2026-07-07T16:00:00Z")];
    await h.runAt("2026-07-07T07:40:00Z");
    assert.equal(onlyV2(v2Messages(h.messaging)).data?.event, "escalated");
  });

  it("(b) multi-day feed: per-day state, only today/tomorrow pushed", async () => {
    const h = createHarness();
    const example = JSON.parse(readFileSync(path.join(__dirname, "..", "example_response.json"), "utf8")) as {
      test: { value: { features: unknown[] } };
    };
    h.features = example.test.value.features;

    await h.runAt("2026-03-07T09:00:00Z");
    const first = onlyV2(v2Messages(h.messaging));
    assert.equal(first.topic, "warngebiet_v2_30740");
    assert.equal(first.data?.event, "new");
    assert.deepEqual(daysOf(first), [
      { date: "2026-03-07", level: 3, start: "2026-03-07T13:00:00Z", end: "2026-03-07T17:00:00Z" },
      { date: "2026-03-08", level: 3, start: "2026-03-08T08:00:00Z", end: "2026-03-08T12:00:00Z" },
    ]);
    assert.deepEqual(h.redis.hashFields(DAY_STATE_KEY), ["30740|2026-03-07", "30740|2026-03-08"]);

    await h.runAt("2026-03-07T09:10:00Z");
    assert.equal(h.messaging.sent.length, 0, "unchanged feed must not push again");

    // Next morning: 2026-03-08 is today (already sent), 2026-03-09 became tomorrow.
    await h.runAt("2026-03-08T06:00:00Z");
    const next = onlyV2(v2Messages(h.messaging));
    assert.equal(next.data?.event, "new");
    assert.deepEqual(
      daysOf(next).map((day) => [day.date, day.level]),
      [
        ["2026-03-08", 3],
        ["2026-03-09", 4],
      ]
    );
    assert.deepEqual(h.redis.hashFields(DAY_STATE_KEY), ["30740|2026-03-08", "30740|2026-03-09"]);
  });

  it("(c) a day expiring in the evening does not cause an updated push", async () => {
    const h = createHarness();
    h.features = [
      heatFeature("today-am", 1, "2026-07-07T07:00:00Z", "2026-07-07T10:00:00Z"),
      heatFeature("today-pm", 1, "2026-07-07T11:00:00Z", "2026-07-07T16:00:00Z"),
      heatFeature("tomorrow", 1, "2026-07-08T08:00:00Z", "2026-07-08T16:00:00Z"),
    ];
    await h.runAt("2026-07-07T05:00:00Z");
    assert.equal(onlyV2(v2Messages(h.messaging)).data?.event, "new");

    // The morning sub-warning ended: the day's start moves later, but it already began.
    h.features = h.features.slice(1);
    await h.runAt("2026-07-07T10:30:00Z");
    assert.equal(h.messaging.sent.length, 0);

    // Evening: today's warnings have ended and dropped out of the feed.
    h.features = h.features.slice(1);
    const result = await h.runAt("2026-07-07T17:30:00Z");
    assert.equal(h.messaging.sent.length, 0);
    assert.equal(result.body.v2Sent, 0);
  });

  it("(d) the first push is `new` without updated wording", async () => {
    const h = createHarness();
    h.features = [heatFeature("w1", 2, "2026-07-07T08:00:00Z", "2026-07-07T16:00:00Z")];
    await h.runAt("2026-07-07T06:30:00Z");
    const message = onlyV2(v2Messages(h.messaging));
    assert.equal(message.data?.event, "new");
    const alert = message.apns?.payload?.aps.alert;
    assert.ok(alert && typeof alert === "object");
    assert.equal(alert.title, "Hitzewarnung");
    assert.equal(alert.body, "Heute in Graz: Hitzewarnstufe 3 (orange), 10:00–18:00 Uhr. Schutzmaßnahmen nach Hitze-V umsetzen.");
    assert.doesNotMatch(alert.body ?? "", /aktualisiert|geändert/);
  });

  it("(e) empty feed, then the same warning again: no duplicate push", async () => {
    const h = createHarness();
    const warning = heatFeature("w1", 1, "2026-07-07T08:00:00Z", "2026-07-07T16:00:00Z");
    h.features = [warning];
    await h.runAt("2026-07-07T06:00:00Z");
    assert.equal(v2Messages(h.messaging).length, 1);

    h.features = [];
    await h.runAt("2026-07-07T06:10:00Z");
    assert.equal(h.messaging.sent.length, 0);
    assert.deepEqual(h.redis.hashFields(DAY_STATE_KEY), [`${GRAZ}|2026-07-07`], "empty feed must not wipe state");

    h.features = [warning];
    await h.runAt("2026-07-07T06:20:00Z");
    assert.equal(h.messaging.sent.length, 0);
  });

  it("(f) Redis write failure after a send: only unrecorded municipalities are resent", async () => {
    const h = createHarness({ fcmSendConcurrency: 1 });
    h.features = [
      heatFeature("w1", 1, "2026-07-07T08:00:00Z", "2026-07-07T16:00:00Z", ["10101", "20101", "30101"]),
    ];
    // First state write (10101) works, second (20101) fails.
    let writes = 0;
    h.redis.failHSetAtomic = () => {
      writes += 1;
      return writes === 2;
    };
    const first = await h.runAt("2026-07-07T06:00:00Z");
    assert.equal(first.status, 200);
    assert.equal(first.body.stateWriteFailures, 1);
    assert.equal(first.body.deferredAborted, 1, "sending stops after a failed state write");
    assert.deepEqual(h.messaging.topics(), ["warngebiet_v2_10101", "warngebiet_v2_20101"]);
    assert.equal(h.reporter.failures[0]?.errorCode, "STATE_WRITE_FAILED");

    h.redis.failHSetAtomic = null;
    await h.runAt("2026-07-07T06:10:00Z");
    assert.deepEqual(h.messaging.topics().sort(), ["warngebiet_v2_20101", "warngebiet_v2_30101"]);

    await h.runAt("2026-07-07T06:20:00Z");
    assert.equal(h.messaging.sent.length, 0);
  });

  it("(g) quiet hours defer without saving state and send at 06:00", async () => {
    const h = createHarness();
    h.features = [heatFeature("w1", 2, "2026-07-08T08:00:00Z", "2026-07-08T16:00:00Z")];

    const evening = await h.runAt("2026-07-07T19:00:00Z"); // 21:00 Vienna
    assert.equal(h.messaging.sent.length, 0);
    assert.equal(evening.body.deferredQuietHours, 1);
    assert.deepEqual(h.redis.hashFields(DAY_STATE_KEY), []);

    await h.runAt("2026-07-08T03:50:00Z"); // 05:50 Vienna
    assert.equal(h.messaging.sent.length, 0);

    await h.runAt("2026-07-08T04:00:00Z"); // 06:00 Vienna
    const message = onlyV2(v2Messages(h.messaging));
    assert.equal(message.data?.event, "new");
    const alert = message.apns?.payload?.aps.alert;
    assert.ok(alert && typeof alert === "object");
    assert.match(alert.body ?? "", /^Heute in Graz/);
  });

  it("(h) LEGACY_LANGUAGE_TOPICS=de sends one v2 and one legacy message", async () => {
    const h = createHarness({ legacyLanguageTopics: "de" });
    h.features = [heatFeature("w1", 2, "2026-07-07T08:00:00Z", "2026-07-07T16:00:00Z")];
    const result = await h.runAt("2026-07-07T06:30:00Z");
    assert.deepEqual(h.messaging.topics().sort(), ["warngebiet_60101_de", "warngebiet_v2_60101"]);
    assert.equal(result.body.v2Sent, 1);
    assert.equal(result.body.legacySent, 1);
    const legacy = legacyMessages(h.messaging)[0];
    assert.deepEqual(legacy.notification, {
      title: "Hitzewarnung",
      body: "Heute in Graz: Hitzewarnstufe 3 (orange), 10:00–18:00 Uhr. Schutzmaßnahmen nach Hitze-V umsetzen.",
    });
    assert.equal(h.reporter.runs[0]?.v2Sent, 1);
    assert.equal(h.reporter.runs[0]?.legacySent, 1);
  });

  it("LEGACY_LANGUAGE_TOPICS=all fans out to 25 languages, off sends none", async () => {
    const all = createHarness({ legacyLanguageTopics: "all" });
    all.features = [heatFeature("w1", 2, "2026-07-07T08:00:00Z", "2026-07-07T16:00:00Z")];
    await all.runAt("2026-07-07T06:30:00Z");
    assert.equal(v2Messages(all.messaging).length, 1);
    assert.equal(legacyMessages(all.messaging).length, 25);
    const en = legacyMessages(all.messaging).find((message) => message.topic === "warngebiet_60101_en");
    assert.equal(en?.notification?.title, "Heat warning");

    const off = createHarness({ legacyLanguageTopics: "off" });
    off.features = all.features;
    await off.runAt("2026-07-07T06:30:00Z");
    assert.deepEqual(off.messaging.topics(), ["warngebiet_v2_60101"]);
  });

  it("a failed legacy language is retried alone on the next run", async () => {
    const h = createHarness({ legacyLanguageTopics: "all" });
    h.features = [heatFeature("w1", 2, "2026-07-07T08:00:00Z", "2026-07-07T16:00:00Z")];
    h.messaging.failWhen = (message) => (message as TopicMessage).topic === "warngebiet_60101_fr";
    const first = await h.runAt("2026-07-07T06:30:00Z");
    assert.equal(first.body.legacyFailed, 1);
    assert.equal(first.body.legacySent, 24);

    h.messaging.failWhen = null;
    const second = await h.runAt("2026-07-07T06:40:00Z");
    assert.deepEqual(h.messaging.topics(), ["warngebiet_60101_fr"]);
    assert.equal(second.body.legacyRetries, 1);

    await h.runAt("2026-07-07T06:50:00Z");
    assert.equal(h.messaging.sent.length, 0);
  });

  it("a failed v2 send is retried without repeating delivered legacy languages", async () => {
    const h = createHarness({ legacyLanguageTopics: "de" });
    h.features = [heatFeature("w1", 2, "2026-07-07T08:00:00Z", "2026-07-07T16:00:00Z")];
    h.messaging.failWhen = (message) => (message as TopicMessage).topic.startsWith("warngebiet_v2_");
    const first = await h.runAt("2026-07-07T06:30:00Z");
    assert.equal(first.body.v2Failed, 1);
    assert.deepEqual(h.messaging.topics(), ["warngebiet_60101_de"]);
    assert.deepEqual(h.redis.hashFields(DAY_STATE_KEY), []);

    h.messaging.failWhen = null;
    const second = await h.runAt("2026-07-07T06:40:00Z");
    assert.deepEqual(h.messaging.topics(), ["warngebiet_v2_60101"]);
    assert.equal(second.body.legacySkippedAlreadyDelivered, 1);
    assert.deepEqual(h.redis.hashFields(LAST_PUSH_KEY), [GRAZ]);
    assert.deepEqual(h.redis.hashFields(LEGACY_SENT_KEY), [`${GRAZ}|de`]);
  });

  it("window change for tomorrow is `updated` (once per Vienna day), carrying only that day", async () => {
    const h = createHarness();
    h.features = [
      heatFeature("today", 1, "2026-07-07T08:00:00Z", "2026-07-07T16:00:00Z"),
      heatFeature("tomorrow", 2, "2026-07-08T08:00:00Z", "2026-07-08T16:00:00Z"),
    ];
    await h.runAt("2026-07-07T06:00:00Z");
    assert.equal(daysOf(onlyV2(v2Messages(h.messaging))).length, 2);

    h.features = [
      heatFeature("today", 1, "2026-07-07T08:00:00Z", "2026-07-07T16:00:00Z"),
      heatFeature("tomorrow", 2, "2026-07-08T09:00:00Z", "2026-07-08T17:00:00Z"),
    ];
    await h.runAt("2026-07-07T14:00:00Z");
    const updated = onlyV2(v2Messages(h.messaging));
    assert.equal(updated.data?.event, "updated");
    assert.deepEqual(daysOf(updated).map((day) => day.date), ["2026-07-08"]);
    const alert = updated.apns?.payload?.aps.alert;
    assert.ok(alert && typeof alert === "object");
    assert.equal(alert.body, "Morgen in Graz: Zeitraum der Hitzewarnstufe 3 geändert, jetzt 11:00–19:00 Uhr.");

    h.features = [
      heatFeature("today", 1, "2026-07-07T08:00:00Z", "2026-07-07T16:00:00Z"),
      heatFeature("tomorrow", 2, "2026-07-08T10:00:00Z", "2026-07-08T17:00:00Z"),
    ];
    const limited = await h.runAt("2026-07-07T15:00:00Z");
    assert.equal(h.messaging.sent.length, 0, "second update the same day is held back");
    assert.equal(limited.body.deferredRateLimited, 1);

    // Next Vienna day the pending change goes out.
    await h.runAt("2026-07-08T04:00:00Z");
    assert.equal(onlyV2(v2Messages(h.messaging)).data?.event, "updated");
  });

  it("downgrade and cancellation are silent; reappearing at or below the pushed level is not pushed", async () => {
    const h = createHarness();
    h.features = [heatFeature("w1", 2, "2026-07-07T08:00:00Z", "2026-07-07T16:00:00Z")];
    await h.runAt("2026-07-07T05:00:00Z");

    h.features = [heatFeature("w1", 1, "2026-07-07T08:00:00Z", "2026-07-07T16:00:00Z")];
    const downgrade = await h.runAt("2026-07-07T06:00:00Z");
    assert.equal(h.messaging.sent.length, 0);
    assert.equal(downgrade.body.silentUpdates, 1);

    h.features = [];
    await h.runAt("2026-07-07T07:00:00Z");
    assert.equal(h.messaging.sent.length, 0);
    assert.deepEqual(h.redis.hashFields(DAY_STATE_KEY), [`${GRAZ}|2026-07-07`], "cancellation keeps the day state");

    h.features = [heatFeature("w1", 2, "2026-07-07T08:00:00Z", "2026-07-07T16:00:00Z")];
    await h.runAt("2026-07-07T08:00:00Z");
    assert.equal(h.messaging.sent.length, 0, "back at the pushed level: no push");

    h.features = [heatFeature("w1", 3, "2026-07-07T08:00:00Z", "2026-07-07T16:00:00Z")];
    await h.runAt("2026-07-07T08:10:00Z");
    assert.equal(onlyV2(v2Messages(h.messaging)).data?.event, "escalated");
  });

  it("a flapping feed 3->2->3->2->3 pushes `new` once and nothing else", async () => {
    const h = createHarness();
    const events: Array<string | undefined> = [];
    const times = ["06:00", "06:10", "06:20", "06:30", "06:40"];
    for (const [index, level] of [3, 2, 3, 2, 3].entries()) {
      h.features = [heatFeature("w1", level - 1, "2026-07-07T08:00:00Z", "2026-07-07T16:00:00Z")];
      await h.runAt(`2026-07-07T${times[index]}:00Z`);
      events.push(v2Messages(h.messaging)[0]?.data?.event);
    }
    assert.deepEqual(events, ["new", undefined, undefined, undefined, undefined]);
    const state = JSON.parse(h.redis.hashes.get(DAY_STATE_KEY)?.get(`${GRAZ}|2026-07-07`) ?? "{}") as {
      level: number;
      pushedLevel: number;
    };
    assert.equal(state.level, 3);
    assert.equal(state.pushedLevel, 3);
  });

  it("migrates day states without pushedLevel (stored level counts as pushed)", async () => {
    const h = createHarness();
    h.redis.hashes.set(
      DAY_STATE_KEY,
      new Map([
        [
          `${GRAZ}|2026-07-07`,
          JSON.stringify({
            level: 3,
            start: "2026-07-07T08:00:00Z",
            end: "2026-07-07T16:00:00Z",
            sentDayKey: "2026-07-07",
            updatedDayKey: "",
          }),
        ],
      ])
    );
    h.features = [heatFeature("w1", 1, "2026-07-07T08:00:00Z", "2026-07-07T16:00:00Z")];
    await h.runAt("2026-07-07T06:00:00Z");
    assert.equal(h.messaging.sent.length, 0);
    const migrated = JSON.parse(h.redis.hashes.get(DAY_STATE_KEY)?.get(`${GRAZ}|2026-07-07`) ?? "{}") as {
      level: number;
      pushedLevel: number;
    };
    assert.deepEqual([migrated.level, migrated.pushedLevel], [2, 3]);

    h.features = [heatFeature("w1", 2, "2026-07-07T08:00:00Z", "2026-07-07T16:00:00Z")];
    await h.runAt("2026-07-07T06:10:00Z");
    assert.equal(h.messaging.sent.length, 0);

    h.features = [heatFeature("w1", 3, "2026-07-07T08:00:00Z", "2026-07-07T16:00:00Z")];
    await h.runAt("2026-07-07T06:20:00Z");
    assert.equal(onlyV2(v2Messages(h.messaging)).data?.event, "escalated");
  });

  it("a warning spanning Mon 00:00-Wed 23:59 is pushed for each day it covers", async () => {
    const h = createHarness();
    // Mon 2026-07-06 00:00 to Wed 2026-07-08 23:59 Vienna (CEST, UTC+2).
    h.features = [heatFeature("long", 2, "2026-07-05T22:00:00Z", "2026-07-08T21:59:00Z")];

    await h.runAt("2026-07-07T06:00:00Z"); // Tue 08:00 Vienna
    const tuesday = onlyV2(v2Messages(h.messaging));
    assert.equal(tuesday.data?.event, "new");
    assert.deepEqual(daysOf(tuesday), [
      { date: "2026-07-07", level: 3, start: "2026-07-06T22:00:00Z", end: "2026-07-07T22:00:00Z" },
      { date: "2026-07-08", level: 3, start: "2026-07-07T22:00:00Z", end: "2026-07-08T21:59:00Z" },
    ]);
    const alert = tuesday.apns?.payload?.aps.alert;
    assert.ok(alert && typeof alert === "object");
    assert.match(alert.body ?? "", /ganztägig/);

    await h.runAt("2026-07-07T10:00:00Z");
    assert.equal(h.messaging.sent.length, 0, "unchanged multi-day warning is not pushed again");

    // Wed: escalated for Wednesday only.
    h.features = [heatFeature("long", 3, "2026-07-05T22:00:00Z", "2026-07-08T21:59:00Z")];
    await h.runAt("2026-07-08T06:00:00Z");
    const wednesday = onlyV2(v2Messages(h.messaging));
    assert.equal(wednesday.data?.event, "escalated");
    assert.deepEqual(daysOf(wednesday), [
      { date: "2026-07-08", level: 4, start: "2026-07-07T22:00:00Z", end: "2026-07-08T21:59:00Z" },
    ]);
  });

  it("an escalation on the second day of a multi-day warning is pushed the day before", async () => {
    const h = createHarness();
    h.features = [heatFeature("long", 1, "2026-07-06T22:00:00Z", "2026-07-08T21:59:00Z")];
    await h.runAt("2026-07-07T06:00:00Z");
    assert.equal(onlyV2(v2Messages(h.messaging)).data?.event, "new");

    h.features = [
      heatFeature("long", 1, "2026-07-06T22:00:00Z", "2026-07-08T21:59:00Z"),
      heatFeature("peak", 2, "2026-07-08T10:00:00Z", "2026-07-08T15:00:00Z"),
    ];
    await h.runAt("2026-07-07T12:00:00Z");
    const escalated = onlyV2(v2Messages(h.messaging));
    assert.equal(escalated.data?.event, "escalated");
    assert.deepEqual(daysOf(escalated).map((day) => [day.date, day.level, day.start, day.end]), [
      ["2026-07-07", 2, "2026-07-06T22:00:00Z", "2026-07-07T22:00:00Z"],
      ["2026-07-08", 3, "2026-07-07T22:00:00Z", "2026-07-08T21:59:00Z"],
    ]);
  });

  it("a warning without start is not re-pushed for the same day, only for a new day", async () => {
    const h = createHarness();
    const noStart = {
      type: "Feature",
      geometry: null,
      properties: {
        warnid: "open",
        wtype: 6,
        wlevel: 2,
        end: String(Date.parse("2026-07-09T14:00:00Z") / 1000),
        gemeinden: [GRAZ],
      },
    };
    h.features = [noStart];

    await h.runAt("2026-07-07T06:00:00Z");
    const first = onlyV2(v2Messages(h.messaging));
    assert.equal(first.data?.event, "new");
    assert.deepEqual(daysOf(first), [
      { date: "2026-07-07", level: 3, start: "2026-07-06T22:00:00Z", end: "2026-07-07T22:00:00Z" },
      { date: "2026-07-08", level: 3, start: "2026-07-07T22:00:00Z", end: "2026-07-08T22:00:00Z" },
    ]);

    await h.runAt("2026-07-07T12:00:00Z");
    assert.equal(h.messaging.sent.length, 0, "same day: no second push");

    // Next day: 07-08 is known (sent as tomorrow), 07-09 is a new day of warning.
    await h.runAt("2026-07-08T06:00:00Z");
    const next = onlyV2(v2Messages(h.messaging));
    assert.equal(next.data?.event, "new");
    assert.deepEqual(daysOf(next).map((day) => day.date), ["2026-07-08", "2026-07-09"]);

    await h.runAt("2026-07-08T12:00:00Z");
    assert.equal(h.messaging.sent.length, 0);

    // Last day: nothing new any more.
    await h.runAt("2026-07-09T06:00:00Z");
    assert.equal(h.messaging.sent.length, 0);
  });

  it("days beyond tomorrow are not pushed and leave no state; past days are cleaned up", async () => {
    const h = createHarness();
    h.features = [heatFeature("w1", 3, "2026-07-10T08:00:00Z", "2026-07-10T16:00:00Z")];
    await h.runAt("2026-07-07T06:00:00Z");
    assert.equal(h.messaging.sent.length, 0);
    assert.deepEqual(h.redis.hashFields(DAY_STATE_KEY), []);

    h.features = [heatFeature("w2", 1, "2026-07-07T08:00:00Z", "2026-07-07T16:00:00Z")];
    await h.runAt("2026-07-07T06:10:00Z");
    assert.deepEqual(h.redis.hashFields(DAY_STATE_KEY), [`${GRAZ}|2026-07-07`]);
    h.features = [];
    const nextDay = await h.runAt("2026-07-08T06:00:00Z");
    assert.equal(nextDay.body.clearedStates, 1);
    assert.deepEqual(h.redis.hashFields(DAY_STATE_KEY), []);
  });

  it("level is clamped to 4 and HITZE_MIN_LEVEL filters lower levels", async () => {
    const h = createHarness({ minLevel: 3 });
    h.features = [
      heatFeature("yellow", 1, "2026-07-07T08:00:00Z", "2026-07-07T16:00:00Z", ["10101"]),
      heatFeature("extreme", 7, "2026-07-07T08:00:00Z", "2026-07-07T16:00:00Z", ["20101"]),
    ];
    await h.runAt("2026-07-07T06:00:00Z");
    const message = onlyV2(v2Messages(h.messaging));
    assert.equal(message.topic, "warngebiet_v2_20101");
    assert.equal(daysOf(message)[0].level, 4);
  });

  it("a concurrent run is skipped while the lock is held", async () => {
    const h = createHarness();
    await h.redis.setNx("hitze:v1:cron_lock", "other", 300);
    const result = await h.runAt("2026-07-07T06:00:00Z");
    assert.equal(result.body.skipped, true);
    assert.equal(result.body.skipReason, "CRON_ALREADY_RUNNING");
  });

  it("a feed failure is reported and leaves state untouched", async () => {
    const h = createHarness();
    const deps = h.deps();
    h.now = Date.parse("2026-07-07T06:00:00Z");
    const { runHitzeCron } = await import("../api/cron/hitze");
    const { AppError } = await import("../api/cron/errors");
    const result = await runHitzeCron({
      ...deps,
      fetchFeed: async () => {
        throw new AppError(502, "GEOSPHERE_HTTP_ERROR", "GeoSphere returned HTTP 500.");
      },
    });
    assert.equal(result.status, 502);
    assert.equal(h.reporter.failures[0]?.errorCode, "GEOSPHERE_HTTP_ERROR");
    assert.equal(await h.redis.get("hitze:v1:cron_lock"), null, "lock released");
  });
});

describe("splitting warnings into Vienna days", () => {
  const warning = (start: string | null, end: string | null, level = 3, id = "w"): NormalizedWarning => ({
    id,
    level,
    municipalities: [GRAZ],
    start: start ?? "",
    end: end ?? "",
    startMs: start === null ? null : Date.parse(start),
    endMs: end === null ? null : Date.parse(end),
    geometry: null,
  });

  it("clips at Vienna midnight across the end of DST", () => {
    // Sat 2026-10-24 12:00 CEST to Mon 2026-10-26 10:00 CET; DST ends Sun 2026-10-25 03:00.
    const days = groupByGkzDay(
      [warning("2026-10-24T10:00:00Z", "2026-10-26T09:00:00Z")],
      Date.parse("2026-10-24T06:00:00Z")
    ).get(GRAZ);
    assert.deepEqual(
      days?.map((day) => [day.date, day.start, day.end]),
      [
        ["2026-10-24", "2026-10-24T10:00:00Z", "2026-10-24T22:00:00Z"],
        ["2026-10-25", "2026-10-24T22:00:00Z", "2026-10-25T23:00:00Z"],
        ["2026-10-26", "2026-10-25T23:00:00Z", "2026-10-26T09:00:00Z"],
      ]
    );
  });

  it("clips at Vienna midnight across the start of DST", () => {
    // DST starts Sun 2026-03-29 02:00 CET.
    const days = groupByGkzDay(
      [warning("2026-03-28T20:00:00Z", "2026-03-30T08:00:00Z")],
      Date.parse("2026-03-28T06:00:00Z")
    ).get(GRAZ);
    assert.deepEqual(
      days?.map((day) => [day.date, day.start, day.end]),
      [
        ["2026-03-28", "2026-03-28T20:00:00Z", "2026-03-28T23:00:00Z"],
        ["2026-03-29", "2026-03-28T23:00:00Z", "2026-03-29T22:00:00Z"],
        ["2026-03-30", "2026-03-29T22:00:00Z", "2026-03-30T08:00:00Z"],
      ]
    );
  });

  it("merges pieces per day: max level, earliest start, latest end; ending at midnight adds no day", () => {
    const days = groupByGkzDay(
      [
        warning("2026-07-06T22:00:00Z", "2026-07-07T22:00:00Z", 2, "a"),
        warning("2026-07-07T10:00:00Z", "2026-07-07T14:00:00Z", 4, "b"),
      ],
      Date.parse("2026-07-07T05:00:00Z")
    ).get(GRAZ);
    assert.deepEqual(days, [
      {
        gkz: GRAZ,
        date: "2026-07-07",
        level: 4,
        start: "2026-07-06T22:00:00Z",
        end: "2026-07-07T22:00:00Z",
        warningIds: ["a", "b"],
      },
    ]);
  });

  it("drops past days and keeps an unknown end open on the last day", () => {
    const days = groupByGkzDay(
      [warning("2026-07-05T08:00:00Z", null)],
      Date.parse("2026-07-07T05:00:00Z")
    ).get(GRAZ);
    assert.deepEqual(days?.map((day) => [day.date, day.start, day.end]), [
      ["2026-07-07", "2026-07-06T22:00:00Z", ""],
    ]);
  });
});
