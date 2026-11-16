import { createHash, timingSafeEqual } from "node:crypto";
import { existsSync, readFileSync } from "node:fs";
import path from "node:path";
import express, { type NextFunction, type Request, type Response } from "express";
import { assetsDir, loadCronConfig } from "../api/cron/env";
import { AppError, errorMessage } from "../api/cron/errors";
import { checkFirebaseReady, firebaseErrorCode } from "../api/cron/firebase";
import {
  MAX_TEST_BULK_IDS,
  listSupportedPushLanguages,
  listTestMunicipalityOptions,
  loadCurrentWarningsSnapshot,
  parseSupportedPushLanguage,
  sendTestPush,
  sendTestPushBulk,
  sendTestPushToToken,
  type HitzeCronHttpResponse,
  type TestPushOptions,
} from "../api/cron/hitze";
import { getPushoverReportStatus, setPushoverReportsEnabled } from "../api/cron/pushover";
import { pingRedis } from "../api/cron/redis";
import { renderDevelopIndexPage, renderRootPage } from "./pages/index";
import { renderPushoverSettingsPage } from "./pages/pushover";
import { renderTestPushPage } from "./pages/testPush";
import { renderWarningsPage } from "./pages/warnings";

const POLITICAL_DISTRICTS_GEOJSON_FILE = "political-districts-20260101.geojson";
const MUNICIPALITIES_GEOJSON_FILE = "municipalities-20260101.geojson";
const JSON_BODY_LIMIT = "64kb";
const READY_REDIS_TIMEOUT_MS = 2_000;

interface TestMapFeature {
  id: string;
  name: string;
  geometry: unknown;
}

const mapFeatureCache = new Map<string, TestMapFeature[]>();

function loadMapFeatures(fileName: string): TestMapFeature[] {
  const cached = mapFeatureCache.get(fileName);
  if (cached) {
    return cached;
  }

  const features: TestMapFeature[] = [];
  const filePath = path.join(assetsDir(), "map", fileName);
  if (existsSync(filePath)) {
    try {
      const payload = JSON.parse(readFileSync(filePath, "utf8")) as { features?: unknown };
      for (const feature of Array.isArray(payload.features) ? payload.features : []) {
        const record = feature as { id?: unknown; properties?: { id?: unknown; name?: unknown }; geometry?: unknown };
        const id = String(record.properties?.id ?? record.id ?? "").trim();
        const name = String(record.properties?.name ?? "").trim();
        if (id && name && record.geometry) {
          features.push({ id, name, geometry: record.geometry });
        }
      }
    } catch (error) {
      console.warn("map_geojson_load_failed", { fileName, error: errorMessage(error) });
    }
  } else {
    console.warn("map_geojson_missing", { fileName });
  }

  mapFeatureCache.set(fileName, features);
  return features;
}

function digest(value: string): Buffer {
  return createHash("sha256").update(value, "utf8").digest();
}

/** Constant-time Bearer check (hashing first equalises the lengths). */
export function isAuthorizedHeader(header: string | undefined, secret: string): boolean {
  const match = /^Bearer (.+)$/.exec(header ?? "");
  const token = match ? match[1] : "";
  return timingSafeEqual(digest(token), digest(secret)) && token.length > 0;
}

/** Tracks in-flight cron runs so a shutdown can wait for them and abort their remaining sends. */
export class CronRunTracker {
  private readonly inFlight = new Set<Promise<unknown>>();
  private readonly controller = new AbortController();
  private closing = false;

  get signal(): AbortSignal {
    return this.controller.signal;
  }

  get isClosing(): boolean {
    return this.closing;
  }

  track<T>(run: Promise<T>): Promise<T> {
    this.inFlight.add(run);
    const cleanup = (): void => {
      this.inFlight.delete(run);
    };
    run.then(cleanup, cleanup);
    return run;
  }

  /**
   * Stops accepting runs and waits up to `timeoutMs`. Then aborts: no new sends start, but
   * sends already in flight still persist their state (otherwise they repeat on the next run),
   * so it waits up to `abortGraceMs` more for the runs to finish. "abandoned" = that bound was hit.
   */
  async drain(timeoutMs: number, abortGraceMs: number): Promise<"idle" | "drained" | "aborted" | "abandoned"> {
    this.closing = true;
    if (this.inFlight.size === 0) {
      return "idle";
    }
    if (await this.settledWithin(timeoutMs)) {
      return "drained";
    }
    this.controller.abort();
    return (await this.settledWithin(abortGraceMs)) ? "aborted" : "abandoned";
  }

  private async settledWithin(ms: number): Promise<boolean> {
    let timer: NodeJS.Timeout | undefined;
    const settled = await Promise.race([
      Promise.allSettled(Array.from(this.inFlight)).then(() => true),
      new Promise<boolean>((resolve) => {
        timer = setTimeout(() => resolve(false), ms);
      }),
    ]);
    clearTimeout(timer);
    return settled;
  }
}

