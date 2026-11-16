import path from "node:path";

export function isEnvFlagEnabled(value: string | undefined): boolean {
  if (!value) {
    return false;
  }

  return ["1", "true", "yes", "on"].includes(value.trim().toLowerCase());
}

export function envString(name: string): string | null {
  const value = process.env[name]?.trim();
  return value ? value : null;
}

export function boundedIntegerEnv(name: string, defaultValue: number, min: number, max: number): number {
  const raw = envString(name);
  if (!raw) {
    return defaultValue;
  }

  const value = Number(raw);
  if (!Number.isInteger(value) || value < min || value > max) {
    console.warn("env_value_ignored", { name, allowed: `${min}..${max}`, defaultValue });
    return defaultValue;
  }

  return value;
}

export type LegacyLanguageTopicsMode = "all" | "de" | "off";

export interface CronConfig {
  /** Hitze-V scale (2 = yellow, 3 = orange, 4 = red). */
  minLevel: number;
  legacyLanguageTopics: LegacyLanguageTopicsMode;
  fcmSendConcurrency: number;
  cronLockTtlSeconds: number;
}

export const DEFAULT_MIN_LEVEL = 2;
export const DEFAULT_FCM_SEND_CONCURRENCY = 50;
export const DEFAULT_CRON_LOCK_TTL_SECONDS = 5 * 60;

export function legacyLanguageTopicsMode(): LegacyLanguageTopicsMode {
  const raw = envString("LEGACY_LANGUAGE_TOPICS")?.toLowerCase();
  if (!raw) {
    return "all";
  }

  if (raw === "all" || raw === "de" || raw === "off") {
    return raw;
  }

  console.warn("env_value_ignored", { name: "LEGACY_LANGUAGE_TOPICS", allowed: "all|de|off", defaultValue: "all" });
  return "all";
}

export function loadCronConfig(): CronConfig {
  return {
    minLevel: boundedIntegerEnv("HITZE_MIN_LEVEL", DEFAULT_MIN_LEVEL, 2, 4),
    legacyLanguageTopics: legacyLanguageTopicsMode(),
    fcmSendConcurrency: boundedIntegerEnv("HITZE_FCM_SEND_CONCURRENCY", DEFAULT_FCM_SEND_CONCURRENCY, 1, 500),
    cronLockTtlSeconds: boundedIntegerEnv("HITZE_CRON_LOCK_TTL_SECONDS", DEFAULT_CRON_LOCK_TTL_SECONDS, 30, 60 * 60),
  };
}

export function isDevelopMode(): boolean {
  return isEnvFlagEnabled(process.env.develop) || isEnvFlagEnabled(process.env.DEVELOP);
}

export function useStaticGeoSphereResponse(): boolean {
  return isEnvFlagEnabled(process.env.HITZE_USE_STATIC_GEOSPHERE_RESPONSE);
}

export interface StaticFeedSource {
  kind: "url" | "file";
  location: string;
}

/** An explicit URL wins; otherwise a local file (default: example_response.json in the working directory). */
export function staticGeoSphereSource(): StaticFeedSource {
  const url = envString("HITZE_STATIC_GEOSPHERE_URL");
  if (url) {
    return { kind: "url", location: url };
  }

  const file = envString("HITZE_STATIC_GEOSPHERE_FILE") ?? "example_response.json";
  return { kind: "file", location: path.resolve(process.cwd(), file) };
}

/** Root of the runtime assets: dist/assets after a build, backend/assets when run from source. */
export function assetsDir(): string {
  return path.resolve(__dirname, "..", "..", "assets");
}
