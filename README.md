# Hitze-V

Hitze-V ist eine mobile Anwendung zur Beobachtung hitze- und wetterbezogener Risiken an Arbeitsorten in Oesterreich. Das Repository enthaelt die nativen Mobile-Clients fuer Android und iOS sowie ein separates Backend, das GeoSphere-Warnungen einsammelt, veraenderte Warnlagen erkennt und Push-Benachrichtigungen ueber Firebase Cloud Messaging an abonnierte Gemeinden verschickt.

Die App richtet sich auf zwei Aufgaben aus:

- Arbeitsorte erfassen und deren aktuelle Gefaehrdungslage sichtbar machen.
- Push-Warnungen fuer jene Gemeinden empfangen, die aus den hinterlegten Standorten abgeleitet werden.

## Architektur im Ueberblick

Das Projekt ist kein klassisches Monorepo mit gemeinsamer Build-Pipeline, sondern besteht aus drei eigenstaendigen Teilen:

- `Android/`: native Android-App mit Kotlin, Jetpack Compose und Firebase Messaging.
- `iOS/Hitze-V/`: native iOS-App mit SwiftUI und Firebase Messaging.
- `backend/`: Node.js/TypeScript-Service fuer Cron-Ausfuehrung, Redis-Zustand und Push-Versand.

Die Daten- und Ereigniskette sieht vereinfacht so aus:

1. Die mobile App speichert Arbeitsorte lokal auf dem Geraet.
2. Fuer jeden Standort wird ueber GeoSphere die zustaendige Gemeinde ermittelt.
3. Die App abonniert das Firebase-Topic `warngebiet_<gemeindenummer>`.
4. Das Backend ruft periodisch GeoSphere-Warnstatusdaten ab.
5. Aendert sich die Warnlage einer Gemeinde, versendet das Backend eine Push-Nachricht an das passende Topic.
6. Die mobilen Clients empfangen die Nachricht und zeigen die Warnung systemseitig an.

## Funktionsumfang

### Mobile Apps

- Verwaltung mehrerer Arbeitsorte.
- Ermittlung der Gemeinde zu einem Standort anhand von Koordinaten.
- Anzeige der aktuellen Hitzelage pro Arbeitsort.
- Darstellung einer Kurzfristvorschau fuer die naechsten vier Tage.
- Einbindung von UV-Index und gefuehlter Temperatur ueber Open-Meteo.
- Lokale Speicherung von App-Daten und Topic-Abonnements.
- Push-Benachrichtigungen ueber Firebase Cloud Messaging.

### Backend

- Abruf und Normalisierung von Warnungen aus GeoSphere.
- Filterung nach Mindestwarnstufe ueber `HITZE_MIN_LEVEL`.
- Aggregation je Gemeinde und Warnungsart.
- Signaturvergleich ueber Redis, damit nur echte Aenderungen versendet werden.
- Tagesbezogene Versandbegrenzung, solange Start- und Endzeit der Warnung unveraendert bleiben.
- Aufraeumen veralteter Redis-Metadaten und entfallener Warnzustaende.
- Entwicklungsrouten fuer manuellen Testversand.

## Verzeichnisstruktur

```text
Hitze-V-App/
├── Android/                 Android-App
├── backend/                 Cron- und Push-Backend
│   ├── api/cron/hitze.ts    zentrale Warnlogik
│   ├── src/server.ts        HTTP-Server und Routen
│   ├── .env.example         Beispiel fuer Backend-Konfiguration
│   └── gemliste_knz.xls     Gemeindeliste fuer Testoberflaeche
└── iOS/Hitze-V/             iOS-App und Xcode-Projekt
```

## Externe Dienste und Datenquellen

Der produktive Betrieb haengt von mehreren externen Systemen ab:

- GeoSphere Austria:
  - Warnstatus und Warnungsdetails fuer Gemeinden
  - Standortaufloesung von Koordinaten zu Gemeinden
- Open-Meteo:
  - UV-Index und gefuehlte Temperatur fuer die App-Ansicht
- Firebase Cloud Messaging:
  - Device-Registrierung
  - Topic-Abonnements
  - eigentlicher Push-Versand
- Redis:
  - Speicherung der zuletzt bekannten Warnsignaturen
  - Speicherung von Versandmetadaten zur Rate-Limit-Logik

Ohne Redis sendet das Backend bewusst keine Warnungen. Die Cron-Logik arbeitet in diesem Fall fail-closed, um Mehrfach- oder Fehlversand zu vermeiden.

