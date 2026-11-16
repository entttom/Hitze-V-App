import { boundedIntegerEnv, envString, isDevelopMode, loadCronConfig } from "../api/cron/env";
import { errorMessage } from "../api/cron/errors";
import { executeHitzeCron } from "../api/cron/hitze";
import { isPushoverConfigured } from "../api/cron/pushover";
import { closeRedis } from "../api/cron/redis";
import { CronRunTracker, createApp } from "./app";

const cronSecret = envString("CRON_SECRET");
if (!cronSecret) {
  console.error(
    [
      "",
      "FATAL: CRON_SECRET is missing or empty.",
      "Without it POST /cron/hitze and the develop routes cannot be authenticated; the server refuses to start.",
      "Generate one with `openssl rand -hex 32` and set CRON_SECRET in the environment.",
      "",
    ].join("\n")
  );
  process.exit(1);
}

const port = boundedIntegerEnv("PORT", 3000, 1, 65_535);
// Docker's default stop grace period is 10 s; both waits together stay below it.
const shutdownTimeoutMs = boundedIntegerEnv("HITZE_SHUTDOWN_TIMEOUT_MS", 4_000, 1_000, 120_000);
const shutdownAbortGraceMs = boundedIntegerEnv("HITZE_SHUTDOWN_ABORT_GRACE_MS", 5_000, 500, 60_000);
const developMode = isDevelopMode();
const tracker = new CronRunTracker();

const app = createApp({
  cronSecret,
  developMode,
  runCron: (signal) => executeHitzeCron(signal),
  tracker,
});

const server = app.listen(port, "0.0.0.0", () => {
  const config = loadCronConfig();
  console.log("hitze_backend_listening", {
    port,
    developMode,
    minLevel: config.minLevel,
    legacyLanguageTopics: config.legacyLanguageTopics,
    pushover: isPushoverConfigured() ? "configured" : "off",
  });
});
server.requestTimeout = 5 * 60 * 1000;

let shuttingDown = false;

async function shutdown(signal: NodeJS.Signals): Promise<void> {
  if (shuttingDown) {
    return;
  }
  shuttingDown = true;
  console.log("shutdown_started", { signal });

  server.close();
  server.closeIdleConnections();

  const drain = await tracker.drain(shutdownTimeoutMs, shutdownAbortGraceMs);
  if (drain === "abandoned") {
    console.error("shutdown_cron_abandoned", { abortGraceMs: shutdownAbortGraceMs });
  } else {
    console.log("shutdown_cron", { result: drain });
  }

  server.closeAllConnections();
  try {
    await closeRedis();
  } catch (error) {
    console.warn("shutdown_redis_close_failed", { error: errorMessage(error) });
  }
  console.log("shutdown_complete");
  process.exit(0);
}

process.on("SIGTERM", (signal) => void shutdown(signal));
process.on("SIGINT", (signal) => void shutdown(signal));
