import type { GkzDay } from "./feed";
import type { PushDay } from "./renderer";
import { addDays, parseIsoMs, viennaDateKey, viennaMidnightUtc } from "./time";

/** Last state communicated (or silently accepted) for one municipality and Vienna date. */
export interface DayState {
  /** Level last seen in the feed (pushed or silently accepted, e.g. a downgrade). */
  level: number;
  /** Highest level actually pushed for this date; only a level above it is `escalated`. */
  pushedLevel: number;
  start: string;
  end: string;
  /** Vienna date of the last push that contained this day ("" if never pushed, e.g. only silent updates). */
  sentDayKey: string;
  /** Vienna date of the last `updated` push for this day; limits `updated` to once per Vienna day. */
  updatedDayKey: string;
}

export type PushableEvent = "new" | "escalated" | "updated";

export type DayClass =
  | "new"
  | "escalated"
  | "updated"
  /** window changed but an `updated` push was already sent today; retried on a later run */
  | "updated-limited"
  /** downgrade or irrelevant window change: state is saved without a push */
  | "silent"
  | "unchanged";

export interface ClassifiedDay {
  day: GkzDay;
  cls: DayClass;
  previous: DayState | undefined;
}

export interface GkzDecision {
  gkz: string;
  event: PushableEvent | null;
  /** Days carried in the push, sorted by date. */
  days: GkzDay[];
  classified: ClassifiedDay[];
  /** State to write after the v2 push succeeded. */
  pushedStates: Record<string, DayState>;
  /** State to write regardless of any push (downgrades, irrelevant window changes). */
  silentStates: Record<string, DayState>;
}

export function dayStateKey(gkz: string, date: string): string {
  return `${gkz}|${date}`;
}

export function dateOfStateKey(key: string): string {
  return key.slice(key.lastIndexOf("|") + 1);
}

export function toPushDay(day: GkzDay): PushDay {
  return { date: day.date, level: day.level, start: day.start, end: day.end };
}

function startMsOrMidnight(value: string, date: string): number {
  return parseIsoMs(value) ?? viennaMidnightUtc(date);
}

function endMsOrMidnight(value: string, date: string): number {
  return parseIsoMs(value) ?? viennaMidnightUtc(addDays(date, 1));
}

/**
 * A changed start only matters while the previous start is still ahead: once the warning
 * has begun, a later start is just a sub-warning that expired. A changed end matters while
 * either end is ahead.
 */
export function windowChangeMatters(previous: DayState, day: GkzDay, nowMs: number): boolean {
  const startMatters =
    previous.start !== day.start && startMsOrMidnight(previous.start, day.date) > nowMs;
  const endMatters =
    previous.end !== day.end &&
    Math.max(endMsOrMidnight(previous.end, day.date), endMsOrMidnight(day.end, day.date)) > nowMs;
  return startMatters || endMatters;
}

export function classifyDay(
  day: GkzDay,
  previous: DayState | undefined,
  nowMs: number
): DayClass {
  if (!previous) {
    return "new";
  }
  if (day.level > previous.pushedLevel) {
    return "escalated";
  }
  // Downgrades and re-rises up to the pushed level (a flapping feed) are only recorded.
  if (day.level !== previous.level) {
    return "silent";
  }
  if (previous.start === day.start && previous.end === day.end) {
    return "unchanged";
  }
  if (!windowChangeMatters(previous, day, nowMs)) {
    return "silent";
  }
  return previous.updatedDayKey === viennaDateKey(nowMs) ? "updated-limited" : "updated";
}

const EVENT_PRIORITY: Record<PushableEvent, number> = { escalated: 3, new: 2, updated: 1 };

export function pushableDays(days: GkzDay[], nowMs: number): GkzDay[] {
  const today = viennaDateKey(nowMs);
  const tomorrow = addDays(today, 1);
  return days.filter((day) => day.date === today || day.date === tomorrow);
}

export function decideForGkz(
  gkz: string,
  days: GkzDay[],
  previousStates: ReadonlyMap<string, DayState>,
  nowMs: number
): GkzDecision {
  const today = viennaDateKey(nowMs);
  const classified: ClassifiedDay[] = pushableDays(days, nowMs).map((day) => {
    const previous = previousStates.get(dayStateKey(gkz, day.date));
    return { day, cls: classifyDay(day, previous, nowMs), previous };
  });

  let event: PushableEvent | null = null;
  for (const entry of classified) {
    if (entry.cls === "new" || entry.cls === "escalated" || entry.cls === "updated") {
      if (!event || EVENT_PRIORITY[entry.cls] > EVENT_PRIORITY[event]) {
        event = entry.cls;
      }
    }
  }

  // `updated` carries only the changed days so the body names the right day;
  // `new`/`escalated` carry every pushable day.
  const included = classified.filter((entry) =>
    event === null ? false : event === "updated" ? entry.cls === "updated" : true
  );

  const pushedStates: Record<string, DayState> = {};
  for (const entry of included) {
    pushedStates[dayStateKey(gkz, entry.day.date)] = {
      level: entry.day.level,
      pushedLevel: Math.max(entry.previous?.pushedLevel ?? 0, entry.day.level),
      start: entry.day.start,
      end: entry.day.end,
      sentDayKey: today,
      updatedDayKey: entry.cls === "updated" ? today : entry.previous?.updatedDayKey ?? "",
    };
  }

  const silentStates: Record<string, DayState> = {};
  for (const entry of classified) {
    if (entry.cls !== "silent" || included.includes(entry)) {
      continue;
    }
    silentStates[dayStateKey(gkz, entry.day.date)] = {
      level: entry.day.level,
      pushedLevel: entry.previous?.pushedLevel ?? entry.day.level,
      start: entry.day.start,
      end: entry.day.end,
      sentDayKey: entry.previous?.sentDayKey ?? "",
      updatedDayKey: entry.previous?.updatedDayKey ?? "",
    };
  }

  return {
    gkz,
    event,
    days: included.map((entry) => entry.day),
    classified,
    pushedStates,
    silentStates,
  };
}

export function decideAll(
  byGkz: ReadonlyMap<string, GkzDay[]>,
  previousStates: ReadonlyMap<string, DayState>,
  nowMs: number
): GkzDecision[] {
  return Array.from(byGkz.keys())
    .sort()
    .map((gkz) => decideForGkz(gkz, byGkz.get(gkz) ?? [], previousStates, nowMs));
}

/** State keys of days that are over in Vienna; they can no longer be pushed. */
export function expiredStateKeys(keys: Iterable<string>, nowMs: number): string[] {
  const today = viennaDateKey(nowMs);
  return Array.from(keys).filter((key) => dateOfStateKey(key) < today);
}
