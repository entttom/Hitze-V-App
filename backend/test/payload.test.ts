import assert from "node:assert/strict";
import path from "node:path";
import { describe, it } from "node:test";
import type { Message, TopicMessage } from "firebase-admin/messaging";
import { buildLegacyMessage, buildV2Message, expiryFor } from "../api/cron/messages";
import { createHarness, heatFeature, legacyMessages, v2Messages } from "./helpers";

// firebase-admin's own validator turns the SDK message into the FCM HTTP v1 wire shape.
const internalPath = path.join(path.dirname(require.resolve("firebase-admin/messaging")), "messaging-internal.js");
const { validateMessage } = require(internalPath) as { validateMessage: (message: Message) => void };

function wireFormat(message: Message): Record<string, unknown> {
  const copy = structuredClone(message);
  validateMessage(copy);
  return copy as unknown as Record<string, unknown>;
}

const V2_DATA_KEYS = ["days", "event", "gkz", "name", "sentAt", "type", "v", "warningIds"];

describe("(i) payload shape matches docs/push-contract-v2.md", () => {
  it("v2 message: topic, string data, android + apns blocks, no notification", async () => {
    const h = createHarness({ legacyLanguageTopics: "de" });
    h.features = [
      heatFeature("124", 2, "2026-07-07T08:00:00Z", "2026-07-07T16:00:00Z"),
      heatFeature("123", 1, "2026-07-08T09:00:00Z", "2026-07-08T17:45:00Z"),
    ];
    await h.runAt("2026-07-07T06:30:00Z");
    const [message] = v2Messages(h.messaging);
    assert.ok(message);

    assert.equal(message.topic, "warngebiet_v2_60101");
    assert.equal("notification" in message, false);
    assert.deepEqual(Object.keys(message.data ?? {}).sort(), V2_DATA_KEYS);
    for (const value of Object.values(message.data ?? {})) {
      assert.equal(typeof value, "string");
    }
    assert.deepEqual(message.data, {
      v: "2",
      type: "heat_warning",
      event: "new",
      gkz: "60101",
      name: "Graz",
      days: JSON.stringify([
        { date: "2026-07-07", level: 3, start: "2026-07-07T08:00:00Z", end: "2026-07-07T16:00:00Z" },
        { date: "2026-07-08", level: 2, start: "2026-07-08T09:00:00Z", end: "2026-07-08T17:45:00Z" },
      ]),
      warningIds: "123,124",
      sentAt: "2026-07-07T06:30:00Z",
    });

    const latestEnd = Date.parse("2026-07-08T17:45:00Z");
    const now = Date.parse("2026-07-07T06:30:00Z");
    assert.equal(message.android?.priority, "high");
    assert.equal(message.android?.collapseKey, "hitze-60101");
    assert.equal(message.android?.ttl, latestEnd - now);
    assert.deepEqual(message.apns?.headers, {
      "apns-push-type": "alert",
      "apns-priority": "10",
      "apns-collapse-id": "hitze-60101",
      "apns-expiration": String(latestEnd / 1000),
    });

    const wire = wireFormat(message) as {
      android: { ttl: string; collapse_key: string; priority: string };
      apns: { payload: { aps: Record<string, unknown> } };
    };
    assert.equal(wire.android.collapse_key, "hitze-60101");
    assert.equal(wire.android.ttl, `${(latestEnd - now) / 1000}s`);
    assert.deepEqual(wire.apns.payload.aps, {
      alert: {
        title: "Hitzewarnung",
        body: "Graz: heute Hitzewarnstufe 3 (orange), 10:00–18:00 Uhr; morgen Hitzewarnstufe 2 (gelb), 11:00–19:45 Uhr. Schutzmaßnahmen nach Hitze-V umsetzen.",
      },
      sound: "default",
      "mutable-content": 1,
      "thread-id": "hitze-60101",
    });
  });

  it("legacy message keeps notification + old data keys and adds collapse/ttl", async () => {
    const h = createHarness({ legacyLanguageTopics: "de" });
    h.features = [heatFeature("124", 2, "2026-07-07T08:00:00Z", "2026-07-07T16:00:00Z")];
    await h.runAt("2026-07-07T06:30:00Z");
    const [legacy] = legacyMessages(h.messaging);
    assert.ok(legacy);
    assert.equal(legacy.topic, "warngebiet_60101_de");
    assert.ok(legacy.notification?.title && legacy.notification.body);
    assert.deepEqual(Object.keys(legacy.data ?? {}).sort(), [
      "gemeindename",
      "gemeindenr",
      "languageCode",
      "source",
      "warningEnd",
      "warningEndLocal",
      "warningIds",
      "warningKind",
      "warningLevel",
      "warningStart",
      "warningStartLocal",
    ]);
    assert.equal(legacy.data?.warningLevel, "3");
    assert.equal(legacy.data?.warningStartLocal, "07.07.2026, 10:00");
    assert.equal(legacy.android?.collapseKey, "hitze-60101");
    assert.equal(legacy.android?.notification?.tag, "hitze-60101");
    assert.equal(legacy.apns?.headers?.["apns-collapse-id"], "hitze-60101");
    assert.ok(Number(legacy.apns?.headers?.["apns-expiration"]) > 0);
    const wire = wireFormat(legacy) as { apns: { payload: { aps: Record<string, unknown> } } };
    assert.equal(wire.apns.payload.aps["thread-id"], "hitze-60101");
  });

  it("ttl is clamped to 1 h .. 4 days", () => {
    const now = Date.parse("2026-07-07T15:50:00Z");
    const soon = expiryFor([{ date: "2026-07-07", level: 2, start: "", end: "2026-07-07T16:00:00Z" }], now);
    assert.equal(soon.ttlMs, 60 * 60 * 1000);
    assert.equal(soon.apnsExpiration, Date.parse("2026-07-07T16:00:00Z") / 1000);
    const open = expiryFor([{ date: "2026-07-08", level: 2, start: "", end: "" }], now);
    assert.equal(open.apnsExpiration * 1000, Date.parse("2026-07-08T22:00:00Z"), "open end = next Vienna midnight");
  });

  it("test messages pass firebase-admin validation", () => {
    const content = { event: "test" as const, gkz: "90101", name: "Wien 1., Innere Stadt", days: [], warningIds: [], nowMs: Date.parse("2026-07-07T06:30:00Z") };
    const v2: TopicMessage = buildV2Message(content);
    assert.equal(v2.data?.type, "test");
    assert.equal(v2.data?.days, "[]");
    wireFormat(v2);
    const legacy = buildLegacyMessage(content, "en");
    assert.equal(legacy.notification?.title, "Test notification");
    wireFormat(legacy);
  });
});
