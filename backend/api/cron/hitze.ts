import { createHash, randomUUID } from "node:crypto";
import type { Message, TopicMessage } from "firebase-admin/messaging";
import { decideAll, expiredStateKeys, toPushDay, type DayState, type GkzDecision } from "./decision";
import { loadCronConfig, type CronConfig, type LegacyLanguageTopicsMode } from "./env";
import { AppError, errorMessage, toAppError } from "./errors";
import { fetchGeoSphereFeed, groupByGkzDay, normalizeFeatures, type FeedResult } from "./feed";
import { firebaseErrorCode, getFirebaseMessaging, type MessagingLike } from "./firebase";
import {
  buildLegacyMessage,
  buildLegacyPayload,
  buildV2Message,
  buildV2Payload,
  latestDayEndMs,
  legacyTopic,
  toTokenMessage,
  v2Topic,
  type PushContent,
} from "./messages";
import { listMunicipalities, municipalityName, type MunicipalityOption } from "./municipalities";
import { pushoverReporter, type CronReporter } from "./pushover";
import {
  DEFAULT_PUSH_LANGUAGE,
  SUPPORTED_PUSH_LANGUAGES,
  listSupportedPushLanguages,
  normalizeSupportedPushLanguage,
  parseSupportedPushLanguage,
  type SupportedPushLanguage,
} from "./pushLocalization";
import { sharedRedis } from "./redis";
import { renderPush, type PushDay } from "./renderer";
import { RedisCronStateStore, legacySentKey, type CronStateStore, type LastPush, type LegacySent, type StateUpdate } from "./state";
import { viennaDateKey, viennaHour } from "./time";

export {
  DEFAULT_PUSH_LANGUAGE,
  listSupportedPushLanguages,
  normalizeSupportedPushLanguage,
  parseSupportedPushLanguage,
  type SupportedPushLanguage,
};

export const PUSH_QUIET_HOURS_START = 20;
export const PUSH_QUIET_HOURS_END = 6;
export const MAX_TEST_BULK_IDS = 50;
const MAX_FAILED_TARGETS_IN_RESPONSE = 50;

export function isQuietHours(nowMs: number): boolean {
  const hour = viennaHour(nowMs);
  return hour >= PUSH_QUIET_HOURS_START || hour < PUSH_QUIET_HOURS_END;
}

export function legacyLanguagesFor(mode: LegacyLanguageTopicsMode): string[] {
  if (mode === "off") {
    return [];
  }
  if (mode === "de") {
    return ["de"];
  }
  // German first so the largest audience is served first.
  return ["de", ...SUPPORTED_PUSH_LANGUAGES.filter((language) => language !== "de")];
}

export interface CronDeps {
  now: () => number;
  store: CronStateStore;
  messaging: () => MessagingLike;
  fetchFeed: (requestId: string) => Promise<FeedResult>;
  config: CronConfig;
  reporter: CronReporter;
  signal?: AbortSignal;
}

export interface HitzeCronHttpResponse {
  status: number;
  headers?: Record<string, string>;
  body: Record<string, unknown>;
}

export interface CronRunSummary {
  requestId: string;
  processedWarnings: number;
  affectedMunicipalities: number;
  events: { new: number; escalated: number; updated: number };
  v2Sent: number;
  v2Failed: number;
  legacySent: number;
  legacyFailed: number;
  legacySkippedAlreadyDelivered: number;
  legacyRetries: number;
  silentUpdates: number;
  deferredQuietHours: number;
  deferredRateLimited: number;
  deferredAborted: number;
  stateWriteFailures: number;
  clearedStates: number;
  pushQuietHoursActive: boolean;
  pushQuietHoursWindow: string;
  legacyLanguageTopics: LegacyLanguageTopicsMode;
  fcmSendConcurrency: number;
  cronLockTtlSeconds: number;
  failedTargets: string[];
  durationMs: number;
}

function quietHoursLabel(): string {
  const pad = (hour: number): string => String(hour).padStart(2, "0");
  return `${pad(PUSH_QUIET_HOURS_START)}:00-${pad(PUSH_QUIET_HOURS_END)}:00 Europe/Vienna`;
}

