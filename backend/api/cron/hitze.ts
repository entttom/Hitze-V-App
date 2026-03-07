import { createHash, randomUUID } from "node:crypto";
import { existsSync } from "node:fs";
import path from "node:path";
import { cert, getApps, initializeApp } from "firebase-admin/app";
import { getMessaging, type Messaging } from "firebase-admin/messaging";
import { createClient, type RedisClientType } from "redis";
import * as XLSX from "xlsx";

const GEOSPHERE_WARNSTATUS_URL = "https://warnungen.zamg.at/wsapp/api/getWarnstatus";
const GEOSPHERE_STATIC_WARNSTATUS_URL =
  "https://raw.githubusercontent.com/entttom/Hitze-V-App/main/backend/example_response.json";
const REDIS_SIGNATURE_KEY = "hitze:v1:signatures";
const REDIS_SEND_META_KEY = "hitze:v1:send_meta";
const SEND_META_RETENTION_DAYS = 7;
const WARNING_TYPE_HEAT = 6;
const WARNING_TYPE_COLD = 7;
const MUNICIPALITY_LIST_FILE = "gemliste_knz.xls";
const DEFAULT_MIN_WARNING_LEVEL = 2;
const GEO_FETCH_TIMEOUT_MS = 10_000;
const GEO_FETCH_RETRIES = 2;

let messagingClient: Messaging | null = null;
let redisClient: RedisClientType | null = null;
let municipalityNameById: Map<string, string> | null = null;
let testMunicipalityOptions: TestMunicipalityOption[] | null = null;

type WarningKind = "heat" | "cold";

interface NormalizedWarning {
  id: string;
  kind: WarningKind;
  level: number;
  municipalities: string[];
  start: string;
  end: string;
}

interface MunicipalityAggregate {
  municipalityId: string;
  kind: WarningKind;
  maxLevel: number;
  warningIds: Set<string>;
  starts: Set<string>;
  ends: Set<string>;
}

interface HandlerSuccessResponse {
  requestId: string;
  processedWarnings: number;
  affectedMunicipalities: number;
  sent: number;
  skippedUnchanged: number;
  skippedRateLimited: number;
  cleared: number;
  failed: number;
  durationMs: number;
  failedMunicipalities: string[];
}

interface AggregateSendMetadata {
  dayKey: string;
  start: string;
  end: string;
}

interface TimeWindow {
  start: string;
  end: string;
}

interface SendCandidate {
  aggregate: MunicipalityAggregate;
  previousTimeWindow: TimeWindow | null;
  timeWindowChanged: boolean;
}

class AppError extends Error {
  constructor(
    public readonly status: number,
    public readonly code: string,
    message: string
  ) {
    super(message);
    this.name = "AppError";
  }
}

class RedisUnavailableError extends AppError {
  constructor(message: string) {
    super(503, "REDIS_UNAVAILABLE", message);
    this.name = "RedisUnavailableError";
  }
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

  if (typeof value === "string") {
    const parsed = Number(value);
    return Number.isFinite(parsed) ? parsed : null;
  }

  return null;
}

function normalizeMunicipalityId(value: string): string {
  return value.replace(/\s+/g, "");
}

function getWarningLevel(properties: Record<string, unknown>): number | null {
  const directLevel =
    asNumber(properties.wlevel) ??
    asNumber(properties.warning_level) ??
    asNumber(properties.warnstufeid);

  if (directLevel !== null) {
    return directLevel;
  }

  const rawInfo = isRecord(properties.rawinfo)
    ? properties.rawinfo
    : isRecord(properties.rawfinfo)
      ? properties.rawfinfo
      : null;

  if (!rawInfo) {
    return null;
  }

  return (
    asNumber(rawInfo.wlevel) ??
    asNumber(rawInfo.warning_level) ??
    asNumber(rawInfo.warnstufeid)
  );
}

function getRawInfo(properties: Record<string, unknown>): Record<string, unknown> | null {
  return isRecord(properties.rawinfo)
    ? properties.rawinfo
    : isRecord(properties.rawfinfo)
      ? properties.rawfinfo
      : null;
}

function parseTimestampToEpochMs(value: unknown): number | null {
  const numeric = asNumber(value);
  if (numeric !== null) {
    // GeoSphere unix values are usually seconds; larger values are assumed to be milliseconds.
    return numeric > 100_000_000_000 ? Math.trunc(numeric) : Math.trunc(numeric * 1000);
  }

  const str = asString(value);
  if (!str) {
    return null;
  }

  if (/^\d+(\.\d+)?$/.test(str)) {
    const asNumeric = Number(str);
    if (Number.isFinite(asNumeric)) {
      return asNumeric > 100_000_000_000 ? Math.trunc(asNumeric) : Math.trunc(asNumeric * 1000);
    }
    return null;
  }

  const parsed = Date.parse(str);
  return Number.isNaN(parsed) ? null : parsed;
}

