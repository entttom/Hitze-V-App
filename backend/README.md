# Hitze-V Backend (Coolify)

## Start local

```bash
npm install
npm run build
npm run start
```

Service listens on `PORT` (default `3000`).

## Endpoints

- `GET /health`
- `GET /cron/hitze`
- `POST /cron/hitze` (requires `Authorization: Bearer <CRON_SECRET>` when `CRON_SECRET` is set)
- `GET /test/push/ui` (Dev-only test UI for recipient selection from `gemliste_knz.xls`)
- `POST /test/push` (Dev-only manual test push to one municipality)
- `POST /test/push/bulk` (Dev-only manual test push to multiple municipalities)
- `POST /test/push/token` (Dev-only manual test push to one device token)

### curl test push

```bash
curl -X POST http://localhost:3000/test/push \
  -H "Content-Type: application/json" \
  -d '{
    "municipalityId": "90101",
    "title": "🧪 Testwarnung",
    "body": "Manuelle Testnachricht vom Backend"
  }'
```

## Required environment variables

- `FIREBASE_SERVICE_ACCOUNT` (JSON string)
- `REDIS_URL`

Optional:

- `HITZE_MIN_LEVEL` (default `2`)
- `CRON_SECRET`
- `develop` or `DEVELOP` (`true`/`1`/`yes`/`on` enables the test routes and test website)
- `PORT`

## Coolify setup

1. Create a new application from this repository.
2. Set **Base Directory** to `backend`.
3. Build using the included `Dockerfile`.
4. Configure environment variables from `.env.example`.
   - For Coolify Redis, use the internal Redis connection URL as `REDIS_URL`.
   - Set `CRON_SECRET` in the app environment variables (required for protected `POST /cron/hitze`).
5. Add a Coolify Scheduled Task.
   - If your scheduler supports URL/method/headers, call:
     - `POST https://<your-domain>/cron/hitze`
     - Header: `Authorization: Bearer <CRON_SECRET>`
   - If your scheduler only supports a command, use:

```bash
sh -lc 'wget -qO- --header="Authorization: Bearer $CRON_SECRET" --post-data="" http://127.0.0.1:3000/cron/hitze >/dev/null'
```

6. Recommended frequency: `*/10 * * * *` (every 10 minutes).
7. Use `GET /health` as health check.

Note: The `wget` command is usually more robust in Coolify scheduled tasks than a complex `node -e` one-liner because it avoids fragile shell escaping.
