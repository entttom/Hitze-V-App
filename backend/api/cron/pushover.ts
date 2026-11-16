import { envString } from "./env";
import { errorMessage } from "./errors";
import { isRedisConfigured, sharedRedis } from "./redis";

const PUSHOVER_API_URL = "https://api.pushover.net/1/messages.json";
const PUSHOVER_TIMEOUT_MS = 5_000;
const PUSHOVER_MAX_FAILED_TARGETS_IN_MESSAGE = 5;
const PUSHOVER_REPORTS_ENABLED_KEY = "hitze:v1:pushover_reports_enabled";
const FAILURE_REPORT_INTERVAL_MS = 60 * 60 * 1000;

let memoryReportsEnabled: boolean | null = null;
const lastFailureReportAt = new Map<string, number>();

export interface PushoverRunReport {
  requestId: string;
  processedWarnings: number;
  affectedMunicipalities: number;
  v2Sent: number;
  v2Failed: number;
  legacySent: number;
  legacyFailed: number;
  deferredQuietHours: number;
  deferredRateLimited: number;
  failedTargets: string[];
  stateWriteFailures: number;
  durationMs: number;
}

export interface PushoverFailureReport {
  requestId: string;
  errorCode: string;
  message: string;
}

/** Reporting hooks used by the cron run; never throw. */
export interface CronReporter {
  runReport(report: PushoverRunReport): Promise<void>;
  failureReport(report: PushoverFailureReport): Promise<void>;
}

interface PushoverConfig {
  appToken: string;
  userKey: string;
  device: string | undefined;
}

export interface PushoverReportStatus {
  configured: boolean;
  enabled: boolean;
  defaultEnabled: boolean;
  storedEnabled: boolean | null;
  persistence: "redis" | "memory";
}

function pushoverConfig(): PushoverConfig | null {
  const appToken = envString("PUSHOVER_APP_TOKEN");
  const userKey = envString("PUSHOVER_USER_KEY");
  if (!appToken || !userKey) {
    return null;
  }
  return { appToken, userKey, device: envString("PUSHOVER_DEVICE") ?? undefined };
}

export function isPushoverConfigured(): boolean {
  return pushoverConfig() !== null;
}

function parseBooleanSetting(value: string | null | undefined): boolean | null {
  const normalized = value?.trim().toLowerCase();
  if (!normalized) {
    return null;
  }
  if (["1", "true", "yes", "on"].includes(normalized)) {
    return true;
  }
  if (["0", "false", "no", "off"].includes(normalized)) {
    return false;
  }
  return null;
}

function defaultReportsEnabled(): boolean {
  return parseBooleanSetting(process.env.PUSHOVER_REPORTS_ENABLED) ?? true;
}

async function readStoredReportsEnabled(): Promise<{ value: boolean | null; persistence: "redis" | "memory" }> {
  if (!isRedisConfigured()) {
    return { value: memoryReportsEnabled, persistence: "memory" };
  }
  return { value: parseBooleanSetting(await sharedRedis.get(PUSHOVER_REPORTS_ENABLED_KEY)), persistence: "redis" };
}

export async function getPushoverReportStatus(): Promise<PushoverReportStatus> {
  const configured = isPushoverConfigured();
  const defaultEnabled = defaultReportsEnabled();
  const stored = await readStoredReportsEnabled();
  return {
    configured,
    enabled: configured && (stored.value ?? defaultEnabled),
    defaultEnabled,
    storedEnabled: stored.value,
    persistence: stored.persistence,
  };
}

export async function setPushoverReportsEnabled(enabled: boolean): Promise<PushoverReportStatus> {
  if (isRedisConfigured()) {
    await sharedRedis.set(PUSHOVER_REPORTS_ENABLED_KEY, enabled ? "true" : "false");
  } else {
    memoryReportsEnabled = enabled;
  }
  return getPushoverReportStatus();
}

function formatDuration(ms: number): string {
  return ms < 1000 ? `${ms}ms` : `${(ms / 1000).toFixed(1)}s`;
}