function toIsoUtc(epochMs: number | null): string {
  if (epochMs === null) {
    return "";
  }

  return new Date(epochMs).toISOString();
}

function getWarningTimeWindow(properties: Record<string, unknown>): { start: string; end: string; endMs: number | null } {
  const rawInfo = getRawInfo(properties);

  const startMs =
    parseTimestampToEpochMs(properties.begin) ??
    parseTimestampToEpochMs(properties.start) ??
    parseTimestampToEpochMs(rawInfo?.begin) ??
    parseTimestampToEpochMs(rawInfo?.start);

  const endMs =
    parseTimestampToEpochMs(properties.end) ??
    parseTimestampToEpochMs(rawInfo?.end);

  return {
    start: toIsoUtc(startMs),
    end: toIsoUtc(endMs),
    endMs,
  };
}

function mapWarningTypeToKind(value: unknown): WarningKind | null {
  const numericType = asNumber(value);
  if (numericType === WARNING_TYPE_HEAT) {
    return "heat";
  }

  if (numericType === WARNING_TYPE_COLD) {
    return "cold";
  }

  return null;
}

function getWarningKind(properties: Record<string, unknown>): WarningKind | null {
  const directType =
    properties.wtype ??
    properties.warn_type ??
    properties.warning_type ??
    properties.warntypid;

  const directKind = mapWarningTypeToKind(directType);
  if (directKind) {
    return directKind;
  }

  const textualType = asString(directType)?.toLowerCase();
  if (textualType && (textualType.includes("hitze") || textualType.includes("heat"))) {
    return "heat";
  }

  if (textualType && (textualType.includes("kälte") || textualType.includes("kaelte") || textualType.includes("cold"))) {
    return "cold";
  }

  const rawInfo = getRawInfo(properties);

  if (!rawInfo) {
    return null;
  }

  const nestedType = rawInfo.wtype ?? rawInfo.warn_type ?? rawInfo.warning_type ?? rawInfo.warntypid;
  return mapWarningTypeToKind(nestedType);
}

function getMunicipalityIds(properties: Record<string, unknown>): string[] {
  const value = properties.gemeinden ?? properties.municipalities;

  if (!Array.isArray(value)) {
    return [];
  }

  const ids = new Set<string>();

  for (const entry of value) {
    const numeric = asNumber(entry);
    const parsed = asString(entry) ?? (numeric !== null ? String(numeric) : null);

    if (!parsed) {
      continue;
    }

    const normalized = normalizeMunicipalityId(parsed);
    if (normalized.length > 0) {
      ids.add(normalized);
    }
  }

  return Array.from(ids).sort();
}

function getWarningId(properties: Record<string, unknown>, fallbackId: string): string {
  const candidates = [properties.warnid, properties.warning_id, properties.id];

  for (const candidate of candidates) {
    const str = asString(candidate);
    if (str) {
      return str;
    }

    const numeric = asNumber(candidate);
    if (numeric !== null) {
      return String(numeric);
    }
  }

  return fallbackId;
}

function normalizeWarning(
  rawFeature: unknown,
  index: number,
  minWarningLevel: number
): NormalizedWarning | null {
  if (!isRecord(rawFeature)) {
    return null;
  }

  const properties = isRecord(rawFeature.properties) ? rawFeature.properties : null;
  if (!properties) {
    return null;
  }

  const kind = getWarningKind(properties);
  if (!kind) {
    return null;
  }

  // Product decision: ignore cold warnings completely.
  if (kind === "cold") {
    return null;
  }

  const level = getWarningLevel(properties);
  if (level === null || level < minWarningLevel) {
    return null;
  }

  const municipalities = getMunicipalityIds(properties);
  if (municipalities.length === 0) {
    return null;
  }

  const { start, end, endMs } = getWarningTimeWindow(properties);
  if (endMs !== null && endMs <= Date.now()) {
    return null;
  }

  return {
    id: getWarningId(properties, `fallback-${index}`),
    kind,
    level,
    municipalities,
    start,
    end,
  };
}

function aggregateWarnings(warnings: NormalizedWarning[]): Map<string, MunicipalityAggregate> {
  const aggregates = new Map<string, MunicipalityAggregate>();

  for (const warning of warnings) {
    for (const municipalityId of warning.municipalities) {
      const aggregateKey = `${warning.kind}:${municipalityId}`;
      const existing = aggregates.get(aggregateKey);

      if (!existing) {
        const aggregate: MunicipalityAggregate = {
          municipalityId,
          kind: warning.kind,
          maxLevel: warning.level,
          warningIds: new Set([warning.id]),
          starts: warning.start ? new Set([warning.start]) : new Set(),
          ends: warning.end ? new Set([warning.end]) : new Set(),
        };
        aggregates.set(aggregateKey, aggregate);
        continue;
      }

      existing.maxLevel = Math.max(existing.maxLevel, warning.level);
      existing.warningIds.add(warning.id);

      if (warning.start) {
        existing.starts.add(warning.start);
      }

      if (warning.end) {
        existing.ends.add(warning.end);
      }
    }
  }

  return aggregates;
}