function fingerprintOf(content: Pick<PushContent, "event" | "days" | "warningIds">): string {
  return createHash("sha256")
    .update(JSON.stringify({ event: content.event, days: content.days, warningIds: content.warningIds }))
    .digest("hex")
    .slice(0, 16);
}

class SendAborted extends Error {
  constructor() {
    super("send aborted");
  }
}

function createLimiter(concurrency: number): <T>(task: () => Promise<T>) => Promise<T> {
  let active = 0;
  const queue: Array<() => void> = [];
  const next = (): void => {
    active -= 1;
    queue.shift()?.();
  };
  return async <T>(task: () => Promise<T>): Promise<T> => {
    if (active >= concurrency) {
      await new Promise<void>((resolve) => queue.push(resolve));
    }
    active += 1;
    try {
      return await task();
    } finally {
      next();
    }
  };
}

async function runPool<T>(items: T[], concurrency: number, worker: (item: T) => Promise<void>): Promise<void> {
  let index = 0;
  const runners = Array.from({ length: Math.min(Math.max(1, concurrency), items.length) }, async () => {
    while (index < items.length) {
      const item = items[index];
      index += 1;
      await worker(item);
    }
  });
  await Promise.all(runners);
}

interface EventJob {
  kind: "event";
  decision: GkzDecision;
}

interface RetryJob {
  kind: "legacy-retry";
  gkz: string;
  lastPush: LastPush;
  languages: string[];
}

