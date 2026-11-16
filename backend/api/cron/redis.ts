import { createClient } from "redis";
import { envString } from "./env";
import { AppError, RedisUnavailableError, errorMessage } from "./errors";

const CONNECT_TIMEOUT_MS = 3_000;
const COMMAND_TIMEOUT_MS = 5_000;
const CONNECT_OVERALL_TIMEOUT_MS = 10_000;
const MAX_RECONNECT_ATTEMPTS = 2;

type NodeRedisClient = ReturnType<typeof createClient>;

/** The small command surface the backend needs; implemented by node-redis and by the test fake. */
export interface RedisLike {
  get(key: string): Promise<string | null>;
  set(key: string, value: string): Promise<void>;
  setNx(key: string, value: string, ttlSeconds: number): Promise<boolean>;
  expireIfEquals(key: string, value: string, ttlSeconds: number): Promise<boolean>;
  deleteIfEquals(key: string, value: string): Promise<boolean>;
  hGetAll(key: string): Promise<Record<string, string>>;
  hDel(key: string, fields: string[]): Promise<void>;
  /** Writes all hash fields in one MULTI/EXEC transaction. */
  hSetAtomic(writes: Array<{ key: string; fields: Record<string, string> }>): Promise<void>;
  ping(): Promise<void>;
}

let client: NodeRedisClient | null = null;
let connecting: Promise<NodeRedisClient> | null = null;

function withTimeout<T>(promise: Promise<T>, ms: number, message: string): Promise<T> {
  let timer: NodeJS.Timeout | undefined;
  const timeout = new Promise<never>((_, reject) => {
    timer = setTimeout(() => reject(new RedisUnavailableError(message)), ms);
  });
  return Promise.race([promise, timeout]).finally(() => clearTimeout(timer));
}

async function connectedClient(): Promise<NodeRedisClient> {
  if (client?.isOpen) {
    return client;
  }
  if (connecting) {
    return connecting;
  }

  const url = envString("REDIS_URL");
  if (!url) {
    throw new AppError(500, "CONFIG_ERROR", "Missing REDIS_URL environment variable.");
  }

  // A fresh client per connect attempt: a client that gave up reconnecting is closed for good.
  const fresh = createClient({
    url,
    disableOfflineQueue: true,
    commandOptions: { timeout: COMMAND_TIMEOUT_MS },
    socket: {
      connectTimeout: CONNECT_TIMEOUT_MS,
      reconnectStrategy: (retries: number, cause: Error) =>
        retries >= MAX_RECONNECT_ATTEMPTS ? cause : Math.min(500 * (retries + 1), 2_000),
    },
  });
  fresh.on("error", (error: unknown) => {
    console.error("redis_client_error", { error: errorMessage(error) });
  });

  connecting = withTimeout(fresh.connect(), CONNECT_OVERALL_TIMEOUT_MS, "Redis connect timed out.")
    .then(() => {
      client = fresh;
      return fresh;
    })
    .catch((error: unknown) => {
      try {
        fresh.destroy();
      } catch {
        // already closed
      }
      throw error instanceof RedisUnavailableError
        ? error
        : new RedisUnavailableError(`Redis connect failed: ${errorMessage(error)}`);
    })
    .finally(() => {
      connecting = null;
    });

  return connecting;
}

async function run<T>(operation: string, fn: (redis: NodeRedisClient) => Promise<T>): Promise<T> {
  const redis = await connectedClient();
  try {
    return await fn(redis);
  } catch (error) {
    throw new RedisUnavailableError(`Redis ${operation} failed: ${errorMessage(error)}`);
  }
}

const COMPARE_AND_EXPIRE = `
  if redis.call("GET", KEYS[1]) == ARGV[1] then
    return redis.call("EXPIRE", KEYS[1], ARGV[2])
  end
  return 0
`;

const COMPARE_AND_DELETE = `
  if redis.call("GET", KEYS[1]) == ARGV[1] then
    return redis.call("DEL", KEYS[1])
  end
  return 0
`;

export const sharedRedis: RedisLike = {
  get: (key) => run("GET", async (redis) => (await redis.get(key)) ?? null),
  set: (key, value) =>
    run("SET", async (redis) => {
      await redis.set(key, value);
    }),
  setNx: (key, value, ttlSeconds) =>
    run("SET NX", async (redis) => {
      const result = await redis.set(key, value, {
        expiration: { type: "EX", value: ttlSeconds },
        condition: "NX",
      });
      return result === "OK";
    }),
  expireIfEquals: (key, value, ttlSeconds) =>
    run("EXPIRE lock", async (redis) => {
      const result = await redis.eval(COMPARE_AND_EXPIRE, { keys: [key], arguments: [value, String(ttlSeconds)] });
      return result === 1;
    }),
  deleteIfEquals: (key, value) =>
    run("DEL lock", async (redis) => {
      const result = await redis.eval(COMPARE_AND_DELETE, { keys: [key], arguments: [value] });
      return result === 1;
    }),
  hGetAll: (key) => run("HGETALL", async (redis) => ({ ...(await redis.hGetAll(key)) })),
  hDel: (key, fields) =>
    run("HDEL", async (redis) => {
      if (fields.length > 0) {
        await redis.hDel(key, fields);
      }
    }),
  hSetAtomic: (writes) =>
    run("MULTI HSET", async (redis) => {
      const nonEmpty = writes.filter((write) => Object.keys(write.fields).length > 0);
      if (nonEmpty.length === 0) {
        return;
      }
      const multi = redis.multi();
      for (const write of nonEmpty) {
        multi.hSet(write.key, write.fields);
      }
      await multi.exec();
    }),
  ping: () =>
    run("PING", async (redis) => {
      await redis.ping();
    }),
};

export async function pingRedis(timeoutMs: number): Promise<void> {
  await withTimeout(sharedRedis.ping(), timeoutMs, "Redis PING timed out.");
}

export function isRedisConfigured(): boolean {
  return envString("REDIS_URL") !== null;
}

export async function closeRedis(): Promise<void> {
  const current = client;
  client = null;
  if (!current?.isOpen) {
    return;
  }
  try {
    await withTimeout(current.close(), 2_000, "Redis close timed out.");
  } catch {
    current.destroy();
  }
}