function buildMunicipalitySignature(aggregate: MunicipalityAggregate): string {
  const warningIds = Array.from(aggregate.warningIds).sort();
  const starts = Array.from(aggregate.starts).sort();
  const ends = Array.from(aggregate.ends).sort();

  const payload = JSON.stringify({
    municipalityId: aggregate.municipalityId,
    kind: aggregate.kind,
    maxLevel: aggregate.maxLevel,
    warningIds,
    starts,
    ends,
  });

  return createHash("sha256").update(payload).digest("hex");
}

function aggregateTimeWindow(aggregate: MunicipalityAggregate): TimeWindow {
  const starts = Array.from(aggregate.starts).filter((value) => value.length > 0).sort();
  const ends = Array.from(aggregate.ends).filter((value) => value.length > 0).sort();

  return {
    start: starts[0] ?? "",
    end: ends.length > 0 ? ends[ends.length - 1] : "",
  };
}

function formatPushTime(isoValue: string): string {
  if (!isoValue) {
    return "";
  }

  const parsed = Date.parse(isoValue);
  if (Number.isNaN(parsed)) {
    return "";
  }

  return new Intl.DateTimeFormat("de-AT", {
    timeZone: "Europe/Vienna",
    day: "2-digit",
    month: "2-digit",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit",
    hour12: false,
  }).format(new Date(parsed));
}

function formatPushClockTime(isoValue: string): string {
  if (!isoValue) {
    return "";
  }

  const parsed = Date.parse(isoValue);
  if (Number.isNaN(parsed)) {
    return "";
  }

  return new Intl.DateTimeFormat("de-AT", {
    timeZone: "Europe/Vienna",
    hour: "numeric",
    minute: "2-digit",
    hour12: false,
  }).format(new Date(parsed));
}

function dayKeyForIsoValue(isoValue: string): string {
  if (!isoValue) {
    return "";
  }

  const parsed = Date.parse(isoValue);
  if (Number.isNaN(parsed)) {
    return "";
  }

  return currentDayKeyVienna(parsed);
}

function buildTimeWindowText(timeWindow: TimeWindow): string {
  const startText = formatPushTime(timeWindow.start);
  const endText = formatPushTime(timeWindow.end);
  const startClockText = formatPushClockTime(timeWindow.start);
  const endClockText = formatPushClockTime(timeWindow.end);
  const todayDayKey = currentDayKeyVienna();
  const startDayKey = dayKeyForIsoValue(timeWindow.start);
  const endDayKey = dayKeyForIsoValue(timeWindow.end);

  if (startText && endText) {
    if (
      startClockText &&
      endClockText &&
      startDayKey === todayDayKey &&
      endDayKey === todayDayKey
    ) {
      return `Heute von ${startClockText}-${endClockText} Uhr`;
    }

    return `Gueltig: ${startText} - ${endText}`;
  }

  if (startText) {
    if (startClockText && startDayKey === todayDayKey) {
      return `Heute ab ${startClockText} Uhr`;
    }

    return `Ab: ${startText}`;
  }

  if (endText) {
    if (endClockText && endDayKey === todayDayKey) {
      return `Heute bis ${endClockText} Uhr`;
    }

    return `Bis: ${endText}`;
  }

  return "";
}

function buildTimeWindowChangeText(previousTimeWindow: TimeWindow | null, currentTimeWindow: TimeWindow): string {
  const currentText = buildTimeWindowText(currentTimeWindow);
  if (!currentText) {
    return "";
  }

  const previousText = previousTimeWindow ? buildTimeWindowText(previousTimeWindow) : "";
  if (previousText) {
    return `Zeitfenster aktualisiert: von ${previousText} auf ${currentText}.`;
  }

  return `Aktualisiertes Zeitfenster: ${currentText}.`;
}

function municipalityListPaths(): string[] {
  return [
    path.resolve(process.cwd(), MUNICIPALITY_LIST_FILE),
    path.resolve(__dirname, "..", MUNICIPALITY_LIST_FILE),
    path.resolve(__dirname, "..", "..", MUNICIPALITY_LIST_FILE),
    path.resolve(__dirname, "..", "..", "..", MUNICIPALITY_LIST_FILE),
  ];
}

function municipalityListPath(): string {
  for (const candidate of municipalityListPaths()) {
    if (existsSync(candidate)) {
      return candidate;
    }
  }

  return municipalityListPaths()[0];
}