## Voraussetzungen

### Allgemein

- Git
- Zugang zu einem Firebase-Projekt mit aktivem Cloud Messaging
- Netzwerkzugriff auf GeoSphere, Open-Meteo und Firebase

### Backend

- Node.js in einer aktuellen LTS-Version
- `npm`
- Redis-Instanz

### Android

- Android Studio
- Android SDK mit `compileSdk 36`
- Java 11
- Firebase-Konfiguration als `google-services.json`

### iOS

- aktuelles Xcode
- CocoaPods wird aktuell nicht verwendet
- Firebase-Konfiguration ueber `GoogleService-Info.plist`

## Lokales Setup

### 1. Repository klonen

```bash
git clone <repo-url>
cd Hitze-V-App
```

### 2. Backend einrichten

```bash
cd backend
npm install
cp .env.example .env
```

Danach muessen die Werte in `.env` an eure Umgebung angepasst werden.

Wichtige Variablen:

- `PORT`: HTTP-Port des Services, lokal standardmaessig `3000`
- `CRON_SECRET`: Bearer-Token fuer den geschuetzten Cron-POST-Endpunkt
- `HITZE_MIN_LEVEL`: Mindestwarnstufe fuer den Versand, Standard `2`
- `HITZE_USE_STATIC_GEOSPHERE_RESPONSE`: aktiviert fuer Tests eine statische Antwort statt der GeoSphere-API
- `HITZE_STATIC_GEOSPHERE_URL`: optionale URL fuer die statische Testantwort, zum Beispiel `https://raw.githubusercontent.com/entttom/Hitze-V-App/main/backend/example_response.json`; ohne Wert wird lokal `backend/example_response.json` geladen
- `FIREBASE_SERVICE_ACCOUNT`: kompletter Firebase-Service-Account als JSON-String
- `REDIS_URL`: Verbindungszeichenfolge zur Redis-Instanz
- `DEVELOP` oder `develop`: aktiviert lokale Test-Endpunkte und Testoberflaeche

Beispiel:

```env
PORT=3000
CRON_SECRET=replace-with-strong-secret
HITZE_MIN_LEVEL=2
HITZE_USE_STATIC_GEOSPHERE_RESPONSE=false
HITZE_STATIC_GEOSPHERE_URL=https://raw.githubusercontent.com/entttom/Hitze-V-App/main/backend/example_response.json
FIREBASE_SERVICE_ACCOUNT={"type":"service_account","project_id":"...","private_key":"-----BEGIN PRIVATE KEY-----\\n...\\n-----END PRIVATE KEY-----\\n","client_email":"..."}
REDIS_URL=redis://default:<password>@<host>:6379
DEVELOP=true
```

### 3. Backend starten

Fuer Entwicklung:

```bash
cd backend
npm run dev
```

Fuer einen Produktionslauf lokal:

```bash
cd backend
npm run build
npm run start
```

Verfuegbare Scripts im Backend:

- `npm run dev`: startet den Service mit `tsx watch`
- `npm run build`: kompiliert TypeScript nach `backend/dist`
- `npm run start`: startet die gebaute Server-Version

### 4. Android-App einrichten

Das Android-Projekt liegt in `Android/` und verwendet Gradle Kotlin DSL.

Wichtige Hinweise:

- Die Datei `google-services.json` ist aktuell nicht im Repository enthalten und muss lokal in `Android/app/` hinterlegt werden.
- Push-Benachrichtigungen benoetigen ein korrekt konfiguriertes Firebase-Projekt.
- Die App verwendet `minSdk 26`, `targetSdk 36` und Jetpack Compose.

Debug-Build ueber die Kommandozeile:

```bash
cd Android
./gradlew :app:assembleDebug
```

Alternativ kann das Projekt direkt in Android Studio geoeffnet werden.

### 5. iOS-App einrichten

Das Xcode-Projekt liegt unter `iOS/Hitze-V/Hitze-V.xcodeproj`.

Wichtige Hinweise:

- `GoogleService-Info.plist` ist im iOS-Projekt vorhanden und wird fuer Firebase verwendet.
- Die App ist in SwiftUI umgesetzt.
- Fuer lokale Tests wird ein Apple-Developer-Setup mit passender Signing-Konfiguration benoetigt.

Typischer Ablauf:

1. `iOS/Hitze-V/Hitze-V.xcodeproj` in Xcode oeffnen.
2. Team und Signing pruefen.
3. Gewuenschtes Simulator- oder Geraeteziel waehlen.
4. App starten.

