import type { Message, TopicMessage } from "firebase-admin/messaging";
import type { CronConfig } from "../api/cron/env";
import type { FeedResult } from "../api/cron/feed";
import type { MessagingLike } from "../api/cron/firebase";
import { runHitzeCron, type CronDeps, type HitzeCronHttpResponse } from "../api/cron/hitze";
import type { CronReporter, PushoverFailureReport, PushoverRunReport } from "../api/cron/pushover";
import type { RedisLike } from "../api/cron/redis";
import { RedisCronStateStore } from "../api/cron/state";

export class FakeRedis implements RedisLike {
  readonly strings = new Map<string, string>();
  readonly hashes = new Map<string, Map<string, string>>();
  /** Return true to make this hSetAtomic call throw (simulated Redis outage). */
  failHSetAtomic: ((writes: Array<{ key: string; fields: Record<string, string> }>) => boolean) | null = null;
  hSetAtomicCalls = 0;

  private hash(key: string): Map<string, string> {
    let hash = this.hashes.get(key);
    if (!hash) {
      hash = new Map();
      this.hashes.set(key, hash);
    }
    return hash;
  }

  async get(key: string): Promise<string | null> {
    return this.strings.get(key) ?? null;
  }

  async set(key: string, value: string): Promise<void> {
    this.strings.set(key, value);
  }

  async setNx(key: string, value: string, _ttlSeconds?: number): Promise<boolean> {
    if (this.strings.has(key)) {
      return false;
    }
    this.strings.set(key, value);
    return true;
  }

  async expireIfEquals(key: string, value: string, _ttlSeconds?: number): Promise<boolean> {
    return this.strings.get(key) === value;
  }

  async deleteIfEquals(key: string, value: string): Promise<boolean> {
    if (this.strings.get(key) !== value) {
      return false;
    }
    this.strings.delete(key);
    return true;
  }

  async hGetAll(key: string): Promise<Record<string, string>> {
    return Object.fromEntries(this.hashes.get(key) ?? []);
  }

  async hDel(key: string, fields: string[]): Promise<void> {
    for (const field of fields) {
      this.hashes.get(key)?.delete(field);
    }
  }

  async hSetAtomic(writes: Array<{ key: string; fields: Record<string, string> }>): Promise<void> {
    this.hSetAtomicCalls += 1;
    if (this.failHSetAtomic?.(writes)) {
      throw new Error("simulated Redis write failure");
    }
    for (const write of writes) {
      for (const [field, value] of Object.entries(write.fields)) {
        this.hash(write.key).set(field, value);
      }
    }
  }

  async ping(): Promise<void> {}

  hashFields(key: string): string[] {
    return Array.from(this.hashes.get(key)?.keys() ?? []).sort();
  }
}

export class FakeMessaging implements MessagingLike {
  readonly sent: Message[] = [];
  readonly attempted: Message[] = [];
  failWhen: ((message: Message) => boolean) | null = null;

  async send(message: Message): Promise<string> {
    this.attempted.push(message);
    if (this.failWhen?.(message)) {
      throw Object.assign(new Error("simulated FCM failure"), { code: "messaging/internal-error" });
    }
    this.sent.push(message);
    return `projects/test/messages/${this.sent.length}`;
  }

  topics(): string[] {
    return this.sent.map((message) => (message as TopicMessage).topic);
  }

  clear(): void {
    this.sent.length = 0;
    this.attempted.length = 0;
  }
}

export class RecordingReporter implements CronReporter {
  readonly runs: PushoverRunReport[] = [];
  readonly failures: PushoverFailureReport[] = [];

  async runReport(report: PushoverRunReport): Promise<void> {
    this.runs.push(report);
  }

  async failureReport(report: PushoverFailureReport): Promise<void> {
    this.failures.push(report);
  }
}

const unixSeconds = (iso: string): string => String(Math.floor(Date.parse(iso) / 1000));

/** A GeoSphere getWarnstatus feature (wlevel on the GeoSphere scale, 1 = yellow). */
export function heatFeature(
  id: string,
  wlevel: number,
  start: string,
  end: string,
  gemeinden: Array<string | number> = ["60101"]
): Record<string, unknown> {
  return {
    type: "Feature",
    geometry: null,
    properties: { warnid: id, wtype: 6, wlevel, start: unixSeconds(start), end: unixSeconds(end), gemeinden },
  };
}

export interface Harness {
  redis: FakeRedis;
  messaging: FakeMessaging;
  reporter: RecordingReporter;
  features: unknown[];
  now: number;
  config: CronConfig;
  deps(): CronDeps;
  runAt(iso: string): Promise<HitzeCronHttpResponse>;
}

export function createHarness(config: Partial<CronConfig> = {}): Harness {
  const harness: Harness = {
    redis: new FakeRedis(),
    messaging: new FakeMessaging(),
    reporter: new RecordingReporter(),
    features: [],
    now: 0,
    config: {
      minLevel: 2,
      legacyLanguageTopics: "off",
      fcmSendConcurrency: 4,
      cronLockTtlSeconds: 300,
      ...config,
    },
    deps(): CronDeps {
      return {
        now: () => harness.now,
        store: new RedisCronStateStore(harness.redis),
        messaging: () => harness.messaging,
        fetchFeed: async (): Promise<FeedResult> => ({
          features: harness.features,
          source: "static",
          sourceLocation: "test",
        }),
        config: harness.config,
        reporter: harness.reporter,
      };
    },
    runAt(iso: string) {
      harness.now = Date.parse(iso);
      harness.messaging.clear();
      return runHitzeCron(harness.deps());
    },
  };
  return harness;
}

export function v2Messages(messaging: FakeMessaging): TopicMessage[] {
  return messaging.sent.filter((message): message is TopicMessage =>
    (message as TopicMessage).topic?.startsWith("warngebiet_v2_")
  );
}

export function legacyMessages(messaging: FakeMessaging): TopicMessage[] {
  return messaging.sent.filter(
    (message): message is TopicMessage =>
      Boolean((message as TopicMessage).topic) && !(message as TopicMessage).topic.startsWith("warngebiet_v2_")
  );
}

export interface DayJson {
  date: string;
  level: number;
  start: string;
  end: string;
}

export function daysOf(message: TopicMessage): DayJson[] {
  return JSON.parse(message.data?.days ?? "[]") as DayJson[];
}