function loadMunicipalityRows(): Array<{ municipalityId: string; name: string }> {
  const filePath = municipalityListPath();

  if (!existsSync(filePath)) {
    console.warn(`municipality_list_not_found: ${filePath}`);
    return [];
  }

  try {
    const workbook = XLSX.readFile(filePath);
    const firstSheet = workbook.Sheets[workbook.SheetNames[0] ?? ""];
    const rows = XLSX.utils.sheet_to_json(firstSheet, {
      header: 1,
      raw: false,
      defval: "",
    }) as unknown[][];

    return rows
      .slice(1)
      .map((row) => {
        const idCandidate =
          asString(row[0]) ?? (asNumber(row[0]) !== null ? String(asNumber(row[0])) : null);
        const name = asString(row[1]);

        if (!idCandidate || !name) {
          return null;
        }

        const municipalityId = normalizeMunicipalityId(idCandidate);
        if (!municipalityId) {
          return null;
        }

        return {
          municipalityId,
          name,
        };
      })
      .filter((row): row is { municipalityId: string; name: string } => row !== null);
  } catch (error) {
    console.warn("municipality_list_load_failed", {
      filePath,
      error: error instanceof Error ? error.message : String(error),
    });
    return [];
  }
}

function loadMunicipalityNameMap(): Map<string, string> {
  if (municipalityNameById) {
    return municipalityNameById;
  }

  const map = new Map<string, string>();
  for (const row of loadMunicipalityRows()) {
    map.set(row.municipalityId, row.name);
  }

  municipalityNameById = map;
  return map;
}

function municipalityDisplayName(municipalityId: string): string {
  const name = loadMunicipalityNameMap().get(municipalityId);
  if (name) {
    return name;
  }

  return `Gemeinde ${municipalityId}`;
}

function getMinWarningLevel(): number {
  const raw = process.env.HITZE_MIN_LEVEL;
  if (!raw) {
    return DEFAULT_MIN_WARNING_LEVEL;
  }

  const value = Number(raw);
  if (!Number.isInteger(value) || value < 1 || value > 3) {
    return DEFAULT_MIN_WARNING_LEVEL;
  }

  return value;
}

function isEnvFlagEnabled(value: string | undefined): boolean {
  if (!value) {
    return false;
  }

  return ["1", "true", "yes", "on"].includes(value.trim().toLowerCase());
}

function useStaticGeoSphereResponse(): boolean {
  return isEnvFlagEnabled(process.env.HITZE_USE_STATIC_GEOSPHERE_RESPONSE);
}

function getGeoSphereWarnstatusUrl(): string {
  return useStaticGeoSphereResponse() ? GEOSPHERE_STATIC_WARNSTATUS_URL : GEOSPHERE_WARNSTATUS_URL;
}

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => {
    setTimeout(resolve, ms);
  });
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
        const body = await response.text();
        throw new AppError(
          502,
          "GEOSPHERE_HTTP_ERROR",
          `GeoSphere returned HTTP ${response.status}. Body: ${body.slice(0, 200)}`
        );
      }

      return await response.json();
    } catch (error) {
      lastError = error;
      const shouldRetry = attempt < GEO_FETCH_RETRIES;

      if (!shouldRetry) {
        break;
      }

      console.warn(`[${requestId}] geosphere_fetch_retry`, {
        attempt,
        error: error instanceof Error ? error.message : String(error),
      });

      await sleep(400 * (attempt + 1));
    } finally {
      clearTimeout(timeout);
    }
  }

  if (lastError instanceof AppError) {
    throw lastError;
  }

  throw new AppError(
    502,
    "GEOSPHERE_FETCH_FAILED",
    `GeoSphere fetch failed: ${lastError instanceof Error ? lastError.message : String(lastError)}`
  );
}

function extractGeoSphereFeatures(payload: unknown): unknown[] | null {
  if (isRecord(payload) && Array.isArray(payload.features)) {
    return payload.features;
  }

  if (isRecord(payload)) {
    for (const nestedValue of Object.values(payload)) {
      if (isRecord(nestedValue) && Array.isArray(nestedValue.features)) {
        return nestedValue.features;
      }

      const wrappedValue = isRecord(nestedValue) ? nestedValue.value : null;
      if (isRecord(wrappedValue) && Array.isArray(wrappedValue.features)) {
        return wrappedValue.features;
      }
    }
  }

  return null;
}

async function fetchGeoSphereWarnings(
  requestId: string,
  minWarningLevel: number
): Promise<NormalizedWarning[]> {
  const payload = await fetchJsonWithRetry(getGeoSphereWarnstatusUrl(), requestId);
  const features = extractGeoSphereFeatures(payload);

  if (!features) {
    throw new AppError(
      502,
      "GEOSPHERE_SCHEMA_INVALID",
      "GeoSphere payload is missing a valid features array."
    );
  }

  const result: NormalizedWarning[] = [];

  features.forEach((feature, index) => {
    const normalized = normalizeWarning(feature, index, minWarningLevel);
    if (normalized) {
      result.push(normalized);
    }
  });

  return result;
}

interface FirebaseServiceAccount {
  projectId: string;
  clientEmail: string;
  privateKey: string;
}

