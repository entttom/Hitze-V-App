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
- `POST /test/push` (manual test push; currently no extra auth)

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