export async function runHitzeCron(deps: CronDeps): Promise<HitzeCronHttpResponse> {
  const startedAt = Date.now();
  const requestId = randomUUID();
  const { store, config } = deps;
  const lockToken = randomUUID();
  let lockAcquired = false;
  let lockTimer: NodeJS.Timeout | null = null;
  let lockLost = false;

  try {
    lockAcquired = await store.acquireLock(lockToken, config.cronLockTtlSeconds);
    if (!lockAcquired) {
      return {
        status: 200,
        body: {
          requestId,
          skipped: true,
          skipReason: "CRON_ALREADY_RUNNING",
          message: "Another heat warning cron run is still active.",
          durationMs: Date.now() - startedAt,
        },
      };
    }

    lockTimer = setInterval(() => {
      store.refreshLock(lockToken, config.cronLockTtlSeconds).then(
        (stillOwned) => {
          if (!stillOwned) {
            lockLost = true;
            console.error(`[${requestId}] cron_lock_lost`);
          }
        },
        (error: unknown) => {
          console.warn(`[${requestId}] cron_lock_refresh_failed`, { error: errorMessage(error) });
        }
      );
    }, Math.max(1_000, Math.floor((config.cronLockTtlSeconds * 1000) / 3)));
    lockTimer.unref();

    const nowMs = deps.now();
    const today = viennaDateKey(nowMs);
    const feed = await deps.fetchFeed(requestId);
    const warnings = normalizeFeatures(feed.features, config.minLevel, nowMs);
    const byGkz = groupByGkzDay(warnings, nowMs);
    const legacyLanguages = legacyLanguagesFor(config.legacyLanguageTopics);

    const dayStates = await store.loadDayStates();
    const lastPushes = await store.loadLastPushes();
    const legacySent = legacyLanguages.length > 0 ? await store.loadLegacySent() : new Map<string, LegacySent>();

    const expiredDayStates = expiredStateKeys(dayStates.keys(), nowMs);
    const expiredLastPushes = Array.from(lastPushes).filter(([, push]) => push.expiresAt <= nowMs).map(([gkz]) => gkz);
    const expiredLegacy = Array.from(legacySent).filter(([, entry]) => entry.expiresAt <= nowMs).map(([key]) => key);
    if (expiredDayStates.length + expiredLastPushes.length + expiredLegacy.length > 0) {
      await store.deleteEntries({ dayStates: expiredDayStates, lastPushes: expiredLastPushes, legacySent: expiredLegacy });
      expiredDayStates.forEach((key) => dayStates.delete(key));
      expiredLastPushes.forEach((gkz) => lastPushes.delete(gkz));
      expiredLegacy.forEach((key) => legacySent.delete(key));
    }

    const decisions = decideAll(byGkz, dayStates, nowMs);
    const quiet = isQuietHours(nowMs);

    const summary: CronRunSummary = {
      requestId,
      processedWarnings: warnings.length,
      affectedMunicipalities: decisions.filter((decision) => decision.classified.length > 0).length,
      events: { new: 0, escalated: 0, updated: 0 },
      v2Sent: 0,
      v2Failed: 0,
      legacySent: 0,
      legacyFailed: 0,
      legacySkippedAlreadyDelivered: 0,
      legacyRetries: 0,
      silentUpdates: 0,
      deferredQuietHours: 0,
      deferredRateLimited: 0,
      deferredAborted: 0,
      stateWriteFailures: 0,
      clearedStates: expiredDayStates.length,
      pushQuietHoursActive: quiet,
      pushQuietHoursWindow: quietHoursLabel(),
      legacyLanguageTopics: config.legacyLanguageTopics,
      fcmSendConcurrency: config.fcmSendConcurrency,
      cronLockTtlSeconds: config.cronLockTtlSeconds,
      failedTargets: [],
      durationMs: 0,
    };

    let abortReason: string | null = null;
    const aborted = (): boolean => {
      if (!abortReason && deps.signal?.aborted) {
        abortReason = "shutdown";
      }
      if (!abortReason && lockLost) {
        abortReason = "lock_lost";
      }
      return abortReason !== null;
    };

    const persist = async (gkz: string, update: StateUpdate): Promise<void> => {
      try {
        await store.persist(update);
      } catch (error) {
        summary.stateWriteFailures += 1;
        // Stop sending: every further push could not be recorded and would repeat next run.
        abortReason = abortReason ?? "state_write_failed";
        console.error(`[${requestId}] state_write_failed`, { gkz, error: errorMessage(error) });
      }
    };

    const jobs: Array<EventJob | RetryJob> = [];
    const silentOnly: Record<string, DayState> = {};
    const eventGkz = new Set<string>();

    for (const decision of decisions) {
      summary.deferredRateLimited += decision.classified.filter((entry) => entry.cls === "updated-limited").length;
      summary.silentUpdates += Object.keys(decision.silentStates).length;

      if (!decision.event) {
        Object.assign(silentOnly, decision.silentStates);
        continue;
      }
      eventGkz.add(decision.gkz);
      if (quiet) {
        summary.deferredQuietHours += 1;
        Object.assign(silentOnly, decision.silentStates);
        continue;
      }
      jobs.push({ kind: "event", decision });
    }

    if (Object.keys(silentOnly).length > 0) {
      await persist("silent", { dayStates: silentOnly });
    }

    if (!quiet && legacyLanguages.length > 0) {
      for (const [gkz, lastPush] of lastPushes) {
        if (eventGkz.has(gkz)) {
          continue;
        }
        const pending = lastPush.legacyLanguages.filter(
          (language) =>
            legacyLanguages.includes(language) &&
            legacySent.get(legacySentKey(gkz, language))?.fingerprint !== lastPush.fingerprint
        );
        if (pending.length > 0 && lastPush.days.some((day) => day.date >= today)) {
          jobs.push({ kind: "legacy-retry", gkz, lastPush, languages: pending });
        }
      }
    }

    const limit = createLimiter(config.fcmSendConcurrency);
    const send = (message: Message): Promise<string> =>
      limit(async () => {
        if (aborted()) {
          throw new SendAborted();
        }
        return deps.messaging().send(message);
      });

    const recordFailure = (target: string, error: unknown): void => {
      if (summary.failedTargets.length < MAX_FAILED_TARGETS_IN_RESPONSE) {
        summary.failedTargets.push(target);
      }
      console.error(`[${requestId}] fcm_send_failed`, { target, code: firebaseErrorCode(error) });
    };

    const sendLegacy = async (
      content: PushContent,
      fingerprint: string,
      languages: string[],
      expiresAt: number
    ): Promise<Record<string, LegacySent>> => {
      const delivered: Record<string, LegacySent> = {};
      await Promise.all(
        languages.map(async (language) => {
          const key = legacySentKey(content.gkz, language);
          if (legacySent.get(key)?.fingerprint === fingerprint) {
            summary.legacySkippedAlreadyDelivered += 1;
            return;
          }
          try {
            await send(buildLegacyMessage(content, language));
            summary.legacySent += 1;
            delivered[key] = { fingerprint, expiresAt };
          } catch (error) {
            if (error instanceof SendAborted) {
              return;
            }
            summary.legacyFailed += 1;
            recordFailure(legacyTopic(content.gkz, language), error);
          }
        })
      );
      return delivered;
    };

    await runPool(jobs, config.fcmSendConcurrency, async (job) => {
      if (aborted()) {
        if (job.kind === "event") {
          summary.deferredAborted += 1;
        }
        return;
      }

      if (job.kind === "legacy-retry") {
        const days = job.lastPush.days.filter((day) => day.date >= today);
        const content: PushContent = {
          event: job.lastPush.event,
          gkz: job.gkz,
          name: job.lastPush.name,
          days,
          warningIds: job.lastPush.warningIds,
          nowMs,
        };
        summary.legacyRetries += job.languages.length;
        const delivered = await sendLegacy(content, job.lastPush.fingerprint, job.languages, job.lastPush.expiresAt);
        if (Object.keys(delivered).length > 0) {
          await persist(job.gkz, { legacySent: delivered });
        }
        return;
      }

      const { decision } = job;
      const event = decision.event;
      if (!event) {
        return;
      }
      const days: PushDay[] = decision.days.map(toPushDay);
      const warningIds = Array.from(new Set(decision.days.flatMap((day) => day.warningIds))).sort();
      const content: PushContent = {
        event,
        gkz: decision.gkz,
        name: municipalityName(decision.gkz),
        days,
        warningIds,
        nowMs,
      };
      const fingerprint = fingerprintOf(content);
      const expiresAt = latestDayEndMs(days) ?? nowMs;

      const v2Result = send(buildV2Message(content)).then(
        () => "sent" as const,
        (error: unknown) => {
          if (error instanceof SendAborted) {
            return "aborted" as const;
          }
          recordFailure(v2Topic(decision.gkz), error);
          return "failed" as const;
        }
      );
      const [v2, delivered] = await Promise.all([
        v2Result,
        sendLegacy(content, fingerprint, legacyLanguages, expiresAt),
      ]);

      const update: StateUpdate = { dayStates: { ...decision.silentStates }, legacySent: delivered };
      if (v2 === "sent") {
        summary.v2Sent += 1;
        summary.events[event] += 1;
        Object.assign(update.dayStates ?? {}, decision.pushedStates);
        update.lastPush = {
          gkz: decision.gkz,
          value: {
            fingerprint,
            event,
            name: content.name,
            days,
            warningIds,
            sentAt: new Date(nowMs).toISOString(),
            expiresAt,
            legacyLanguages,
          },
        };
      } else if (v2 === "failed") {
        summary.v2Failed += 1;
      } else {
        summary.deferredAborted += 1;
      }
      await persist(decision.gkz, update);
    });

    if (abortReason) {
      console.warn(`[${requestId}] cron_sends_aborted`, { reason: abortReason, deferred: summary.deferredAborted });
    }

    summary.durationMs = Date.now() - startedAt;
    console.log(`[${requestId}] cron_completed`, {
      warnings: summary.processedWarnings,
      municipalities: summary.affectedMunicipalities,
      events: summary.events,
      v2Sent: summary.v2Sent,
      v2Failed: summary.v2Failed,
      legacySent: summary.legacySent,
      legacyFailed: summary.legacyFailed,
      deferredQuietHours: summary.deferredQuietHours,
      deferredAborted: summary.deferredAborted,
      stateWriteFailures: summary.stateWriteFailures,
      durationMs: summary.durationMs,
    });

    const attempted = summary.v2Sent + summary.v2Failed + summary.legacySent + summary.legacyFailed;
    if (attempted > 0) {
      await deps.reporter.runReport({
        requestId,
        processedWarnings: summary.processedWarnings,
        affectedMunicipalities: summary.affectedMunicipalities,
        v2Sent: summary.v2Sent,
        v2Failed: summary.v2Failed,
        legacySent: summary.legacySent,
        legacyFailed: summary.legacyFailed,
        deferredQuietHours: summary.deferredQuietHours,
        deferredRateLimited: summary.deferredRateLimited,
        failedTargets: summary.failedTargets,
        stateWriteFailures: summary.stateWriteFailures,
        durationMs: summary.durationMs,
      });
    }
    if (summary.stateWriteFailures > 0) {
      await deps.reporter.failureReport({
        requestId,
        errorCode: "STATE_WRITE_FAILED",
        message: `${summary.stateWriteFailures} Redis-Schreibvorgänge fehlgeschlagen; ${summary.deferredAborted} Gemeinden zurückgestellt.`,
      });
    }

    return { status: 200, body: { ...summary } };
  } catch (error) {
    const appError = toAppError(error);
    console.error(`[${requestId}] cron_failed`, { code: appError.code, status: appError.status, message: appError.message });
    await deps.reporter.failureReport({ requestId, errorCode: appError.code, message: appError.message });
    return {
      status: appError.status,
      body: { requestId, errorCode: appError.code, message: appError.message, durationMs: Date.now() - startedAt },
    };
  } finally {
    if (lockTimer) {
      clearInterval(lockTimer);
    }
    if (lockAcquired) {
      try {
        await store.releaseLock(lockToken);
      } catch (error) {
        console.error(`[${requestId}] cron_lock_release_failed`, { error: errorMessage(error) });
      }
    }
  }
}

