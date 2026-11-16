import { readFile } from "node:fs/promises";
import { staticGeoSphereSource, useStaticGeoSphereResponse } from "./env";
import { AppError, errorMessage } from "./errors";
import { normalizeGkz } from "./municipalities";
import { addDays, isoUtc, viennaDateKey, viennaMidnightUtc } from "./time";

export const GEOSPHERE_WARNSTATUS_URL = "https://warnungen.zamg.at/wsapp/api/getWarnstatus";
const WARNING_TYPE_HEAT = 6;
const MAX_HITZE_V_LEVEL = 4;
const GEO_FETCH_TIMEOUT_MS = 10_000;
const GEO_FETCH_RETRIES = 2;

export interface NormalizedWarning {
  id: string;
  /** Hitze-V scale (GeoSphere wlevel + 1), clamped to 4. */
  level: number;
  municipalities: string[];
  /** ISO-8601 UTC or "". */
  start: string;
  end: string;
  startMs: number | null;
  endMs: number | null;
  geometry: unknown;
}

/** Aggregate of all warnings for one municipality on one Vienna calendar day. */
export interface GkzDay {
  gkz: string;
  date: string;
  level: number;
  start: string;
  end: string;
  warningIds: string[];
}

export interface FeedResult {
  features: unknown[];
  source: "live" | "static";
  sourceLocation: string;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null;
}

function asString(value: unknown): string | null {
  if (typeof value !== "string") {
    return null;
  }
  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : null;
}

function asNumber(value: unknown): number | null {
  if (typeof value === "number" && Number.isFinite(value)) {
    return value;
  }
  if (typeof value === "string" && value.trim()) {
    const parsed = Number(value);
    return Number.isFinite(parsed) ? parsed : null;
  }
  return null;
}

function rawInfoOf(properties: Record<string, unknown>): Record<string, unknown> | null {
  if (isRecord(properties.rawinfo)) {
    return properties.rawinfo;
  }
  return isRecord(properties.rawfinfo) ? properties.rawfinfo : null;
}

function geoSphereLevel(properties: Record<string, unknown>): number | null {
  const direct =
    asNumber(properties.wlevel) ?? asNumber(properties.warning_level) ?? asNumber(properties.warnstufeid);
  if (direct !== null) {
    return direct;
  }
  const rawInfo = rawInfoOf(properties);
  if (!rawInfo) {
    return null;
  }
  return asNumber(rawInfo.wlevel) ?? asNumber(rawInfo.warning_level) ?? asNumber(rawInfo.warnstufeid);
}

function parseTimestampMs(value: unknown): number | null {
  const numeric = asNumber(value);
  if (numeric !== null) {
    // GeoSphere sends unix seconds; very large values are already milliseconds.
    return numeric > 100_000_000_000 ? Math.trunc(numeric) : Math.trunc(numeric * 1000);
  }
  const text = asString(value);
  if (!text) {
    return null;
  }
  const parsed = Date.parse(text);
  return Number.isNaN(parsed) ? null : parsed;
}

function isHeatWarning(properties: Record<string, unknown>): boolean {
  const candidates = [
    properties.wtype,
    properties.warn_type,
    properties.warning_type,
    properties.warntypid,
  ];
  const rawInfo = rawInfoOf(properties);
  if (rawInfo) {
    candidates.push(rawInfo.wtype, rawInfo.warn_type, rawInfo.warning_type, rawInfo.warntypid);
  }

  return candidates.some((candidate) => {
    if (asNumber(candidate) === WARNING_TYPE_HEAT) {
      return true;
    }
    const text = asString(candidate)?.toLowerCase();
    return Boolean(text && (text.includes("hitze") || text.includes("heat")));
  });
}

function municipalityIds(properties: Record<string, unknown>): string[] {
  const value = properties.gemeinden ?? properties.municipalities;
  if (!Array.isArray(value)) {
    return [];
  }
  const ids = new Set<string>();
  for (const entry of value) {
    if (typeof entry !== "string" && typeof entry !== "number") {
      continue;
    }
    const id = normalizeGkz(entry);
    if (id) {
      ids.add(id);
    }
  }
  return Array.from(ids).sort();
}

