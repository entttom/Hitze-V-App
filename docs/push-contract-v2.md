# HitzeV push contract v2

One push per municipality (GKZ) instead of one per municipality and language.
The backend sends structured data; each app renders title and body in the
user's in-app language from the shared copy file. This file is the contract
between `backend/`, `iOS/` and `Android/`; change it only together with all three.

## Naming rule

The app is called **HitzeV**. **Hitze-V** (with hyphen) is the abbreviation of the
Austrian Hitzeschutzverordnung and stays "Hitze-V" in every language wherever the
regulation is meant. Never use "Heat-V".

## Topics

| Topic | Who subscribes | Format |
|---|---|---|
| `warngebiet_v2_<GKZ>` | app versions with v2 support | v2 (this document) |
| `warngebiet_<GKZ>_<lang>` | legacy app versions (≤ iOS 1.2.4 / current Android) | legacy, `notification` block |
| `warngebiet_<GKZ>` | very old builds | not sent any more |

- `<GKZ>`: 5-digit Gemeindekennziffer as string, leading zeros kept, whitespace stripped
  (same normalisation as the backend: `String(value).replace(/\s+/g, "")`).
- v2 apps subscribe **only** to `warngebiet_v2_<GKZ>` and, once per GKZ (migration),
  unsubscribe from `warngebiet_<GKZ>` and from `warngebiet_<GKZ>_<lang>` for **all 25**
  language codes. Topic (un)subscription does not depend on notification permission.
- v2 apps re-subscribe all desired topics on every app start / token refresh
  (idempotent), so restores, reinstalls and token rotation heal themselves.
- Upgrade safety: until the app has written a v2 desired state once, launch/token
  resyncs must not tear anything down (no unsubscribe, no token deletion). Legacy topics
  are only dropped per GKZ after its v2 topic is confirmed.
- A worksite whose GKZ is not known yet must not block or shrink the sync: sync the known
  GKZs plus the GKZs already subscribed (additions happen, removals wait until every
  push-enabled worksite has a GKZ).
- Backend env `LEGACY_LANGUAGE_TOPICS` = `all` (default) | `de` | `off` controls the
  legacy fan-out during the transition.

## v2 message (FCM HTTP v1)

No top-level `notification` block (Android must receive it in `onMessageReceived`).

```jsonc
{
  "topic": "warngebiet_v2_60101",
  "data": {                       // all values are strings
    "v": "2",
    "type": "heat_warning",       // or "test"
    "event": "new",               // "new" | "escalated" | "updated" | "test"
    "gkz": "60101",
    "name": "Graz",               // whitespace-normalised municipality name
    "days": "[{\"date\":\"2026-07-07\",\"level\":3,\"start\":\"2026-07-07T08:00:00Z\",\"end\":\"2026-07-07T16:00:00Z\"}]",
    "warningIds": "123,124",
    "sentAt": "2026-07-07T06:30:00Z"
  },
  "android": {
    "priority": "high",
    "ttl": "<ms until latest day end, min 1 h, max 4 days>",
    "collapseKey": "hitze-60101"
  },
  "apns": {
    "headers": {
      "apns-push-type": "alert",
      "apns-priority": "10",
      "apns-collapse-id": "hitze-60101",
      "apns-expiration": "<unix seconds of latest day end>"
    },
    "payload": {
      "aps": {
        "alert": { "title": "<German fallback>", "body": "<German fallback>" },
        "sound": "default",
        "mutable-content": 1,
        "thread-id": "hitze-60101"
      }
    }
  }
}
```

### `days`

JSON array (string-encoded), sorted by `date`, **only today and/or tomorrow**
(Europe/Vienna) with level ≥ `HITZE_MIN_LEVEL`; 1 or 2 entries. Days further ahead
are pushed once they become "tomorrow".

- `date`: `YYYY-MM-DD`, calendar day in Europe/Vienna. A warning that overlaps several
  Vienna days contributes to **each** day it overlaps, with `start`/`end` clipped to that
  day (a continuation day starts at 00:00 Vienna, renders as "00:00–…" or `allDay`).
  A warning without `start` belongs to the days from today up to its `end`.