export function buildRunMessage(input: PushoverRunReport): { title: string; message: string; priority: "0" | "1" } {
  const failed = input.v2Failed + input.legacyFailed + input.stateWriteFailures;
  const lines = [
    `Warnungen: ${input.processedWarnings}`,
    `Gemeinden: ${input.affectedMunicipalities}`,
    `v2-Pushes: ${input.v2Sent} gesendet, ${input.v2Failed} Fehler`,
    `Legacy-Pushes: ${input.legacySent} gesendet, ${input.legacyFailed} Fehler`,
  ];
  if (input.stateWriteFailures > 0) {
    lines.push(`Redis-Schreibfehler: ${input.stateWriteFailures}`);
  }
  if (input.failedTargets.length > 0) {
    lines.push("", "Fehler (Auszug):");
    const shown = input.failedTargets.slice(0, PUSHOVER_MAX_FAILED_TARGETS_IN_MESSAGE);
    lines.push(...shown.map((target) => `  ${target}`));
    if (input.failedTargets.length > shown.length) {
      lines.push(`  +${input.failedTargets.length - shown.length} mehr`);
    }
  }
  if (input.deferredQuietHours > 0 || input.deferredRateLimited > 0) {
    lines.push("", `Zurückgestellt: ${input.deferredQuietHours} Ruhezeit, ${input.deferredRateLimited} Update-Limit`);
  }
  lines.push(`Dauer: ${formatDuration(input.durationMs)}`);

  return {
    title: failed === 0 ? "HitzeV: Hitzewarnung versendet" : "HitzeV: Hitzewarnung mit Fehlern",
    message: lines.join("\n"),
    priority: failed === 0 ? "0" : "1",
  };
}

async function postToPushover(
  requestId: string,
  content: { title: string; message: string; priority: "0" | "1" }
): Promise<void> {
  const config = pushoverConfig();
  if (!config) {
    return;
  }

  let status: PushoverReportStatus;
  try {
    status = await getPushoverReportStatus();
  } catch (error) {
    // Redis may be the reason we report; fall back to the env default.
    console.warn(`[${requestId}] pushover_status_error`, { error: errorMessage(error) });
    status = {
      configured: true,
      enabled: defaultReportsEnabled(),
      defaultEnabled: defaultReportsEnabled(),
      storedEnabled: null,
      persistence: "memory",
    };
  }
  if (!status.enabled) {
    return;
  }

  const params = new URLSearchParams({
    token: config.appToken,
    user: config.userKey,
    title: content.title,
    message: content.message,
    priority: content.priority,
  });
  if (config.device) {
    params.set("device", config.device);
  }

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), PUSHOVER_TIMEOUT_MS);
  try {
    const response = await fetch(PUSHOVER_API_URL, {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: params,
      signal: controller.signal,
    });
    if (!response.ok) {
      console.warn(`[${requestId}] pushover_send_failed`, { status: response.status });
    }
  } finally {
    clearTimeout(timeout);
  }
}

export async function sendPushoverRunReport(report: PushoverRunReport): Promise<void> {
  try {
    await postToPushover(report.requestId, buildRunMessage(report));
  } catch (error) {
    console.warn(`[${report.requestId}] pushover_send_error`, { error: errorMessage(error) });
  }
}

/** At most one report per error code per hour (per process). */
export function shouldSendFailureReport(errorCode: string, nowMs: number): boolean {
  const last = lastFailureReportAt.get(errorCode);
  if (last !== undefined && nowMs - last < FAILURE_REPORT_INTERVAL_MS) {
    return false;
  }
  lastFailureReportAt.set(errorCode, nowMs);
  return true;
}

export async function sendPushoverFailureReport(report: PushoverFailureReport): Promise<void> {
  try {
    if (!isPushoverConfigured() || !shouldSendFailureReport(report.errorCode, Date.now())) {
      return;
    }
    await postToPushover(report.requestId, {
      title: `HitzeV: Cron-Fehler ${report.errorCode}`,
      message: `${report.message.slice(0, 500)}\n\nWeitere Fehler dieses Typs werden für 1 h nicht gemeldet.`,
      priority: "1",
    });
  } catch (error) {
    console.warn(`[${report.requestId}] pushover_failure_report_error`, { error: errorMessage(error) });
  }
}

export const pushoverReporter: CronReporter = {
  runReport: sendPushoverRunReport,
  failureReport: sendPushoverFailureReport,
};
