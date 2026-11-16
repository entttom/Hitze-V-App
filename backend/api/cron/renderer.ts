import { readFileSync } from "node:fs";
import path from "node:path";
import { assetsDir } from "./env";
import { addDays, isoWeekday, parseIsoMs, viennaClock, viennaDateKey, viennaMidnightUtc } from "./time";

export type PushEvent = "new" | "escalated" | "updated" | "test";

export interface PushDay {
  /** `YYYY-MM-DD`, Europe/Vienna. */
  date: string;
  /** Hitze-V scale 2..4. */
  level: number;
  /** ISO-8601 UTC or "". */
  start: string;
  end: string;
}

export interface PushCopyLanguage {
  title: string;
  titleEscalated: string;
  titleUpdated: string;
  titleTest: string;
  levelNames: Record<string, string>;
  dayToday: string;
  dayTomorrow: string;
  weekdays: string[];
  allDay: string;
  timeRange: string;
  bodyNew: string;
  bodyEscalated: string;
  bodyUpdated: string;
  bodyTodayTomorrow: string;
  bodyTest: string;
}

export interface PushCopy {
  version: number;
  fallbackLanguage: string;
  languages: Record<string, Partial<PushCopyLanguage>>;
}

export interface RenderedPush {
  title: string;
  body: string;
}

const STRING_KEYS = [
  "title",
  "titleEscalated",
  "titleUpdated",
  "titleTest",
  "dayToday",
  "dayTomorrow",
  "allDay",
  "timeRange",
  "bodyNew",
  "bodyEscalated",
  "bodyUpdated",
  "bodyTodayTomorrow",
  "bodyTest",
] as const;

let cachedCopy: PushCopy | null = null;

export function pushCopyPath(): string {
  return path.join(assetsDir(), "push-copy.json");
}

export function parsePushCopy(raw: unknown): PushCopy {
  if (typeof raw !== "object" || raw === null) {
    throw new Error("push-copy.json must contain an object.");
  }
  const record = raw as Record<string, unknown>;
  const languages = record.languages;
  const fallbackLanguage = record.fallbackLanguage;
  if (typeof languages !== "object" || languages === null || typeof fallbackLanguage !== "string") {
    throw new Error("push-copy.json needs 'languages' and 'fallbackLanguage'.");
  }
  const copy: PushCopy = {
    version: typeof record.version === "number" ? record.version : 1,
    fallbackLanguage,
    languages: languages as Record<string, Partial<PushCopyLanguage>>,
  };
  // The fallback language must be complete; other languages may be partial and borrow from it.
  const fallback = copy.languages[fallbackLanguage];
  if (!fallback || !isCompleteLanguage(fallback)) {
    throw new Error(`push-copy.json fallback language '${fallbackLanguage}' is missing or incomplete.`);
  }
  return copy;
}

function isCompleteLanguage(language: Partial<PushCopyLanguage>): language is PushCopyLanguage {
  return (
    STRING_KEYS.every((key) => typeof language[key] === "string") &&
    Array.isArray(language.weekdays) &&
    language.weekdays.length === 7 &&
    typeof language.levelNames === "object" &&
    language.levelNames !== null
  );
}

export function loadPushCopy(): PushCopy {
  if (!cachedCopy) {
    cachedCopy = parsePushCopy(JSON.parse(readFileSync(pushCopyPath(), "utf8")));
  }
  return cachedCopy;
}

export function availableCopyLanguages(copy: PushCopy = loadPushCopy()): string[] {
  return Object.keys(copy.languages);
}

/** Merges the requested language over the fallback language, key by key. */
export function resolveCopyLanguage(copy: PushCopy, language: string): PushCopyLanguage {
  const fallback = copy.languages[copy.fallbackLanguage] as PushCopyLanguage;
  const requested = copy.languages[language.trim().toLowerCase()];
  if (!requested) {
    return fallback;
  }

  const merged: PushCopyLanguage = { ...fallback, levelNames: { ...fallback.levelNames } };
  for (const key of STRING_KEYS) {
    const value = requested[key];
    if (typeof value === "string" && value.length > 0) {
      merged[key] = value;
    }
  }
  if (Array.isArray(requested.weekdays) && requested.weekdays.length === 7) {
    merged.weekdays = requested.weekdays;
  }
  if (requested.levelNames && typeof requested.levelNames === "object") {
    Object.assign(merged.levelNames, requested.levelNames);
  }
  return merged;
}

function fill(template: string, values: Record<string, string | number>): string {
  let result = template;
  for (const [key, value] of Object.entries(values)) {
    result = result.split(`{${key}}`).join(String(value));
  }
  return result;
}

export function dayLabel(copy: PushCopyLanguage, date: string, nowMs: number): string {
  const today = viennaDateKey(nowMs);
  if (date === today) {
    return copy.dayToday;
  }
  if (date === addDays(today, 1)) {
    return copy.dayTomorrow;
  }
  return copy.weekdays[isoWeekday(date) - 1] ?? date;
}

export function timeText(copy: PushCopyLanguage, day: PushDay): string {
  const dayStart = viennaMidnightUtc(day.date);
  const nextDayStart = viennaMidnightUtc(addDays(day.date, 1));
  const startMs = parseIsoMs(day.start);
  const endMs = parseIsoMs(day.end);

  const start = startMs === null || startMs <= dayStart ? "00:00" : viennaClock(startMs);
  const end = endMs === null || endMs >= nextDayStart ? "24:00" : viennaClock(endMs);

  if (start === "00:00" && end === "24:00") {
    return copy.allDay;
  }
  return fill(copy.timeRange, { start, end });
}

function levelName(copy: PushCopyLanguage, level: number): string {
  return copy.levelNames[String(level)] ?? String(level);
}

export interface RenderInput {
  event: PushEvent;
  name: string;
  days: PushDay[];
  nowMs: number;
  language: string;
}

export function renderPush(input: RenderInput, copyFile: PushCopy = loadPushCopy()): RenderedPush {
  const copy = resolveCopyLanguage(copyFile, input.language);
  const { event, name, days, nowMs } = input;

  const title =
    event === "escalated"
      ? copy.titleEscalated
      : event === "updated"
        ? copy.titleUpdated
        : event === "test"
          ? copy.titleTest
          : copy.title;

  if (event === "test") {
    return { title, body: fill(copy.bodyTest, { name }) };
  }

  if (days.length === 0) {
    throw new Error("renderPush needs at least one day for non-test events.");
  }

  if (days.length === 2 && event !== "updated") {
    const [first, second] = days;
    return {
      title,
      body: fill(copy.bodyTodayTomorrow, {
        name,
        level1: first.level,
        levelName1: levelName(copy, first.level),
        time1: timeText(copy, first),
        level2: second.level,
        levelName2: levelName(copy, second.level),
        time2: timeText(copy, second),
      }),
    };
  }

  const day = days[0];
  const template = event === "escalated" ? copy.bodyEscalated : event === "updated" ? copy.bodyUpdated : copy.bodyNew;
  return {
    title,
    body: fill(template, {
      day: dayLabel(copy, day.date, nowMs),
      name,
      level: day.level,
      levelName: levelName(copy, day.level),
      time: timeText(copy, day),
    }),
  };
}