export function defaultCronDeps(signal?: AbortSignal): CronDeps {
  return {
    now: () => Date.now(),
    store: new RedisCronStateStore(sharedRedis),
    messaging: getFirebaseMessaging,
    fetchFeed: fetchGeoSphereFeed,
    config: loadCronConfig(),
    reporter: pushoverReporter,
    signal,
  };
}

export function executeHitzeCron(signal?: AbortSignal): Promise<HitzeCronHttpResponse> {
  return runHitzeCron(defaultCronDeps(signal));
}

// ---------- develop-only helpers (test UI) ----------

export type TestPushFormat = "v2" | "legacy";

export interface TestPushOptions {
  format: TestPushFormat;
  /** Legacy topic language / rendering language; ignored for v2 topics. */
  language?: SupportedPushLanguage;
  title?: string;
  body?: string;
}

function testContent(gkz: string, nowMs: number): PushContent {
  return { event: "test", gkz, name: municipalityName(gkz), days: [], warningIds: [], nowMs };
}

function testPayload(gkz: string, options: TestPushOptions, nowMs: number): Omit<TopicMessage, "topic"> {
  const content = testContent(gkz, nowMs);
  if (options.format === "v2") {
    const rendered = renderPush({ event: "test", name: content.name, days: [], nowMs, language: "de" });
    return buildV2Payload(content, {
      title: options.title?.trim() || rendered.title,
      body: options.body?.trim() || rendered.body,
    });
  }
  return buildLegacyPayload(content, options.language ?? "de", { title: options.title, body: options.body });
}