function getFirebaseServiceAccountFromEnv(): FirebaseServiceAccount {
  const raw = process.env.FIREBASE_SERVICE_ACCOUNT;
  if (!raw) {
    throw new AppError(500, "CONFIG_ERROR", "Missing FIREBASE_SERVICE_ACCOUNT environment variable.");
  }

  let parsed: unknown;
  try {
    parsed = JSON.parse(raw);
  } catch {
    throw new AppError(500, "CONFIG_ERROR", "FIREBASE_SERVICE_ACCOUNT is not valid JSON.");
  }

  if (!isRecord(parsed)) {
    throw new AppError(500, "CONFIG_ERROR", "FIREBASE_SERVICE_ACCOUNT must decode into an object.");
  }

  const projectId = asString(parsed.project_id);
  const clientEmail = asString(parsed.client_email);
  const privateKey = asString(parsed.private_key)?.replace(/\\n/g, "\n");

  if (!projectId || !clientEmail || !privateKey) {
    throw new AppError(
      500,
      "CONFIG_ERROR",
      "FIREBASE_SERVICE_ACCOUNT is missing required fields project_id/client_email/private_key."
    );
  }

  return { projectId, clientEmail, privateKey };
}

function getFirebaseMessagingClient(): Messaging {
  if (messagingClient) {
    return messagingClient;
  }

  if (!getApps().length) {
    const serviceAccount = getFirebaseServiceAccountFromEnv();

    initializeApp({
      credential: cert({
        projectId: serviceAccount.projectId,
        clientEmail: serviceAccount.clientEmail,
        privateKey: serviceAccount.privateKey,
      }),
    });
  }

  messagingClient = getMessaging();
  return messagingClient;
}

class RedisStateClient {
  constructor(private readonly client: RedisClientType) {}

  async getSignatures(): Promise<Record<string, string>> {
    try {
      const result = await this.client.hGetAll(REDIS_SIGNATURE_KEY);
      return result ?? {};
    } catch (error) {
      throw new RedisUnavailableError(
        `Redis HGETALL failed: ${error instanceof Error ? error.message : String(error)}`
      );
    }
  }

  async setSignatures(entries: Record<string, string>): Promise<void> {
    const pairs = Object.entries(entries);
    if (pairs.length === 0) {
      return;
    }

    try {
      await this.client.hSet(REDIS_SIGNATURE_KEY, entries);
    } catch (error) {
      throw new RedisUnavailableError(
        `Redis HSET failed: ${error instanceof Error ? error.message : String(error)}`
      );
    }
  }

  async getSendMetadata(): Promise<Record<string, AggregateSendMetadata>> {
    try {
      const result = await this.client.hGetAll(REDIS_SEND_META_KEY);
      if (!result) {
        return {};
      }

      const parsed: Record<string, AggregateSendMetadata> = {};
      for (const [key, value] of Object.entries(result)) {
        try {
          const decoded = JSON.parse(value) as { dayKey?: unknown; start?: unknown };
          const dayKey = asString(decoded.dayKey);
          const start = asString(decoded.start) ?? "";
          const end = asString((decoded as { end?: unknown }).end) ?? "";
          if (!dayKey) {
            continue;
          }

          parsed[key] = { dayKey, start, end };
        } catch {
          // Ignore malformed metadata entries and continue safely.
        }
      }

      return parsed;
    } catch (error) {
      throw new RedisUnavailableError(
        `Redis HGETALL failed: ${error instanceof Error ? error.message : String(error)}`
      );
    }
  }

  async setSendMetadata(entries: Record<string, AggregateSendMetadata>): Promise<void> {
    const serializedEntries: Record<string, string> = {};
    for (const [key, value] of Object.entries(entries)) {
      serializedEntries[key] = JSON.stringify(value);
    }

    if (Object.keys(serializedEntries).length === 0) {
      return;
    }

    try {
      await this.client.hSet(REDIS_SEND_META_KEY, serializedEntries);
    } catch (error) {
      throw new RedisUnavailableError(
        `Redis HSET failed: ${error instanceof Error ? error.message : String(error)}`
      );
    }
  }

  async removeSignatures(municipalityIds: string[]): Promise<number> {
    if (municipalityIds.length === 0) {
      return 0;
    }

    try {
      return await this.client.hDel(REDIS_SIGNATURE_KEY, municipalityIds);
    } catch (error) {
      throw new RedisUnavailableError(
        `Redis HDEL failed: ${error instanceof Error ? error.message : String(error)}`
      );
    }
  }

  async removeSendMetadata(aggregateKeys: string[]): Promise<number> {
    if (aggregateKeys.length === 0) {
      return 0;
    }

    try {
      return await this.client.hDel(REDIS_SEND_META_KEY, aggregateKeys);
    } catch (error) {
      throw new RedisUnavailableError(
        `Redis HDEL failed: ${error instanceof Error ? error.message : String(error)}`
      );
    }
  }
}

