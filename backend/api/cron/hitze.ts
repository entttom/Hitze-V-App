import { createHash, randomUUID } from "node:crypto";
import { cert, getApps, initializeApp } from "firebase-admin/app";
import { getMessaging, type Messaging } from "firebase-admin/messaging";
import { createClient, type RedisClientType } from "redis";

const GEOSPHERE_WARNSTATUS_URL = "https://warnungen.zamg.at/wsapp/api/getWarnstatus";
const REDIS_SIGNATURE_KEY = "hitze:v1:signatures";
const HITZE_TYPE_ID = 6;
const DEFAULT_MIN_WARNING_LEVEL = 2;
const GEO_FETCH_TIMEOUT_MS = 10_000;
const GEO_FETCH_RETRIES = 2;

let messagingClient: Messaging | null = null;
let redisClient: RedisClientType | null = null;

interface NormalizedWarning {
  id: string;
  level: number;
  municipalities: string[];
  start: string;
  end: string;
}

interface MunicipalityAggregate {
  municipalityId: string;
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
  cleared: number;
  failed: number;
  durationMs: number;
  failedMunicipalities: string[];
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

function isHeatWarning(properties: Record<string, unknown>): boolean {
  const directType =
    properties.wtype ??
    properties.warn_type ??
    properties.warning_type ??
    properties.warntypid;

  const numericType = asNumber(directType);
  if (numericType === HITZE_TYPE_ID) {
    return true;
  }

  const textualType = asString(directType)?.toLowerCase();
  if (textualType && (textualType.includes("hitze") || textualType.includes("heat"))) {
    return true;
  }

  const rawInfo = isRecord(properties.rawinfo)
    ? properties.rawinfo
    : isRecord(properties.rawfinfo)
      ? properties.rawfinfo
      : null;

  const nestedNumericType = rawInfo ? asNumber(rawInfo.wtype) : null;
  return nestedNumericType === HITZE_TYPE_ID;
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

    const normalized = parsed.replace(/\s+/g, "");
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

  if (!isHeatWarning(properties)) {
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

  const start = asString(properties.start) ?? "";
  const end = asString(properties.end) ?? "";

  return {
    id: getWarningId(properties, `fallback-${index}`),
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
      const existing = aggregates.get(municipalityId);

      if (!existing) {
        const aggregate: MunicipalityAggregate = {
          municipalityId,
          maxLevel: warning.level,
          warningIds: new Set([warning.id]),
          starts: warning.start ? new Set([warning.start]) : new Set(),
          ends: warning.end ? new Set([warning.end]) : new Set(),
        };
        aggregates.set(municipalityId, aggregate);
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
    maxLevel: aggregate.maxLevel,
    warningIds,
    starts,
    ends,
  });

  return createHash("sha256").update(payload).digest("hex");
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

async function fetchGeoSphereWarnings(
  requestId: string,
  minWarningLevel: number
): Promise<NormalizedWarning[]> {
  const payload = await fetchJsonWithRetry(GEOSPHERE_WARNSTATUS_URL, requestId);

  if (!isRecord(payload) || !Array.isArray(payload.features)) {
    throw new AppError(502, "GEOSPHERE_SCHEMA_INVALID", "GeoSphere payload is missing a valid features array.");
  }

  const result: NormalizedWarning[] = [];

  payload.features.forEach((feature, index) => {
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

export interface TestPushInput {
  municipalityId: string;
  title?: string;
  body?: string;
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
      title: input.title?.trim() || "🧪 Test: Hitze-Warnung",
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

async function sendMunicipalityWarning(
  messaging: Messaging,
  aggregate: MunicipalityAggregate
): Promise<void> {
  const topic = topicForMunicipality(aggregate.municipalityId);
  const warningIds = Array.from(aggregate.warningIds).sort();

  await messaging.send({
    topic,
    notification: {
      title: "⚠️ Hitze-Warnung",
      body: `Warnstufe ${aggregate.maxLevel} erreicht. Hitzeschutzmaßnahmen nach Hitze-V umsetzen!`,
    },
    data: {
      gemeindenr: aggregate.municipalityId,
      warningLevel: String(aggregate.maxLevel),
      warningIds: warningIds.join(","),
      source: "geosphere",
    },
    apns: {
      headers: {
        "apns-collapse-id": `hitze-${aggregate.municipalityId}`,
      },
      payload: {
        aps: {
          sound: "default",
          "thread-id": `hitze-${aggregate.municipalityId}`,
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
      a.municipalityId.localeCompare(b.municipalityId)
    );

    const currentSignatures: Record<string, string> = {};
    for (const aggregate of aggregates) {
      currentSignatures[aggregate.municipalityId] = buildMunicipalitySignature(aggregate);
    }

    // Fail-closed: without Redis state comparison no push is sent.
    const redis = await getRedisClient();
    const previousSignatures = await redis.getSignatures();

    const previousMunicipalityIds = new Set(Object.keys(previousSignatures));
    const currentMunicipalityIds = new Set(Object.keys(currentSignatures));

    const changedMunicipalityIds = aggregates
      .filter((aggregate) => previousSignatures[aggregate.municipalityId] !== currentSignatures[aggregate.municipalityId])
      .map((aggregate) => aggregate.municipalityId);

    const removedMunicipalityIds = Array.from(previousMunicipalityIds).filter(
      (municipalityId) => !currentMunicipalityIds.has(municipalityId)
    );

    const changedAggregates = aggregates.filter((aggregate) =>
      changedMunicipalityIds.includes(aggregate.municipalityId)
    );

    const messaging = getFirebaseMessagingClient();

    const sendResults = await Promise.allSettled(
      changedAggregates.map(async (aggregate) => {
        await sendMunicipalityWarning(messaging, aggregate);
        return aggregate.municipalityId;
      })
    );

    const successfulSignatures: Record<string, string> = {};
    const failedMunicipalities: string[] = [];

    sendResults.forEach((result, index) => {
      const municipalityId = changedAggregates[index]?.municipalityId;

      if (!municipalityId) {
        return;
      }

      if (result.status === "fulfilled") {
        successfulSignatures[municipalityId] = currentSignatures[municipalityId];
        return;
      }

      failedMunicipalities.push(municipalityId);
      console.error(`[${requestId}] fcm_send_failed`, {
        municipalityId,
        error:
          result.reason instanceof Error
            ? result.reason.message
            : String(result.reason),
      });
    });

    if (Object.keys(successfulSignatures).length > 0) {
      await redis.setSignatures(successfulSignatures);
    }

    const cleared = await redis.removeSignatures(removedMunicipalityIds);

    const response: HandlerSuccessResponse = {
      requestId,
      processedWarnings: normalizedWarnings.length,
      affectedMunicipalities: aggregates.length,
      sent: Object.keys(successfulSignatures).length,
      skippedUnchanged: aggregates.length - changedMunicipalityIds.length,
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
