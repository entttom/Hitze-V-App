# HitzeV Backend

Internal Node/TypeScript service (Express) on the internal Coolify instance. A scheduler calls
`POST /cron/hitze`; the backend reads the GeoSphere Austria warning feed (`getWarnstatus`),
decides per municipality (GKZ) and day what to push, and sends Firebase Cloud Messaging topic
messages. The apps never call the backend; they subscribe to FCM topics directly.

Push format and rendering rules: [`docs/push-contract-v2.md`](../docs/push-contract-v2.md).
Texts: [`assets/push-copy.json`](assets/push-copy.json) (single source of truth, read-only here),
golden vectors: [`assets/push-copy-examples.json`](assets/push-copy-examples.json).

## Local development

```bash
npm ci
npm run build      # tsc + copies assets/ to dist/assets (no network access)
npm test           # node:test via tsx: renderer golden vectors, decision engine, payloads, HTTP
npm run typecheck  # tsc --noEmit for sources and tests
npm run start      # node dist/src/server.js
npm run dev        # tsx watch src/server.ts
```

The service listens on `PORT` (default `3000`) and refuses to start without `CRON_SECRET`.

### Map data for the develop warnings page

`assets/map/*.geojson` are the Statistik Austria 2026-01-01 political districts and municipalities
(CC BY 4.0, EPSG:31287, simplified; district 900 "Wien (Stadt)" is left out because 901–923 cover it).
They are committed so the build is reproducible and offline. To refresh them manually:

```bash
npm run update-map   # downloads the WFS datasets and rewrites assets/map/*.geojson
```

### Municipality names

`assets/municipalities.json` (2114 GKZ → name, whitespace-normalised: "Wien 1., Innere Stadt")
was converted once from `gemliste_knz.xls`; its IDs match the municipality GeoJSON. The `.xls`
is no longer read at runtime.

## Endpoints

| Method | Path | Auth | Purpose |
|---|---|---|---|
| `GET` | `/` | – | Minimal page, no endpoint list |
| `GET` | `/health` | – | Liveness, no dependencies (Docker `HEALTHCHECK`) |
| `GET` | `/ready` | – | Readiness: Redis `PING` (2 s timeout) + Firebase initialisation; 503 if not ready |
| `POST` | `/cron/hitze` | `Authorization: Bearer <CRON_SECRET>` | Run the heat-warning evaluation |

Develop mode only (`DEVELOP=true`); the HTML pages carry no data and ask once per browser session
for `CRON_SECRET`; every data/send route needs the Bearer secret:

| Method | Path | Purpose |
|---|---|---|
| `GET` | `/test`, `/test/push/ui`, `/test/warnings/ui`, `/test/pushover/ui` | Develop pages (light/dark) |
| `GET` | `/test/push/options` | Municipalities and legacy languages for the test UI |
| `POST` | `/test/push` | Test push to one municipality |
| `POST` | `/test/push/bulk` | Test push to up to 50 municipalities |
| `POST` | `/test/push/token` | Test push to one device token |
| `GET` | `/test/warnings/data` | Live feed snapshot (no push, no Redis write) |
| `GET`/`POST` | `/test/pushover/status` | Pushover report switch |

Test push body: `{"municipalityId": "60101", "format": "v2" | "legacy", "lang": "de", "title": "…", "body": "…"}`.
`format` defaults to `legacy`. `v2` sends a `type=test` data message to `warngebiet_v2_<GKZ>`
(title/body only replace the German iOS fallback alert); `legacy` sends to
`warngebiet_<GKZ>_<lang>` with a visible notification (empty title/body = test copy from
`push-copy.json`).

```bash
curl -X POST http://localhost:3000/test/push \
  -H "Authorization: Bearer $CRON_SECRET" \
  -H "Content-Type: application/json" \
  -d '{"municipalityId": "90101", "format": "v2"}'
```

## What a cron run does

1. Takes the Redis lock `hitze:v1:cron_lock` (shared with the previous version so old and new
   containers never run at once). TTL `HITZE_CRON_LOCK_TTL_SECONDS` (default 300 s), refreshed
   every TTL/3 while the run is active; a run that loses the lock stops sending.
2. Fetches the feed, keeps heat warnings (type 6) with Hitze-V level ≥ `HITZE_MIN_LEVEL`
   (level = GeoSphere `wlevel` + 1, clamped to 4) that have not ended.
3. Splits every warning across each Vienna calendar day it overlaps, with start/end clipped to that
   day (a continuation day starts at 00:00 Vienna, a day that continues ends at the next midnight;
   DST-correct). A warning without start begins today; one without end runs up to today. Pieces of
   the same GKZ and day are merged: highest level, earliest start, latest end. Only today and
   tomorrow (Europe/Vienna) are pushable; later days are pushed once they become tomorrow.
4. Per GKZ and day against the stored state: `new` (day never sent), `escalated` (level above the
   highest level already **pushed** for that day; never rate-limited), `updated` (same level,
   start/end changed while still relevant, at most once per GKZ and day per Vienna day; the push
   carries only the changed days). Downgrades, cancellations, expiry, and start shifts of warnings
   that already began are not pushed; they only update the last seen level/window.
   A day's state, including its highest pushed level, is kept until the day is over, even if the
   warning disappears from the feed. A warning that disappears and comes back the same day at the
   same or a lower level is therefore not pushed again; only a higher level is `escalated`. A feed
   that flaps 3→2→3→2→3 pushes `new` once and nothing else. A warning lasting several days is
   pushed per day: each new day that becomes "tomorrow" is `new` once.
