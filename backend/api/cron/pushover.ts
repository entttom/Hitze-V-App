import { createClient, type RedisClientType } from "redis";

const PUSHOVER_API_URL = "https://api.pushover.net/1/messages.json";
const PUSHOVER_TIMEOUT_MS = 5_000;
const PUSHOVER_MAX_FAILED_TARGETS_IN_MESSAGE = 5;
const PUSHOVER_REPORTS_ENABLED_KEY = "hitze:v1:pushover_reports_enabled";

let settingsRedisClient: RedisClientType | null = null;
let memoryPushoverReportsEnabled: boolean | null = null;

export interface PushoverReportInput {
  requestId: string;
  processedWarnings: number;
  affectedMunicipalities: number;
  sent: number;
  attempted: number;
  skippedRateLimited: number;
  skippedQuietHours: number;
  failed: number;
  failedMunicipalities: string[];
  failedTargets: string[];
  durationMs: number;
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

function getPushoverConfig(): PushoverConfig | null {
  const appToken = process.env.PUSHOVER_APP_TOKEN?.trim();
  const userKey = process.env.PUSHOVER_USER_KEY?.trim();

  if (!appToken || !userKey) {
    return null;
  }

  return {
    appToken,
    userKey,
    device: process.env.PUSHOVER_DEVICE?.trim() || undefined,
  };
}

export function isPushoverConfigured(): boolean {
  return getPushoverConfig() !== null;
}

function parseBooleanSetting(value: string | undefined): boolean | null {
  if (!value) {
    return null;
  }

  const normalized = value.trim().toLowerCase();
  if (["1", "true", "yes", "on"].includes(normalized)) {
    return true;
  }

  if (["0", "false", "no", "off"].includes(normalized)) {
    return false;
  }

  return null;
}

function defaultPushoverReportsEnabled(): boolean {
  return parseBooleanSetting(process.env.PUSHOVER_REPORTS_ENABLED) ?? true;
}

async function getSettingsRedisClient(): Promise<RedisClientType | null> {
  const redisUrl = process.env.REDIS_URL?.trim();
  if (!redisUrl) {
    return null;
  }

  if (!settingsRedisClient) {
    settingsRedisClient = createClient({ url: redisUrl });
    settingsRedisClient.on("error", (error: unknown) => {
      console.warn("pushover_settings_redis_error", {
        error: error instanceof Error ? error.message : String(error),
      });
    });
  }

  if (!settingsRedisClient.isOpen) {
    await settingsRedisClient.connect();
  }

  return settingsRedisClient;
}

async function readStoredPushoverReportsEnabled(): Promise<{
  value: boolean | null;
  persistence: "redis" | "memory";
}> {
  const client = await getSettingsRedisClient();
  if (!client) {
    return { value: memoryPushoverReportsEnabled, persistence: "memory" };
  }

  const stored = await client.get(PUSHOVER_REPORTS_ENABLED_KEY);
  return {
    value: parseBooleanSetting(stored ?? undefined),
    persistence: "redis",
  };
}

export async function getPushoverReportStatus(): Promise<PushoverReportStatus> {
  const configured = isPushoverConfigured();
  const defaultEnabled = defaultPushoverReportsEnabled();
  const stored = await readStoredPushoverReportsEnabled();
  const desiredEnabled = stored.value ?? defaultEnabled;

  return {
    configured,
    enabled: configured && desiredEnabled,
    defaultEnabled,
    storedEnabled: stored.value,
    persistence: stored.persistence,
  };
}

export async function setPushoverReportsEnabled(enabled: boolean): Promise<PushoverReportStatus> {
  const client = await getSettingsRedisClient();

  if (!client) {
    memoryPushoverReportsEnabled = enabled;
  } else {
    await client.set(PUSHOVER_REPORTS_ENABLED_KEY, enabled ? "true" : "false");
  }

  return getPushoverReportStatus();
}

function formatDuration(ms: number): string {
  if (ms < 1000) {
    return `${ms}ms`;
  }
  return `${(ms / 1000).toFixed(1)}s`;
}

function buildPushoverMessage(input: PushoverReportInput): {
  title: string;
  message: string;
  priority: "0" | "1";
} {
  const allOK = input.failed === 0;
  const title = allOK ? "Hitze-Warnung versendet" : "Hitze-Warnung: Fehler";

  const lines: string[] = [];
  lines.push(`Warnungen: ${input.processedWarnings}`);
  lines.push(`Gemeinden: ${input.affectedMunicipalities}`);

  if (allOK) {
    lines.push(`Pushes: ${input.sent} (alle Sprachen OK)`);
  } else {
    lines.push(
      `Pushes: ${input.sent} / ${input.attempted} — ${input.failed} Fehler in ${input.failedMunicipalities.length} Gemeinden`
    );

    if (input.failedTargets.length > 0) {
      lines.push("");
      lines.push("Fehler (Auszug):");
      const shown = input.failedTargets.slice(0, PUSHOVER_MAX_FAILED_TARGETS_IN_MESSAGE);
      for (const target of shown) {
        lines.push(`  ${target}`);
      }
      const remaining = input.failedTargets.length - shown.length;
      if (remaining > 0) {
        lines.push(`  +${remaining} mehr`);
      }
    }
  }

  if (input.skippedRateLimited > 0 || input.skippedQuietHours > 0) {
    lines.push("");
    lines.push(
      `Skipped: ${input.skippedRateLimited} rate-limited, ${input.skippedQuietHours} quiet-hours`
    );
  }

  lines.push(`Dauer: ${formatDuration(input.durationMs)}`);

  return {
    title,
    message: lines.join("\n"),
    priority: allOK ? "0" : "1",
  };
}

export async function sendPushoverReport(input: PushoverReportInput): Promise<void> {
  let status: PushoverReportStatus;
  try {
    status = await getPushoverReportStatus();
  } catch (error) {
    console.warn(`[${input.requestId}] pushover_status_error`, {
      error: error instanceof Error ? error.message : String(error),
    });
    return;
  }

  if (!status.enabled) {
    console.log(`[${input.requestId}] pushover_report_skipped`, {
      configured: status.configured,
      storedEnabled: status.storedEnabled,
      defaultEnabled: status.defaultEnabled,
    });
    return;
  }

  const config = getPushoverConfig();
  if (!config) {
    return;
  }

  const { title, message, priority } = buildPushoverMessage(input);

  const params = new URLSearchParams({
    token: config.appToken,
    user: config.userKey,
    title,
    message,
    priority,
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
      const text = await response.text();
      console.warn(`[${input.requestId}] pushover_send_failed`, {
        status: response.status,
        body: text.slice(0, 200),
      });
    }
  } catch (error) {
    console.warn(`[${input.requestId}] pushover_send_error`, {
      error: error instanceof Error ? error.message : String(error),
    });
  } finally {
    clearTimeout(timeout);
  }
}