## Backend-Endpunkte

Der HTTP-Server wird in `backend/src/server.ts` definiert.

Regulaere Endpunkte:

- `GET /health`
  - einfacher Health-Check
- `GET /cron/hitze`
  - fuehrt den Warnlauf direkt aus
  - eignet sich fuer manuelle lokale Verifikation
- `POST /cron/hitze`
  - fuehrt denselben Warnlauf aus
  - erwartet `Authorization: Bearer <CRON_SECRET>`, wenn `CRON_SECRET` gesetzt ist

Entwicklungs- und Test-Endpunkte, nur mit `DEVELOP=true`:

- `GET /test/push/ui`
  - kleine Testoberflaeche fuer den manuellen Push-Versand
- `POST /test/push`
  - sendet eine Testnachricht an genau eine Gemeinde
- `POST /test/push/bulk`
  - sendet Testnachrichten an mehrere Gemeinden
- `POST /test/push/token`
  - sendet eine Testnachricht direkt an ein einzelnes Geraetetoken

Beispiel fuer einen manuellen Test:

```bash
curl -X POST http://localhost:3000/test/push \
  -H "Content-Type: application/json" \
  -d '{
    "municipalityId": "90101",
    "title": "Testwarnung",
    "body": "Manuelle Testnachricht vom Backend"
  }'
```

## Wie der Cron-Lauf arbeitet

Die Kernlogik liegt in `backend/api/cron/hitze.ts`.

Der Ablauf in Kurzform:

1. GeoSphere-Warnungen werden geladen und auf relevante Warnungen reduziert.
2. Warnungen unterhalb von `HITZE_MIN_LEVEL` werden verworfen.
3. Die verbleibenden Warnungen werden je Gemeinde und Warnungsart aggregiert.
4. Pro Aggregat wird eine Signatur berechnet.
5. Die Signatur wird mit dem zuletzt in Redis gespeicherten Zustand verglichen.
6. Nur geaenderte Zustaende kommen fuer einen Versand in Frage.
7. Wurde fuer denselben Zustand am selben Tag bereits eine Nachricht gesendet und haben sich Start- oder Endzeit nicht geaendert, wird der Versand unterdrueckt.
8. Erfolgreich versendete Zustaende werden mit neuer Signatur und Versandmetadaten in Redis abgelegt.
9. Entfallene Warnzustaende werden aus Redis entfernt.

Die Antwort des Cron-Endpunkts enthaelt unter anderem:

- `processedWarnings`
- `affectedMunicipalities`
- `sent`
- `skippedUnchanged`
- `skippedRateLimited`
- `cleared`
- `failed`
- `failedMunicipalities`

Diese Felder sind die wichtigste Grundlage fuer Monitoring und Fehlersuche.

## Topic-Strategie fuer Push-Benachrichtigungen

Sowohl Android als auch iOS verwenden das Topic-Schema:

```text
warngebiet_<gemeindenummer>
```

Beispiel:

```text
warngebiet_90101
```

Die Clients ermitteln anhand von Koordinaten die zustaendige Gemeinde und synchronisieren daraus ihre Topic-Abonnements. Wenn mehrere Arbeitsorte hinterlegt sind, ist die App auf mehreren Gemeinde-Topics gleichzeitig registriert.

## Datenquellen in den Mobile-Clients

Die Apps nutzen externe APIs nicht nur fuer Push, sondern auch fuer die Darstellung:

- GeoSphere:
  - Ermittlung der Gemeinde zu einer Koordinate
  - Auslesen aktiver Warnungen fuer die Standortbewertung
- Open-Meteo:
  - Tageswerte fuer UV-Index-Maximum
  - Tageswerte fuer maximale gefuehlte Temperatur

Die mobile Anzeige ist damit nicht von einem eigenen App-Backend fuer Dashboards abhaengig. Das Backend wird primaer fuer den Push-Prozess benoetigt.

## Deployment des Backends mit Coolify

Das Backend ist bereits auf einen Betrieb in Coolify ausgelegt.

Empfohlener Ablauf:

