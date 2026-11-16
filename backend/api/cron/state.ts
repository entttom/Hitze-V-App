import type { DayState, PushableEvent } from "./decision";
import type { RedisLike } from "./redis";
import type { PushDay } from "./renderer";

/** Shared with the v1 deployment so an old and a new container never run concurrently. */
export const CRON_LOCK_KEY = "hitze:v1:cron_lock";
export const DAY_STATE_KEY = "hitze:v2:day_state";
export const LAST_PUSH_KEY = "hitze:v2:last_push";
export const LEGACY_SENT_KEY = "hitze:v2:legacy_sent";

/** Content of the last successful v2 push per municipality; legacy topics are retried from it. */
export interface LastPush {
  fingerprint: string;
  event: PushableEvent;
  name: string;
  days: PushDay[];
  warningIds: string[];
  sentAt: string;
  /** Epoch ms of the latest day end; retries stop afterwards. */
  expiresAt: number;
  /** Legacy languages this push was meant for. */
  legacyLanguages: string[];
}

/** Last push content delivered to one legacy `warngebiet_<GKZ>_<lang>` topic. */
export interface LegacySent {
  fingerprint: string;
  expiresAt: number;
}

export interface StateUpdate {
  dayStates?: Record<string, DayState>;
  lastPush?: { gkz: string; value: LastPush };
  legacySent?: Record<string, LegacySent>;
}

export interface CronStateStore {
  acquireLock(token: string, ttlSeconds: number): Promise<boolean>;
  refreshLock(token: string, ttlSeconds: number): Promise<boolean>;
  releaseLock(token: string): Promise<void>;
  loadDayStates(): Promise<Map<string, DayState>>;
  loadLastPushes(): Promise<Map<string, LastPush>>;
  loadLegacySent(): Promise<Map<string, LegacySent>>;
  deleteEntries(entries: { dayStates?: string[]; lastPushes?: string[]; legacySent?: string[] }): Promise<void>;
  /** All writes of one municipality in one transaction. */
  persist(update: StateUpdate): Promise<void>;
}

export function legacySentKey(gkz: string, language: string): string {
  return `${gkz}|${language}`;
}

function parseJson(value: string): unknown {
  try {
    return JSON.parse(value);
  } catch {
    return null;
  }
}

function isObject(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null;
}

function parseDayState(value: string): DayState | null {
  const parsed = parseJson(value);
  if (!isObject(parsed) || typeof parsed.level !== "number") {
    return null;
  }
  const text = (key: string): string => (typeof parsed[key] === "string" ? (parsed[key] as string) : "");
  return {
    level: parsed.level,
    // Entries written before pushedLevel existed: the stored level is the best known pushed level.
    pushedLevel: typeof parsed.pushedLevel === "number" ? parsed.pushedLevel : parsed.level,
    start: text("start"),
    end: text("end"),
    sentDayKey: text("sentDayKey"),
    updatedDayKey: text("updatedDayKey"),
  };
}

function parseLastPush(value: string): LastPush | null {
  const parsed = parseJson(value);
  if (
    !isObject(parsed) ||
    typeof parsed.fingerprint !== "string" ||
    typeof parsed.expiresAt !== "number" ||
    !Array.isArray(parsed.days)
  ) {
    return null;
  }
  return parsed as unknown as LastPush;
}

function parseLegacySent(value: string): LegacySent | null {
  const parsed = parseJson(value);
  if (!isObject(parsed) || typeof parsed.fingerprint !== "string" || typeof parsed.expiresAt !== "number") {
    return null;
  }
  return { fingerprint: parsed.fingerprint, expiresAt: parsed.expiresAt };
}

function parseHash<T>(hash: Record<string, string>, parse: (value: string) => T | null): Map<string, T> {
  const map = new Map<string, T>();
  for (const [field, value] of Object.entries(hash)) {
    const parsed = parse(value);
    if (parsed) {
      map.set(field, parsed);
    }
  }
  return map;
}

function serialize<T>(entries: Record<string, T>): Record<string, string> {
  const fields: Record<string, string> = {};
  for (const [field, value] of Object.entries(entries)) {
    fields[field] = JSON.stringify(value);
  }
  return fields;
}

export class RedisCronStateStore implements CronStateStore {
  constructor(private readonly redis: RedisLike) {}

  acquireLock(token: string, ttlSeconds: number): Promise<boolean> {
    return this.redis.setNx(CRON_LOCK_KEY, token, ttlSeconds);
  }

  refreshLock(token: string, ttlSeconds: number): Promise<boolean> {
    return this.redis.expireIfEquals(CRON_LOCK_KEY, token, ttlSeconds);
  }

  async releaseLock(token: string): Promise<void> {
    await this.redis.deleteIfEquals(CRON_LOCK_KEY, token);
  }

  async loadDayStates(): Promise<Map<string, DayState>> {
    return parseHash(await this.redis.hGetAll(DAY_STATE_KEY), parseDayState);
  }

  async loadLastPushes(): Promise<Map<string, LastPush>> {
    return parseHash(await this.redis.hGetAll(LAST_PUSH_KEY), parseLastPush);
  }

  async loadLegacySent(): Promise<Map<string, LegacySent>> {
    return parseHash(await this.redis.hGetAll(LEGACY_SENT_KEY), parseLegacySent);
  }

  async deleteEntries(entries: { dayStates?: string[]; lastPushes?: string[]; legacySent?: string[] }): Promise<void> {
    await this.redis.hDel(DAY_STATE_KEY, entries.dayStates ?? []);
    await this.redis.hDel(LAST_PUSH_KEY, entries.lastPushes ?? []);
    await this.redis.hDel(LEGACY_SENT_KEY, entries.legacySent ?? []);
  }

  async persist(update: StateUpdate): Promise<void> {
    await this.redis.hSetAtomic([
      { key: DAY_STATE_KEY, fields: serialize(update.dayStates ?? {}) },
      {
        key: LAST_PUSH_KEY,
        fields: update.lastPush ? { [update.lastPush.gkz]: JSON.stringify(update.lastPush.value) } : {},
      },
      { key: LEGACY_SENT_KEY, fields: serialize(update.legacySent ?? {}) },
    ]);
  }
}