export interface AppOptions {
  cronSecret: string;
  developMode: boolean;
  runCron: (signal: AbortSignal) => Promise<HitzeCronHttpResponse>;
  tracker: CronRunTracker;
}

const HTML_CSP = [
  "default-src 'none'",
  "script-src 'unsafe-inline'",
  "style-src 'unsafe-inline'",
  "img-src 'self' data:",
  "connect-src 'self'",
  "base-uri 'none'",
  "form-action 'none'",
  "frame-ancestors 'none'",
].join("; ");

function sendHtml(res: Response, html: string): void {
  res.setHeader("Cache-Control", "no-store");
  res.setHeader("Content-Security-Policy", HTML_CSP);
  res.setHeader("X-Frame-Options", "DENY");
  res.status(200).type("html").send(html);
}

function noStore(res: Response): void {
  res.setHeader("Cache-Control", "no-store");
}

function optionalString(value: unknown): string | undefined {
  return typeof value === "string" ? value : undefined;
}

function parseTestPushOptions(body: Record<string, unknown>): TestPushOptions {
  const rawFormat = body.format;
  if (rawFormat !== undefined && rawFormat !== "v2" && rawFormat !== "legacy") {
    throw new AppError(400, "INVALID_INPUT", "format must be 'v2' or 'legacy'.");
  }
  const format = rawFormat ?? "legacy";

  let language: TestPushOptions["language"];
  const rawLanguage = body.lang;
  if (rawLanguage !== undefined && rawLanguage !== null && rawLanguage !== "") {
    if (typeof rawLanguage !== "string") {
      throw new AppError(400, "INVALID_INPUT", "lang must be a string when provided.");
    }
    const parsed = parseSupportedPushLanguage(rawLanguage);
    if (!parsed) {
      throw new AppError(400, "INVALID_INPUT", `Unsupported lang '${rawLanguage.trim().slice(0, 10)}'.`);
    }
    language = parsed;
  }

  return { format, language, title: optionalString(body.title), body: optionalString(body.body) };
}

function sendError(res: Response, error: unknown, fallbackCode: string): void {
  if (error instanceof AppError) {
    res.status(error.status).json({ errorCode: error.code, message: error.message });
    return;
  }
  // Only reachable by authenticated develop callers; Firebase details help debugging there.
  res.status(500).json({ errorCode: fallbackCode, message: errorMessage(error), firebaseCode: firebaseErrorCode(error) });
}

export interface ReadinessResult {
  ok: boolean;
  checks: { redis: "ok" | "error"; firebase: "ok" | "error" };
}

export async function checkReadiness(): Promise<ReadinessResult> {
  const redis = await pingRedis(READY_REDIS_TIMEOUT_MS).then(
    () => "ok" as const,
    (error: unknown) => {
      console.warn("ready_redis_failed", { error: errorMessage(error) });
      return "error" as const;
    }
  );
  let firebase: "ok" | "error" = "ok";
  try {
    checkFirebaseReady();
  } catch (error) {
    console.warn("ready_firebase_failed", { error: errorMessage(error) });
    firebase = "error";
  }
  return { ok: redis === "ok" && firebase === "ok", checks: { redis, firebase } };
}

