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
5. Add a Coolify scheduler to call:
   - `POST https://<your-domain>/cron/hitze`
   - Header: `Authorization: Bearer <CRON_SECRET>`
6. Use `GET /health` as health check.