function warningId(properties: Record<string, unknown>, fallback: string): string {
  for (const candidate of [properties.warnid, properties.warning_id, properties.id]) {
    const text = asString(candidate);
    if (text) {
      return text;
    }
    const numeric = asNumber(candidate);
    if (numeric !== null) {
      return String(numeric);
    }
  }
  return fallback;
}

export function normalizeWarning(
  rawFeature: unknown,
  index: number,
  minLevel: number,
  nowMs: number
): NormalizedWarning | null {
  if (!isRecord(rawFeature) || !isRecord(rawFeature.properties)) {
    return null;
  }
  const properties = rawFeature.properties;
  if (!isHeatWarning(properties)) {
    return null;
  }

  const rawLevel = geoSphereLevel(properties);
  if (rawLevel === null || rawLevel <= 0) {
    return null;
  }
  const level = Math.min(MAX_HITZE_V_LEVEL, Math.trunc(rawLevel) + 1);
  if (level < Math.max(2, minLevel)) {
    return null;
  }

  const municipalities = municipalityIds(properties);
  if (municipalities.length === 0) {
    return null;
  }

  const rawInfo = rawInfoOf(properties);
  const startMs =
    parseTimestampMs(properties.begin) ??
    parseTimestampMs(properties.start) ??
    parseTimestampMs(rawInfo?.begin) ??
    parseTimestampMs(rawInfo?.start);
  const endMs = parseTimestampMs(properties.end) ?? parseTimestampMs(rawInfo?.end);
  if (endMs !== null && endMs <= nowMs) {
    return null;
  }

  return {
    id: warningId(properties, `fallback-${index}`),
    level,
    municipalities,
    start: startMs === null ? "" : isoUtc(startMs),
    end: endMs === null ? "" : isoUtc(endMs),
    startMs,
    endMs,
    geometry: rawFeature.geometry,
  };
}

export function normalizeFeatures(features: unknown[], minLevel: number, nowMs: number): NormalizedWarning[] {
  const result: NormalizedWarning[] = [];
  features.forEach((feature, index) => {
    const warning = normalizeWarning(feature, index, minLevel, nowMs);
    if (warning) {
      result.push(warning);
    }
  });
  return result;
}

interface DayAccumulator {
  gkz: string;
  date: string;
  level: number;
  startMs: number;
  endMs: number | null;
  openEnd: boolean;
  warningIds: Set<string>;
}

/** Bounds the per-warning day loop against a bogus far-future end; only today/tomorrow are pushed. */
const MAX_DAYS_AHEAD = 14;

interface DayPiece {
  date: string;
  startMs: number;
  /** null = unknown end (only on the warning's last day). */
  endMs: number | null;
}

/**
 * The Vienna days (from today on) a warning overlaps, with start/end clipped to each day.
 * A warning without start begins today; one without end covers its start day up to today.
 */
export function splitIntoViennaDays(warning: NormalizedWarning, nowMs: number): DayPiece[] {
  const today = viennaDateKey(nowMs);
  const startMs = warning.startMs ?? viennaMidnightUtc(today);
  const startDate = viennaDateKey(startMs);
  const lastDate =
    warning.endMs === null
      ? startDate > today
        ? startDate
        : today
      : viennaDateKey(warning.endMs - 1);
  const firstDate = startDate > today ? startDate : today;
  const limitDate = addDays(today, MAX_DAYS_AHEAD);

  const pieces: DayPiece[] = [];
  for (let date = firstDate; date <= lastDate && date <= limitDate; date = addDays(date, 1)) {
    const dayStartMs = viennaMidnightUtc(date);
    const nextDayStartMs = viennaMidnightUtc(addDays(date, 1));
    pieces.push({
      date,
      startMs: Math.max(startMs, dayStartMs),
      endMs:
        warning.endMs === null
          ? date === lastDate
            ? null
            : nextDayStartMs
          : Math.min(warning.endMs, nextDayStartMs),
    });
  }
  return pieces;
}

/**
 * Splits every warning across the Vienna days it overlaps and merges the pieces per
 * municipality and day: highest level, earliest start, latest end (an unknown end keeps
 * the day open). Days before today are dropped; they can no longer be pushed.
 */