export interface TestPushResult {
  municipalityId: string;
  topic: string;
  format: TestPushFormat;
  language: string | null;
  messageId: string;
}

export async function sendTestPush(
  municipalityId: string,
  options: TestPushOptions,
  messaging: MessagingLike = getFirebaseMessaging(),
  nowMs: number = Date.now()
): Promise<TestPushResult> {
  const gkz = municipalityId.replace(/\s+/g, "");
  if (!gkz) {
    throw new AppError(400, "INVALID_INPUT", "municipalityId is required.");
  }
  const language = options.format === "legacy" ? options.language ?? "de" : null;
  const topic = options.format === "v2" ? v2Topic(gkz) : legacyTopic(gkz, language ?? "de");
  const messageId = await messaging.send({ topic, ...testPayload(gkz, options, nowMs) });
  return { municipalityId: gkz, topic, format: options.format, language, messageId };
}

export async function sendTestPushBulk(
  municipalityIds: string[],
  options: TestPushOptions,
  concurrency: number
): Promise<{ sent: TestPushResult[]; failed: Array<{ municipalityId: string; error: string; code: string }> }> {
  const ids = Array.from(new Set(municipalityIds.map((id) => id.replace(/\s+/g, "")).filter(Boolean)));
  if (ids.length === 0) {
    throw new AppError(400, "INVALID_INPUT", "At least one municipalityId is required.");
  }
  if (ids.length > MAX_TEST_BULK_IDS) {
    throw new AppError(400, "INVALID_INPUT", `At most ${MAX_TEST_BULK_IDS} municipalities per test send.`);
  }

  const messaging = getFirebaseMessaging();
  const sent: TestPushResult[] = [];
  const failed: Array<{ municipalityId: string; error: string; code: string }> = [];
  await runPool(ids, concurrency, async (id) => {
    try {
      sent.push(await sendTestPush(id, options, messaging));
    } catch (error) {
      failed.push({ municipalityId: id, error: errorMessage(error), code: firebaseErrorCode(error) });
    }
  });
  sent.sort((a, b) => a.municipalityId.localeCompare(b.municipalityId));
  return { sent, failed };
}

