import type { Message, TokenMessage, TopicMessage } from "firebase-admin/messaging";
import type { PushDay, PushEvent, RenderedPush } from "./renderer";
import { renderPush } from "./renderer";
import { addDays, isoUtc, parseIsoMs, viennaClock, viennaMidnightUtc, viennaParts } from "./time";

const HOUR_MS = 60 * 60 * 1000;
const MIN_TTL_MS = HOUR_MS;
const MAX_TTL_MS = 4 * 24 * HOUR_MS;
/** Language of the APNs fallback alert in v2 messages. */
export const V2_FALLBACK_ALERT_LANGUAGE = "de";

export function v2Topic(gkz: string): string {
  return `warngebiet_v2_${gkz}`;
}

export function legacyTopic(gkz: string, language: string): string {
  return `warngebiet_${gkz}_${language}`;
}

export function collapseId(gkz: string): string {
  return `hitze-${gkz}`;
}

export interface PushContent {
  event: PushEvent;
  gkz: string;
  name: string;
  days: PushDay[];
  warningIds: string[];
  nowMs: number;
}

export function latestDayEndMs(days: PushDay[]): number | null {
  let latest: number | null = null;
  for (const day of days) {
    const end = parseIsoMs(day.end) ?? viennaMidnightUtc(addDays(day.date, 1));
    latest = latest === null ? end : Math.max(latest, end);
  }
  return latest;
}

export interface Expiry {
  ttlMs: number;
  apnsExpiration: number;
}

export function expiryFor(days: PushDay[], nowMs: number): Expiry {
  const latestEnd = latestDayEndMs(days) ?? nowMs + MIN_TTL_MS;
  const ttlMs = Math.min(MAX_TTL_MS, Math.max(MIN_TTL_MS, latestEnd - nowMs));
  // A day ending within the next minute must still be deliverable.
  const apnsExpiration = Math.floor(Math.max(latestEnd, nowMs + 60_000) / 1000);
  return { ttlMs, apnsExpiration };
}

function daysJson(days: PushDay[]): string {
  return JSON.stringify(
    days.map((day) => ({ date: day.date, level: day.level, start: day.start, end: day.end }))
  );
}

export function v2Data(content: PushContent): Record<string, string> {
  return {
    v: "2",
    type: content.event === "test" ? "test" : "heat_warning",
    event: content.event,
    gkz: content.gkz,
    name: content.name,
    days: daysJson(content.days),
    warningIds: content.warningIds.join(","),
    sentAt: isoUtc(content.nowMs),
  };
}

export function buildV2Payload(content: PushContent, alert?: RenderedPush): Omit<TopicMessage, "topic"> {
  const fallback =
    alert ??
    renderPush({
      event: content.event,
      name: content.name,
      days: content.days,
      nowMs: content.nowMs,
      language: V2_FALLBACK_ALERT_LANGUAGE,
    });
  const { ttlMs, apnsExpiration } = expiryFor(content.days, content.nowMs);
  const id = collapseId(content.gkz);

  return {
    data: v2Data(content),
    android: {
      priority: "high",
      ttl: ttlMs,
      collapseKey: id,
    },
    apns: {
      headers: {
        "apns-push-type": "alert",
        "apns-priority": "10",
        "apns-collapse-id": id,
        "apns-expiration": String(apnsExpiration),
      },
      payload: {
        aps: {
          alert: { title: fallback.title, body: fallback.body },
          sound: "default",
          mutableContent: true,
          threadId: id,
        },
      },
    },
  };
}

export function buildV2Message(content: PushContent): TopicMessage {
  return { topic: v2Topic(content.gkz), ...buildV2Payload(content) };
}

function formatLegacyLocal(value: string): string {
  const ms = parseIsoMs(value);
  if (ms === null) {
    return "";
  }
  const p = viennaParts(ms);
  const pad = (n: number): string => String(n).padStart(2, "0");
  return `${pad(p.day)}.${pad(p.month)}.${p.year}, ${viennaClock(ms)}`;
}

function legacyWindow(days: PushDay[]): { start: string; end: string } {
  const starts = days.map((day) => day.start);
  const ends = days.map((day) => day.end);
  const known = (values: string[]): string[] => values.filter((value) => value.length > 0).sort();
  return {
    start: starts.some((value) => !value) ? "" : known(starts)[0] ?? "",
    end: ends.some((value) => !value) ? "" : known(ends).at(-1) ?? "",
  };
}

export function buildLegacyPayload(
  content: PushContent,
  language: string,
  override?: Partial<RenderedPush>
): Omit<TopicMessage, "topic"> {
  const rendered = renderPush({
    event: content.event,
    name: content.name,
    days: content.days,
    nowMs: content.nowMs,
    language,
  });
  const { ttlMs, apnsExpiration } = expiryFor(content.days, content.nowMs);
  const id = collapseId(content.gkz);

  const data: Record<string, string> =
    content.event === "test"
      ? {
          gemeindenr: content.gkz,
          source: "manual_test",
          warningLevel: "test",
          languageCode: language,
        }
      : (() => {
          const window = legacyWindow(content.days);
          return {
            gemeindenr: content.gkz,
            gemeindename: content.name,
            warningKind: "heat",
            warningLevel: String(Math.max(...content.days.map((day) => day.level))),
            warningIds: content.warningIds.join(","),
            warningStart: window.start,
            warningEnd: window.end,
            warningStartLocal: formatLegacyLocal(window.start),
            warningEndLocal: formatLegacyLocal(window.end),
            source: "geosphere",
            languageCode: language,
          };
        })();

  return {
    notification: {
      title: override?.title?.trim() || rendered.title,
      body: override?.body?.trim() || rendered.body,
    },
    data,
    android: {
      priority: "high",
      ttl: ttlMs,
      collapseKey: id,
      notification: { tag: id },
    },
    apns: {
      headers: {
        "apns-push-type": "alert",
        "apns-priority": "10",
        "apns-collapse-id": id,
        "apns-expiration": String(apnsExpiration),
      },
      payload: {
        aps: {
          sound: "default",
          threadId: id,
        },
      },
    },
  };
}

export function buildLegacyMessage(
  content: PushContent,
  language: string,
  override?: Partial<RenderedPush>
): TopicMessage {
  return { topic: legacyTopic(content.gkz, language), ...buildLegacyPayload(content, language, override) };
}

export function toTokenMessage(token: string, payload: Omit<TopicMessage, "topic">): TokenMessage {
  return { token, ...payload };
}

export function messageTarget(message: Message): string {
  if ("topic" in message && message.topic) {
    return `topic:${message.topic}`;
  }
  if ("token" in message && message.token) {
    return `token:…${message.token.slice(-6)}`;
  }
  return "other";
}
