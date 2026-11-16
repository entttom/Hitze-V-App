export const VIENNA_TIME_ZONE = "Europe/Vienna";

const viennaPartsFormatter = new Intl.DateTimeFormat("en-CA", {
  timeZone: VIENNA_TIME_ZONE,
  year: "numeric",
  month: "2-digit",
  day: "2-digit",
  hour: "2-digit",
  minute: "2-digit",
  second: "2-digit",
  hourCycle: "h23",
});

export interface ViennaParts {
  year: number;
  month: number;
  day: number;
  hour: number;
  minute: number;
  second: number;
}

export function viennaParts(epochMs: number): ViennaParts {
  const parts = viennaPartsFormatter.formatToParts(new Date(epochMs));
  const value = (type: Intl.DateTimeFormatPartTypes): number =>
    Number(parts.find((part) => part.type === type)?.value ?? "0");

  return {
    year: value("year"),
    month: value("month"),
    day: value("day"),
    hour: value("hour") % 24,
    minute: value("minute"),
    second: value("second"),
  };
}

function pad2(value: number): string {
  return String(value).padStart(2, "0");
}

/** `YYYY-MM-DD` of the instant in Europe/Vienna. */
export function viennaDateKey(epochMs: number): string {
  const p = viennaParts(epochMs);
  return `${p.year}-${pad2(p.month)}-${pad2(p.day)}`;
}

/** `HH:mm` (24 h) of the instant in Europe/Vienna. */
export function viennaClock(epochMs: number): string {
  const p = viennaParts(epochMs);
  return `${pad2(p.hour)}:${pad2(p.minute)}`;
}

export function viennaHour(epochMs: number): number {
  return viennaParts(epochMs).hour;
}

function parseDateKey(dateKey: string): { year: number; month: number; day: number } {
  const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(dateKey);
  if (!match) {
    throw new Error(`Invalid date key '${dateKey}'.`);
  }
  return { year: Number(match[1]), month: Number(match[2]), day: Number(match[3]) };
}

export function addDays(dateKey: string, days: number): string {
  const { year, month, day } = parseDateKey(dateKey);
  const date = new Date(Date.UTC(year, month - 1, day + days));
  return `${date.getUTCFullYear()}-${pad2(date.getUTCMonth() + 1)}-${pad2(date.getUTCDate())}`;
}

/** 1 = Monday … 7 = Sunday. */
export function isoWeekday(dateKey: string): number {
  const { year, month, day } = parseDateKey(dateKey);
  const weekday = new Date(Date.UTC(year, month - 1, day)).getUTCDay();
  return weekday === 0 ? 7 : weekday;
}

/** UTC instant of 00:00 Europe/Vienna on the given date. */
export function viennaMidnightUtc(dateKey: string): number {
  const { year, month, day } = parseDateKey(dateKey);
  const wallClockAsUtc = Date.UTC(year, month - 1, day);
  let guess = wallClockAsUtc;
  // Two passes settle the offset (Vienna never switches DST at midnight).
  for (let i = 0; i < 2; i += 1) {
    const p = viennaParts(guess);
    const offset = Date.UTC(p.year, p.month - 1, p.day, p.hour, p.minute, p.second) - guess;
    guess = wallClockAsUtc - offset;
  }
  return guess;
}

/** ISO-8601 UTC without milliseconds (`2026-07-07T08:00:00Z`), parseable by every platform formatter. */
export function isoUtc(epochMs: number): string {
  return new Date(Math.floor(epochMs / 1000) * 1000).toISOString().replace(".000Z", "Z");
}

export function parseIsoMs(value: string): number | null {
  if (!value) {
    return null;
  }
  const parsed = Date.parse(value);
  return Number.isNaN(parsed) ? null : parsed;
}