5. Quiet hours 20:00–06:00 Europe/Vienna: pushes are deferred and their state is not saved, so they go
   out at the first run from 06:00.
6. Per GKZ: one v2 message to `warngebiet_v2_<GKZ>` plus legacy messages to
   `warngebiet_<GKZ>_<lang>` (`LEGACY_LANGUAGE_TOPICS`). Legacy messages keep a visible
   `notification` (rendered from `push-copy.json` in the topic language), the old data keys, and get
   `collapseKey`/`tag`/`apns-collapse-id` `hitze-<GKZ>` plus TTL/expiration.
7. Each GKZ's state is written in one Redis transaction right after its sends. The v2 send decides
   the day state; legacy deliveries are tracked per language and failed languages are retried on the
   next runs (until the warning ends) without repeating the v2 push. If a state write fails, the run
   stops sending so at most that one GKZ can be pushed twice.
8. SIGTERM: no new runs are accepted; a running cron gets `HITZE_SHUTDOWN_TIMEOUT_MS` to finish.
   Then it is aborted (no new sends start) and the server waits up to
   `HITZE_SHUTDOWN_ABORT_GRACE_MS` more for the sends already in flight to record their state
   before Redis is closed and the process exits; only if that bound is hit can a GKZ be pushed
   again on the next run (logged as `shutdown_cron_abandoned`).

Redis keys: `hitze:v2:day_state` (`<GKZ>|<date>` → level (last seen)/pushedLevel (highest pushed)/
start/end/sentDayKey/updatedDayKey; entries written before `pushedLevel` existed use their stored
level as `pushedLevel`),
`hitze:v2:last_push` (`<GKZ>` → last v2 content), `hitze:v2:legacy_sent` (`<GKZ>|<lang>`). Past
days and expired entries are removed on each run. The old `hitze:v1:signatures` and
`hitze:v1:send_meta` hashes are ignored (delete them manually when convenient).

**Migration:** the v2 state starts empty. Deployed while warnings are active, every affected GKZ
gets one `new` push (v2 + legacy) even if v1 had already notified it. Deploying outside the heat
season (empty feed) avoids that.

**Android during the migration:** legacy messages carry a `notification` block, which Android
posts itself (tag `hitze-<GKZ>`, id 0), while v2 apps post the v2 push themselves (tag
`hitze-<GKZ>`, id 1). A device that still receives a legacy topic while already subscribed to the
v2 topic (an updated app before its legacy unsubscribe has gone through) can therefore briefly
show both notifications. It ends once the app has dropped its legacy topics; the backend keeps
the legacy format unchanged for old app versions.

## Environment

Required: `CRON_SECRET`, `FIREBASE_SERVICE_ACCOUNT` (JSON string), `REDIS_URL`.

| Variable | Default | Meaning |
|---|---|---|
| `PORT` | `3000` | HTTP port |
| `HITZE_MIN_LEVEL` | `2` | Minimum Hitze-V level pushed: 2 yellow, 3 orange, 4 red |
| `LEGACY_LANGUAGE_TOPICS` | `all` | `all` (25 languages) \| `de` \| `off` – legacy fan-out during the transition |
| `HITZE_FCM_SEND_CONCURRENCY` | `50` | Parallel FCM sends (1–500) |
| `HITZE_CRON_LOCK_TTL_SECONDS` | `300` | Lock TTL (30–3600), refreshed during a run |
| `HITZE_SHUTDOWN_TIMEOUT_MS` | `4000` | SIGTERM: wait this long for a running cron, then abort its remaining sends |
| `HITZE_SHUTDOWN_ABORT_GRACE_MS` | `5000` | After the abort: max. wait for in-flight sends to record their state |
| `DEVELOP` / `develop` | off | Enables `/test` pages and the authenticated `/test/*` API |
| `HITZE_USE_STATIC_GEOSPHERE_RESPONSE` | off | Use a static feed instead of GeoSphere |
| `HITZE_STATIC_GEOSPHERE_FILE` | `example_response.json` | Local static feed (relative to the working directory; not in the Docker image) |
| `HITZE_STATIC_GEOSPHERE_URL` | – | Static feed URL; wins over the file when set |
| `PUSHOVER_APP_TOKEN`, `PUSHOVER_USER_KEY` | – | Enable Pushover admin reports |
| `PUSHOVER_DEVICE` | – | Limit reports to one device |
| `PUSHOVER_REPORTS_ENABLED` | `true` | Default for reports (develop UI override stored in Redis) |

Pushover: a summary after every run that attempted sends (v2 and legacy counted separately) and a
failure alert for failed runs/state writes, at most once per hour per error code. Reporting never
fails the run.

## Coolify setup

1. Application from this repository, **Base Directory** `backend`, build with the included
   `Dockerfile` (`npm ci`, production dependencies only at runtime, runs as `node`, `node` is PID 1).
2. Environment variables from `.env.example`; `REDIS_URL` = internal Coolify Redis URL.
3. Health check: `GET /health` (also in the image); use `GET /ready` where readiness is supported.
4. Stop grace period ≥ 10 s (graceful shutdown waits up to `HITZE_SHUTDOWN_TIMEOUT_MS` +
   `HITZE_SHUTDOWN_ABORT_GRACE_MS`, 9 s by default).
5. Scheduled task every 10 minutes (`*/10 * * * *`), as a command in the container:

```bash
sh -lc 'wget -qO- --header="Authorization: Bearer $CRON_SECRET" --post-data="" http://127.0.0.1:3000/cron/hitze >/dev/null'
```

`GET /cron/hitze` is not a trigger; only `POST` with the Bearer secret is.