1. In Coolify eine neue Anwendung aus diesem Repository anlegen.
2. Als Base Directory `backend` setzen.
3. Das vorhandene `Dockerfile` des Backend-Verzeichnisses verwenden.
4. Alle benoetigten Umgebungsvariablen aus `backend/.env.example` hinterlegen.
5. Fuer `REDIS_URL` die interne Redis-URL aus Coolify verwenden.
6. In den Environment-Variablen der App `CRON_SECRET` als eigenes Secret setzen.
7. Einen Scheduled Task fuer den Cronlauf anlegen (in vielen Coolify-Setups command-basiert statt URL-basiert):

   ```bash
   sh -lc 'wget -qO- --header="Authorization: Bearer $CRON_SECRET" --post-data="" http://127.0.0.1:3000/cron/hitze >/dev/null'
   ```

8. Als Frequenz z. B. `*/10 * * * *` (alle 10 Minuten) setzen.
9. `GET /health` als Health-Check konfigurieren.

Hinweis:

- Falls dein Coolify-Dialog URL/Methode/Header anbietet, kannst du alternativ direkt `POST https://<domain>/cron/hitze` mit Header `Authorization: Bearer <CRON_SECRET>` verwenden.
- Der `wget`-Befehl ist in Coolify oft robuster als komplexe `node -e`-Einzeiler, weil weniger Escaping/Quoting noetig ist.

## Typische Entwicklungs-Workflows

### Mobile Oberflaeche testen

- Android oder iOS lokal starten
- Arbeitsorte anlegen
- pruefen, ob Gemeinde und Risikostufe korrekt aufgeloest werden
- bei aktiviertem Firebase-Setup die Topic-Synchronisierung validieren

### Push-Lauf testen

1. Backend lokal mit `DEVELOP=true` starten.
2. Sicherstellen, dass Redis und Firebase erreichbar sind.
3. `GET /test/push/ui` oder die `POST /test/push`-Route verwenden.
4. Anschliessend `GET /cron/hitze` oder `POST /cron/hitze` ausfuehren.
5. Rueckgabedaten und Server-Logs auf `sent`, `failed` und `skippedRateLimited` pruefen.

### Warnlogik pruefen

- bei fehlendem Versand zunaechst `REDIS_URL`, `FIREBASE_SERVICE_ACCOUNT` und `HITZE_MIN_LEVEL` kontrollieren
- pruefen, ob GeoSphere gerade relevante Warnungen liefert
- beachten, dass unveraenderte Zustaende bewusst nicht erneut verschickt werden

## Bekannte Besonderheiten

- Im Repository liegt aktuell keine Root-Build-Pipeline ueber alle Plattformen hinweg vor.
- Das Backend besitzt derzeit keine dedizierten automatisierten Tests im Repository.
- Android und iOS lesen Wetter- und Warninformationen direkt von externen APIs.
- Der Versand ist zustandsbehaftet und haengt damit funktional von Redis ab.
- Die Entwicklungs-Testoberflaeche im Backend wird nur aktiviert, wenn `DEVELOP` beziehungsweise `develop` gesetzt ist.

## Troubleshooting

### Es kommen keine Push-Nachrichten an

- Firebase-Konfiguration der App pruefen
- sicherstellen, dass das richtige Topic abonniert wurde
- Backend-Response auf `failedMunicipalities` pruefen
- kontrollieren, ob Redis den Zustand bereits als unveraendert einstuft

### Der Cron-Endpunkt liefert Fehler

- `FIREBASE_SERVICE_ACCOUNT` auf gueltiges JSON pruefen
- `REDIS_URL` und Redis-Erreichbarkeit pruefen
- Netzwerkzugriff auf GeoSphere kontrollieren
- bei `401` den `Authorization`-Header mit `CRON_SECRET` abgleichen

### Eine Gemeinde wird nicht korrekt erkannt

- Standortkoordinaten pruefen
- Antwort der GeoSphere-API verifizieren
- beachten, dass die Topic-Zuordnung ausschliesslich aus der aufgeloesten Gemeindenummer entsteht

## Weiterfuehrende Dateien

- `backend/README.md`: kurze, backend-spezifische Betriebsnotizen
- `backend/.env.example`: Referenz fuer benoetigte Umgebungsvariablen
- `backend/api/cron/hitze.ts`: zentrale Warn- und Versandlogik
- `backend/src/server.ts`: HTTP-Routen und Serverstart

## Lizenz und Betriebshinweis

Dieses Repository enthaelt operative Konfiguration fuer Mobile-Apps und ein produktionsnahes Push-Backend. Vor einem produktiven Einsatz sollten insbesondere Firebase-Projektgrenzen, Signierung, Secrets-Management, Redis-Verfuegbarkeit und Monitoring sauber geklaert sein.