export function createApp(options: AppOptions): express.Express {
  const { cronSecret, developMode, runCron, tracker } = options;
  const app = express();
  app.disable("x-powered-by");
  app.set("etag", false);

  app.use((_req: Request, res: Response, next: NextFunction) => {
    res.setHeader("X-Content-Type-Options", "nosniff");
    res.setHeader("Referrer-Policy", "no-referrer");
    next();
  });
  app.use(express.json({ limit: JSON_BODY_LIMIT }));

  const requireAuth = (req: Request, res: Response, next: NextFunction): void => {
    if (!isAuthorizedHeader(req.header("authorization"), cronSecret)) {
      res.status(401).json({ errorCode: "UNAUTHORIZED", message: "Missing or invalid Authorization header." });
      return;
    }
    next();
  };

  app.get("/", (_req: Request, res: Response) => {
    sendHtml(res, renderRootPage());
  });

  app.get("/health", (_req: Request, res: Response) => {
    noStore(res);
    res.status(200).json({ ok: true });
  });

  app.get("/ready", async (_req: Request, res: Response) => {
    noStore(res);
    if (tracker.isClosing) {
      res.status(503).json({ ok: false, shuttingDown: true });
      return;
    }
    const result = await checkReadiness();
    res.status(result.ok ? 200 : 503).json(result);
  });

  app.post("/cron/hitze", requireAuth, async (_req: Request, res: Response) => {
    noStore(res);
    if (tracker.isClosing) {
      res.status(503).json({ errorCode: "SHUTTING_DOWN", message: "Server is shutting down." });
      return;
    }
    const result = await tracker.track(runCron(tracker.signal));
    for (const [key, value] of Object.entries(result.headers ?? {})) {
      res.setHeader(key, value);
    }
    res.status(result.status).json(result.body);
  });

  if (developMode) {
    // HTML shells carry no data; every data or send endpoint below needs the Bearer secret.
    app.get("/test", (_req: Request, res: Response) => sendHtml(res, renderDevelopIndexPage()));
    app.get("/test/push/ui", (_req: Request, res: Response) => sendHtml(res, renderTestPushPage(MAX_TEST_BULK_IDS)));
    app.get("/test/warnings/ui", (_req: Request, res: Response) => sendHtml(res, renderWarningsPage()));
    app.get("/test/pushover/ui", (_req: Request, res: Response) => sendHtml(res, renderPushoverSettingsPage()));

    app.use("/test", requireAuth);

    app.get("/test/push/options", (_req: Request, res: Response) => {
      noStore(res);
      res.status(200).json({
        municipalities: listTestMunicipalityOptions(),
        languages: listSupportedPushLanguages(),
        defaultLegacyLanguage: "de",
        maxBulkIds: MAX_TEST_BULK_IDS,
      });
    });

    app.get("/test/pushover/status", async (_req: Request, res: Response) => {
      noStore(res);
      try {
        res.status(200).json(await getPushoverReportStatus());
      } catch (error) {
        sendError(res, error, "PUSHOVER_STATUS_FAILED");
      }
    });

    app.post("/test/pushover/status", async (req: Request, res: Response) => {
      const enabled = (req.body as Record<string, unknown> | undefined)?.enabled;
      if (typeof enabled !== "boolean") {
        res.status(400).json({ errorCode: "INVALID_INPUT", message: "enabled must be a boolean." });
        return;
      }
      try {
        res.status(200).json(await setPushoverReportsEnabled(enabled));
      } catch (error) {
        sendError(res, error, "PUSHOVER_STATUS_SAVE_FAILED");
      }
    });

    app.get("/test/warnings/data", async (_req: Request, res: Response) => {
      noStore(res);
      try {
        const snapshot = await loadCurrentWarningsSnapshot();
        res.status(200).json({
          ...snapshot,
          districtFeatures: loadMapFeatures(POLITICAL_DISTRICTS_GEOJSON_FILE),
          municipalityFeatures: loadMapFeatures(MUNICIPALITIES_GEOJSON_FILE),
        });
      } catch (error) {
        sendError(res, error, "WARNINGS_SNAPSHOT_FAILED");
      }
    });

    app.post("/test/push", async (req: Request, res: Response) => {
      const body = (req.body ?? {}) as Record<string, unknown>;
      try {
        const municipalityId = optionalString(body.municipalityId)?.trim();
        if (!municipalityId) {
          throw new AppError(400, "INVALID_INPUT", "municipalityId is required in JSON body.");
        }
        const result = await sendTestPush(municipalityId, parseTestPushOptions(body));
        res.status(200).json({ ok: true, ...result });
      } catch (error) {
        sendError(res, error, "TEST_PUSH_FAILED");
      }
    });

    app.post("/test/push/bulk", async (req: Request, res: Response) => {
      const body = (req.body ?? {}) as Record<string, unknown>;
      try {
        const ids = Array.isArray(body.municipalityIds)
          ? body.municipalityIds.filter((entry: unknown): entry is string => typeof entry === "string")
          : [];
        const options = parseTestPushOptions(body);
        const result = await sendTestPushBulk(ids, options, loadCronConfig().fcmSendConcurrency);
        res.status(200).json({
          ok: true,
          format: options.format,
          lang: options.format === "legacy" ? options.language ?? "de" : null,
          sentCount: result.sent.length,
          failedCount: result.failed.length,
          recipients: result.sent,
          failures: result.failed,
        });
      } catch (error) {
        sendError(res, error, "TEST_PUSH_BULK_FAILED");
      }
    });

    app.post("/test/push/token", async (req: Request, res: Response) => {
      const body = (req.body ?? {}) as Record<string, unknown>;
      try {
        const token = optionalString(body.token) ?? "";
        const options = parseTestPushOptions(body);
        const result = await sendTestPushToToken(token, optionalString(body.municipalityId) ?? "", options);
        res.status(200).json({ ok: true, format: options.format, ...result });
      } catch (error) {
        sendError(res, error, "TEST_PUSH_TOKEN_FAILED");
      }
    });
  }

  app.use((_req: Request, res: Response) => {
    res.status(404).json({ errorCode: "NOT_FOUND", message: "Not found." });
  });

  // Body-parser errors (oversized or malformed JSON) and anything unexpected; never leak stack traces.
  app.use((error: unknown, _req: Request, res: Response, next: NextFunction) => {
    if (res.headersSent) {
      next(error);
      return;
    }
    const status =
      typeof error === "object" && error !== null && typeof (error as { status?: unknown }).status === "number"
        ? (error as { status: number }).status
        : 500;
    if (status >= 500) {
      console.error("http_unhandled_error", { error: errorMessage(error) });
    }
    res.status(status).json({
      errorCode: status === 413 ? "PAYLOAD_TOO_LARGE" : status === 400 ? "INVALID_JSON" : "INTERNAL_ERROR",
      message: status < 500 ? "Invalid request body." : "Internal error.",
    });
  });

  return app;
}