export async function sendTestPushToToken(
  token: string,
  municipalityId: string,
  options: TestPushOptions
): Promise<{ messageId: string; tokenSuffix: string }> {
  const trimmed = token.trim();
  if (!trimmed) {
    throw new AppError(400, "INVALID_INPUT", "token is required.");
  }
  const gkz = municipalityId.replace(/\s+/g, "") || "90101";
  const messageId = await getFirebaseMessaging().send(toTokenMessage(trimmed, testPayload(gkz, options, Date.now())));
  return { messageId, tokenSuffix: trimmed.slice(-6) };
}

export function listTestMunicipalityOptions(): MunicipalityOption[] {
  return listMunicipalities();
}

// ---------- develop-only warnings snapshot ----------

export interface CurrentWarningsSnapshotMunicipality {
  municipalityId: string;
  name: string;
  maxLevel: number;
  start: string | null;
  end: string | null;
  contributingWarningIds: string[];
  days: PushDay[];
}

export interface CurrentWarningsSnapshotMapFeature {
  id: string;
  kind: "heat";
  level: number;
  start: string | null;
  end: string | null;
  municipalityCount: number;
  municipalityIds: string[];
  geometry: unknown;
}

export interface CurrentWarningsSnapshot {
  requestId: string;
  fetchedAt: string;
  durationMs: number;
  source: "live" | "static";
  sourceUrl: string;
  minWarningLevel: number;
  rawFeatureCount: number;
  acceptedWarningCount: number;
  affectedMunicipalities: CurrentWarningsSnapshotMunicipality[];
  mapFeatures: CurrentWarningsSnapshotMapFeature[];
}

export async function loadCurrentWarningsSnapshot(): Promise<CurrentWarningsSnapshot> {
  const requestId = randomUUID();
  const startedAt = Date.now();
  const config = loadCronConfig();
  const feed = await fetchGeoSphereFeed(requestId);
  const warnings = normalizeFeatures(feed.features, config.minLevel, startedAt);
  const byGkz = groupByGkzDay(warnings, startedAt);

  const affectedMunicipalities = Array.from(byGkz, ([gkz, days]) => {
    const starts = days.map((day) => day.start);
    const ends = days.map((day) => day.end).filter(Boolean).sort();
    return {
      municipalityId: gkz,
      name: municipalityName(gkz),
      maxLevel: Math.max(...days.map((day) => day.level)),
      start: starts.some((value) => !value) ? null : starts.sort()[0] ?? null,
      end: ends.at(-1) ?? null,
      contributingWarningIds: Array.from(new Set(days.flatMap((day) => day.warningIds))).sort(),
      days: days.map(toPushDay),
    };
  }).sort((a, b) => b.maxLevel - a.maxLevel || a.municipalityId.localeCompare(b.municipalityId));

  return {
    requestId,
    fetchedAt: new Date().toISOString(),
    durationMs: Date.now() - startedAt,
    source: feed.source,
    sourceUrl: feed.sourceLocation,
    minWarningLevel: config.minLevel,
    rawFeatureCount: feed.features.length,
    acceptedWarningCount: warnings.length,
    affectedMunicipalities,
    mapFeatures: warnings.map((warning) => ({
      id: warning.id,
      kind: "heat",
      level: warning.level,
      start: warning.start || null,
      end: warning.end || null,
      municipalityCount: warning.municipalities.length,
      municipalityIds: warning.municipalities,
      geometry: warning.geometry,
    })),
  };
}