- `level`: integer 2–4 on the Hitze-V scale (GeoSphere `wlevel` + 1; 2 = yellow,
  3 = orange, 4 = red). Values > 4 are clamped to 4.
- `start` / `end`: ISO-8601 UTC, or `""` if unknown.

### Events (backend decision, per GKZ)

State per GKZ and date is stored after each successful send.

| Event | When |
|---|---|
| `escalated` | a day in `days` has a higher level than the highest level already **pushed** for that date — **always sent, never rate-limited** (a feed that flaps 3→2→3 does not re-push) |
| `new` | a day in `days` was not sent before |
| `updated` | same levels, but start/end of a day changed (at most once per GKZ and date per Vienna day) |
| — | downgrade, cancellation, or a day dropping out because it expired: no push. The day's state (incl. the highest pushed level) is kept until the day has passed, so a warning that disappears and comes back the same day at the same or a lower level is not pushed again |

Priority if several apply: `escalated` > `new` > `updated`. Quiet hours 20:00–06:00
Vienna defer pushes (state is **not** saved for deferred keys).

## Rendering (identical on backend, iOS, Android)

Copy file: `backend/assets/push-copy.json` (single source of truth; apps bundle a copy
generated/copied at build time). Language = the app's in-app language, resolved to one
of the 25 codes; unknown → `fallbackLanguage` (`en`). The backend renders the iOS
fallback alert in `de` and legacy pushes in the topic's language.

All times are shown in **Europe/Vienna**, regardless of the device time zone, as `HH:mm`
(24 h, zero-padded) in every language.

1. `now` = current instant (device) / send instant (backend). `today` = Vienna date of
   `now`, `tomorrow` = today + 1.
2. `dayLabel(date)`: `dayToday` if today, `dayTomorrow` if tomorrow, else
   `weekdays[isoWeekday - 1]` (Monday first).
3. `time(day)`:
   - `s` = Vienna `HH:mm` of `start`; if `start` is empty or ≤ 00:00 of `date` → `"00:00"`.
   - `e` = Vienna `HH:mm` of `end`; if `end` is empty or ≥ 00:00 of `date + 1` → `"24:00"`.
   - if `s == "00:00"` and `e == "24:00"` → `allDay`; else `timeRange` with `{start}`=`s`, `{end}`=`e`.
4. `levelName(level)` = `levelNames["<level>"]`.
5. Title: `new` → `title`, `escalated` → `titleEscalated`, `updated` → `titleUpdated`,
   `test` → `titleTest`.
6. Body:
   - `test` → `bodyTest` (`{name}`).
   - 2 entries in `days` (always today + tomorrow) and event ≠ `updated` →
     `bodyTodayTomorrow` with `{name}`, `{level1}`, `{levelName1}`, `{time1}`,
     `{level2}`, `{levelName2}`, `{time2}`.
   - otherwise use `days[0]` with `bodyNew` / `bodyEscalated` / `bodyUpdated` and
     `{day}`, `{name}`, `{level}`, `{levelName}`, `{time}`.
7. Placeholders are replaced literally; no other formatting.

Golden test vectors: `backend/assets/push-copy-examples.json`. All three components
must reproduce them exactly in their unit tests.

## Display

- iOS: Notification Service Extension rewrites `title`/`body` with the rendered text
  (language from the App Group `group.org.entner.HitzeV`, key `dashboard.language`).
  If rendering fails, the German fallback alert is shown.
- Android: `onMessageReceived` renders and posts on channel `heat_warning_alerts`,
  tag `hitze-<GKZ>`, id `1` (a newer push replaces the older one for the same GKZ),
  visibility public, no `CATEGORY_ALARM`.
- Tap: both apps open the dashboard and scroll to / highlight the worksite(s) with this
  `gkz` (iOS: `userInfo["gkz"]`; Android: intent extra `org.entner.HitzeV.extra.GKZ`).