export function groupByGkzDay(warnings: NormalizedWarning[], nowMs: number): Map<string, GkzDay[]> {
  const accumulators = new Map<string, DayAccumulator>();

  for (const warning of warnings) {
    for (const piece of splitIntoViennaDays(warning, nowMs)) {
      for (const gkz of warning.municipalities) {
        const key = `${gkz}|${piece.date}`;
        let acc = accumulators.get(key);
        if (!acc) {
          acc = {
            gkz,
            date: piece.date,
            level: warning.level,
            startMs: piece.startMs,
            endMs: piece.endMs,
            openEnd: false,
            warningIds: new Set(),
          };
          accumulators.set(key, acc);
        }
        acc.level = Math.max(acc.level, warning.level);
        acc.warningIds.add(warning.id);
        acc.startMs = Math.min(acc.startMs, piece.startMs);
        if (piece.endMs === null) {
          acc.openEnd = true;
        } else if (acc.endMs === null || piece.endMs > acc.endMs) {
          acc.endMs = piece.endMs;
        }
      }
    }
  }

  const byGkz = new Map<string, GkzDay[]>();
  for (const acc of accumulators.values()) {
    const day: GkzDay = {
      gkz: acc.gkz,
      date: acc.date,
      level: acc.level,
      start: isoUtc(acc.startMs),
      end: acc.openEnd || acc.endMs === null ? "" : isoUtc(acc.endMs),
      warningIds: Array.from(acc.warningIds).sort(),
    };
    const list = byGkz.get(acc.gkz) ?? [];
    list.push(day);
    byGkz.set(acc.gkz, list);
  }
  for (const list of byGkz.values()) {
    list.sort((a, b) => a.date.localeCompare(b.date));
  }
  return byGkz;
}

export function extractFeatures(payload: unknown): unknown[] | null {
  if (isRecord(payload) && Array.isArray(payload.features)) {
    return payload.features;
  }
  if (isRecord(payload)) {
    for (const nested of Object.values(payload)) {
      if (isRecord(nested) && Array.isArray(nested.features)) {
        return nested.features;
      }
      const wrapped = isRecord(nested) ? nested.value : null;
      if (isRecord(wrapped) && Array.isArray(wrapped.features)) {
        return wrapped.features;
      }
    }
  }
  return null;
}

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function fetchJsonWithRetry(url: string, requestId: string): Promise<unknown> {
  let lastError: unknown;

  for (let attempt = 0; attempt <= GEO_FETCH_RETRIES; attempt += 1) {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), GEO_FETCH_TIMEOUT_MS);
    try {
      const response = await fetch(url, {
        method: "GET",
        headers: { Accept: "application/json" },
        signal: controller.signal,
      });
      if (!response.ok) {
        throw new AppError(502, "GEOSPHERE_HTTP_ERROR", `GeoSphere returned HTTP ${response.status}.`);
      }
      return await response.json();
    } catch (error) {
      lastError = error;
      if (attempt >= GEO_FETCH_RETRIES) {
        break;
      }
      console.warn(`[${requestId}] geosphere_fetch_retry`, { attempt, error: errorMessage(error) });
      await sleep(400 * (attempt + 1));
    } finally {
      clearTimeout(timeout);
    }
  }

  if (lastError instanceof AppError) {
    throw lastError;
  }
  throw new AppError(502, "GEOSPHERE_FETCH_FAILED", `GeoSphere fetch failed: ${errorMessage(lastError)}`);
}

export async function fetchGeoSphereFeed(requestId: string): Promise<FeedResult> {
  let payload: unknown;
  let source: FeedResult["source"] = "live";
  let sourceLocation = GEOSPHERE_WARNSTATUS_URL;

  if (useStaticGeoSphereResponse()) {
    const staticSource = staticGeoSphereSource();
    source = "static";
    sourceLocation = staticSource.location;
    if (staticSource.kind === "url") {
      payload = await fetchJsonWithRetry(staticSource.location, requestId);
    } else {
      try {
        payload = JSON.parse(await readFile(staticSource.location, "utf8"));
      } catch (error) {
        throw new AppError(500, "CONFIG_ERROR", `Static GeoSphere file could not be read: ${errorMessage(error)}`);
      }
    }
  } else {
    payload = await fetchJsonWithRetry(GEOSPHERE_WARNSTATUS_URL, requestId);
  }

  const features = extractFeatures(payload);
  if (!features) {
    throw new AppError(502, "GEOSPHERE_SCHEMA_INVALID", "GeoSphere payload is missing a valid features array.");
  }
  return { features, source, sourceLocation };
}