async function getRedisClient(): Promise<RedisStateClient> {
  const redisUrl = asString(process.env.REDIS_URL);

  if (!redisUrl) {
    throw new AppError(
      500,
      "CONFIG_ERROR",
      "Missing REDIS_URL environment variable."
    );
  }

  if (!redisClient) {
    redisClient = createClient({ url: redisUrl });
    redisClient.on("error", (error: unknown) => {
      console.error("redis_client_error", {
        error: error instanceof Error ? error.message : String(error),
      });
    });
  }

  try {
    if (!redisClient.isOpen) {
      await redisClient.connect();
    }
  } catch (error) {
    throw new RedisUnavailableError(
      `Redis connect failed: ${error instanceof Error ? error.message : String(error)}`
    );
  }

  return new RedisStateClient(redisClient);
}

function topicForMunicipality(municipalityId: string): string {
  return `warngebiet_${municipalityId}`;
}

function aggregateStateKey(aggregate: MunicipalityAggregate): string {
  return `${aggregate.kind}:${aggregate.municipalityId}`;
}

function currentDayKeyVienna(epochMs: number = Date.now()): string {
  const parts = new Intl.DateTimeFormat("en-CA", {
    timeZone: "Europe/Vienna",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).formatToParts(new Date(epochMs));

  const year = parts.find((part) => part.type === "year")?.value;
  const month = parts.find((part) => part.type === "month")?.value;
  const day = parts.find((part) => part.type === "day")?.value;

  if (!year || !month || !day) {
    return new Date(epochMs).toISOString().slice(0, 10);
  }

  return `${year}-${month}-${day}`;
}

function dayKeyDaysAgoVienna(daysAgo: number): string {
  const millisPerDay = 24 * 60 * 60 * 1000;
  return currentDayKeyVienna(Date.now() - daysAgo * millisPerDay);
}

function pushContentForWarning(
  aggregate: MunicipalityAggregate,
  timeWindow: TimeWindow,
  previousTimeWindow: TimeWindow | null = null,
  timeWindowChanged: boolean = false
): { title: string; body: string; collapsePrefix: string } {
  const name = municipalityDisplayName(aggregate.municipalityId);
  const timeWindowText = buildTimeWindowText(timeWindow);
  const timeWindowChangeText = timeWindowChanged
    ? buildTimeWindowChangeText(previousTimeWindow, timeWindow)
    : "";

  if (aggregate.kind === "cold") {
    const bodyBase = `Achtung extreme Kälte in ${name}, Kälteschutz-Ausrüstung tragen.`;
    return {
      title: "Kälte-Warnung",
      body: timeWindowChangeText
        ? `${bodyBase} ${timeWindowChangeText}`
        : timeWindowText
          ? `${bodyBase} ${timeWindowText}`
          : bodyBase,
      collapsePrefix: "kaelte",
    };
  }

  const bodyBase = `In ${name} wurde Warnstufe ${aggregate.maxLevel} erreicht. Hitzeschutzmaßnahmen nach Hitze-V umsetzen.`;
  return {
    title: "Hitze-Warnung",
    body: timeWindowChangeText
      ? `${bodyBase} ${timeWindowChangeText}`
      : timeWindowText
        ? `${bodyBase} ${timeWindowText}`
        : bodyBase,
    collapsePrefix: "hitze",
  };
}

export interface TestPushInput {
  municipalityId: string;
  title?: string;
  body?: string;
}

export interface TestBulkPushInput {
  municipalityIds: string[];
  title?: string;
  body?: string;
}

export interface TestPushTokenInput {
  token: string;
  title?: string;
  body?: string;
}

export interface TestMunicipalityOption {
  municipalityId: string;
  name: string;
}

export function listTestMunicipalityOptions(): TestMunicipalityOption[] {
  if (testMunicipalityOptions) {
    return testMunicipalityOptions;
  }

  testMunicipalityOptions = loadMunicipalityRows()
    .map((row) => ({
      municipalityId: row.municipalityId,
      name: row.name,
    }))
    .sort((left, right) => left.municipalityId.localeCompare(right.municipalityId, "de-AT"));

  return testMunicipalityOptions;
}

export async function sendTestPushNotification(input: TestPushInput): Promise<{ messageId: string; topic: string }> {
  const municipalityId = input.municipalityId.trim();
  if (!municipalityId) {
    throw new AppError(400, "INVALID_INPUT", "municipalityId is required.");
  }

  const topic = topicForMunicipality(municipalityId);
  const messaging = getFirebaseMessagingClient();

  const messageId = await messaging.send({
    topic,
    notification: {
      title: input.title?.trim() || "Test: Hitze-Warnung",
      body:
        input.body?.trim() ||
        "Dies ist eine manuelle Testnachricht vom Backend.",
    },
    data: {
      gemeindenr: municipalityId,
      source: "manual_test",
      warningLevel: "test",
    },
    apns: {
      headers: {
        "apns-collapse-id": `test-hitze-${municipalityId}`,
      },
      payload: {
        aps: {
          sound: "default",
          "thread-id": `test-hitze-${municipalityId}`,
        },
      },
    },
  });

  return { messageId, topic };
}

export async function sendTestPushNotifications(
  input: TestBulkPushInput
): Promise<{ sent: Array<{ municipalityId: string; topic: string; messageId: string }> }> {
  const municipalityIds = Array.from(
    new Set(
      input.municipalityIds
        .map((municipalityId) => municipalityId.trim())
        .filter((municipalityId) => municipalityId.length > 0)
    )
  );

  if (municipalityIds.length === 0) {
    throw new AppError(400, "INVALID_INPUT", "At least one municipalityId is required.");
  }

  const sent: Array<{ municipalityId: string; topic: string; messageId: string }> = [];

  for (const municipalityId of municipalityIds) {
    const result = await sendTestPushNotification({
      municipalityId,
      title: input.title,
      body: input.body,
    });

    sent.push({
      municipalityId,
      topic: result.topic,
      messageId: result.messageId,
    });
  }

  return { sent };
}

export async function sendTestPushToToken(
  input: TestPushTokenInput
): Promise<{ messageId: string; token: string }> {
  const token = input.token.trim();
  if (!token) {
    throw new AppError(400, "INVALID_INPUT", "token is required.");
  }

  const messaging = getFirebaseMessagingClient();

  const messageId = await messaging.send({
    token,
    notification: {
      title: input.title?.trim() || "Test: Hitze-Warnung (Token)",
      body: input.body?.trim() || "Direkter Testversand an ein einzelnes Gerät.",
    },
    data: {
      source: "manual_test_token",
      warningLevel: "test",
    },
    apns: {
      headers: {
        "apns-collapse-id": "test-hitze-token",
      },
      payload: {
        aps: {
          sound: "default",
          "thread-id": "test-hitze-token",
        },
      },
    },
  });

  return { messageId, token };
}

async function sendMunicipalityWarning(
  messaging: Messaging,
  aggregate: MunicipalityAggregate,
  previousTimeWindow: TimeWindow | null = null,
  timeWindowChanged: boolean = false
): Promise<void> {
  const topic = topicForMunicipality(aggregate.municipalityId);
  const warningIds = Array.from(aggregate.warningIds).sort();
  const timeWindow = aggregateTimeWindow(aggregate);
  const content = pushContentForWarning(
    aggregate,
    timeWindow,
    previousTimeWindow,
    timeWindowChanged
  );
  const collapseId = `${content.collapsePrefix}-${aggregate.municipalityId}`;
  const warningStartLocal = formatPushTime(timeWindow.start);
  const warningEndLocal = formatPushTime(timeWindow.end);

  await messaging.send({
    topic,
    notification: {
      title: content.title,
      body: content.body,
    },
    data: {
      gemeindenr: aggregate.municipalityId,
      gemeindename: municipalityDisplayName(aggregate.municipalityId),
      warningKind: aggregate.kind,
      warningLevel: String(aggregate.maxLevel),
      warningIds: warningIds.join(","),
      warningStart: timeWindow.start,
      warningEnd: timeWindow.end,
      warningStartLocal,
      warningEndLocal,
      source: "geosphere",
    },
    apns: {
      headers: {
        "apns-collapse-id": collapseId,
      },
      payload: {
        aps: {
          sound: "default",
          "thread-id": collapseId,
        },
      },
    },
  });
}

function mapError(error: unknown): AppError {
  if (error instanceof AppError) {
    return error;
  }

  return new AppError(
    500,
    "INTERNAL_ERROR",
    error instanceof Error ? error.message : "Unexpected error"
  );
}

export interface HitzeCronHttpResponse {
  status: number;
  headers?: Record<string, string>;
  body: Record<string, unknown>;
}

export async function executeHitzeCron(method?: string): Promise<HitzeCronHttpResponse> {
  const startedAt = Date.now();
  const requestId = randomUUID();

  if (method && !["GET", "POST"].includes(method.toUpperCase())) {
    return {
      status: 405,
      headers: { Allow: "GET, POST" },
      body: {
        requestId,
        errorCode: "METHOD_NOT_ALLOWED",
        message: "Only GET or POST are allowed.",
      },
    };
  }

  try {
    const minWarningLevel = getMinWarningLevel();
    const normalizedWarnings = await fetchGeoSphereWarnings(requestId, minWarningLevel);
    const aggregatesMap = aggregateWarnings(normalizedWarnings);

    const aggregates = Array.from(aggregatesMap.values()).sort((a, b) =>
      aggregateStateKey(a).localeCompare(aggregateStateKey(b))
    );

    const currentSignatures: Record<string, string> = {};
    for (const aggregate of aggregates) {
      currentSignatures[aggregateStateKey(aggregate)] = buildMunicipalitySignature(aggregate);
    }

    // Fail-closed: without Redis state comparison no push is sent.
    const redis = await getRedisClient();
    const previousSignatures = await redis.getSignatures();
    const previousSendMetadata = await redis.getSendMetadata();
    const todayDayKey = currentDayKeyVienna();
    const sendMetaCutoffDayKey = dayKeyDaysAgoVienna(SEND_META_RETENTION_DAYS);

    const staleSendMetadataKeys = Object.entries(previousSendMetadata)
      .filter(([, metadata]) => metadata.dayKey < sendMetaCutoffDayKey)
      .map(([key]) => key);

    if (staleSendMetadataKeys.length > 0) {
      await redis.removeSendMetadata(staleSendMetadataKeys);
      staleSendMetadataKeys.forEach((key) => {
        delete previousSendMetadata[key];
      });
    }

    const previousAggregateKeys = new Set(Object.keys(previousSignatures));
    const currentAggregateKeys = new Set(Object.keys(currentSignatures));

    const changedAggregateKeys = aggregates
      .map((aggregate) => aggregateStateKey(aggregate))
      .filter((key) => previousSignatures[key] !== currentSignatures[key]);

    const removedAggregateKeys = Array.from(previousAggregateKeys).filter((key) => !currentAggregateKeys.has(key));

    const changedAggregateKeySet = new Set(changedAggregateKeys);
    const changedAggregates = aggregates.filter((aggregate) => changedAggregateKeySet.has(aggregateStateKey(aggregate)));

    const sendCandidates: SendCandidate[] = [];
    const skippedRateLimitedKeys = new Set<string>();

    for (const aggregate of changedAggregates) {
      const key = aggregateStateKey(aggregate);
      const previousMetadata = previousSendMetadata[key];
      const currentTimeWindow = aggregateTimeWindow(aggregate);
      const currentStart = currentTimeWindow.start;
      const currentEnd = currentTimeWindow.end;
      const sentToday = previousMetadata?.dayKey === todayDayKey;
      const beginChanged = (previousMetadata?.start ?? "") !== currentStart;
      const endChanged = (previousMetadata?.end ?? "") !== currentEnd;

      if (!sentToday || beginChanged || endChanged) {
        sendCandidates.push({
          aggregate,
          previousTimeWindow: previousMetadata
            ? {
                start: previousMetadata.start,
                end: previousMetadata.end,
              }
            : null,
          timeWindowChanged: beginChanged || endChanged,
        });
        continue;
      }

      skippedRateLimitedKeys.add(key);
    }

    const messaging = getFirebaseMessagingClient();

    const sendResults = await Promise.allSettled(
      sendCandidates.map(async (candidate) => {
        await sendMunicipalityWarning(
          messaging,
          candidate.aggregate,
          candidate.previousTimeWindow,
          candidate.timeWindowChanged
        );
        return candidate.aggregate.municipalityId;
      })
    );

    const signaturesToPersist: Record<string, string> = {};
    const sendMetadataToPersist: Record<string, AggregateSendMetadata> = {};
    const failedMunicipalities: string[] = [];

    sendResults.forEach((result, index) => {
      const candidate = sendCandidates[index];
      const aggregate = candidate?.aggregate;
      const key = aggregate ? aggregateStateKey(aggregate) : null;

      if (!aggregate || !key) {
        return;
      }

      if (result.status === "fulfilled") {
        signaturesToPersist[key] = currentSignatures[key];
        const timeWindow = aggregateTimeWindow(aggregate);
        sendMetadataToPersist[key] = {
          dayKey: todayDayKey,
          start: timeWindow.start,
          end: timeWindow.end,
        };
        return;
      }

      failedMunicipalities.push(`${aggregate.kind}:${aggregate.municipalityId}`);
      console.error(`[${requestId}] fcm_send_failed`, {
        municipalityId: aggregate.municipalityId,
        warningKind: aggregate.kind,
        error:
          result.reason instanceof Error
            ? result.reason.message
            : String(result.reason),
      });
    });

    for (const key of skippedRateLimitedKeys) {
      signaturesToPersist[key] = currentSignatures[key];
    }

    if (Object.keys(signaturesToPersist).length > 0) {
      await redis.setSignatures(signaturesToPersist);
    }

    if (Object.keys(sendMetadataToPersist).length > 0) {
      await redis.setSendMetadata(sendMetadataToPersist);
    }

    const cleared = await redis.removeSignatures(removedAggregateKeys);
    await redis.removeSendMetadata(removedAggregateKeys);

    const response: HandlerSuccessResponse = {
      requestId,
      processedWarnings: normalizedWarnings.length,
      affectedMunicipalities: aggregates.length,
      sent: Object.keys(sendMetadataToPersist).length,
      skippedUnchanged: aggregates.length - changedAggregateKeys.length,
      skippedRateLimited: skippedRateLimitedKeys.size,
      cleared,
      failed: failedMunicipalities.length,
      failedMunicipalities,
      durationMs: Date.now() - startedAt,
    };

    return {
      status: 200,
      body: response as unknown as Record<string, unknown>,
    };
  } catch (error) {
    const appError = mapError(error);

    console.error(`[${requestId}] cron_failed`, {
      code: appError.code,
      status: appError.status,
      message: appError.message,
    });

    return {
      status: appError.status,
      body: {
        requestId,
        errorCode: appError.code,
        message: appError.message,
        durationMs: Date.now() - startedAt,
      },
    };
  }
}
