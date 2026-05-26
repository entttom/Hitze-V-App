"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const node_fs_1 = require("node:fs");
const node_path_1 = __importDefault(require("node:path"));
const express_1 = __importDefault(require("express"));
const env_1 = require("../api/cron/env");
const pushover_1 = require("../api/cron/pushover");
const hitze_1 = require("../api/cron/hitze");
const app = (0, express_1.default)();
app.use(express_1.default.json());
const port = Number(process.env.PORT ?? "3000");
const cronSecret = process.env.CRON_SECRET?.trim();
const developMode = (0, env_1.isEnvFlagEnabled)(process.env.develop) || (0, env_1.isEnvFlagEnabled)(process.env.DEVELOP);
const POLITICAL_DISTRICTS_GEOJSON_FILE = "political-districts-20260101.geojson";
const MUNICIPALITIES_GEOJSON_FILE = "municipalities-20260101.geojson";
let cachedPoliticalDistrictFeatures = null;
let cachedMunicipalityFeatures = null;
if (!cronSecret) {
    console.error([
        "",
        "================================================================",
        "  FATAL: CRON_SECRET is missing or empty.",
        "================================================================",
        "",
        "  Without CRON_SECRET, the /cron/hitze endpoint cannot",
        "  authenticate cron triggers and would be publicly callable.",
        "  The server refuses to start fail-open.",
        "",
        "  Fix:",
        "    1. Generate a strong random value:",
        "         openssl rand -hex 32",
        "    2. Set CRON_SECRET in your environment.",
        "       (Coolify: Resources -> Backend -> Environment Variables)",
        "    3. Restart the container.",
        "",
        "================================================================",
        "",
    ].join("\n"));
    process.exit(1);
}
function isAuthorized(req) {
    const header = req.header("authorization") ?? "";
    return header === `Bearer ${cronSecret}`;
}
function mapGeoJsonPaths(fileName) {
    return [
        node_path_1.default.resolve(__dirname, "..", "assets", fileName),
        node_path_1.default.resolve(process.cwd(), "dist", "assets", fileName),
        node_path_1.default.resolve(process.cwd(), "assets", fileName),
    ];
}
function loadMapFeatures(fileName, cacheName) {
    const cached = cacheName === "districts" ? cachedPoliticalDistrictFeatures : cachedMunicipalityFeatures;
    if (cached) {
        return cached;
    }
    for (const filePath of mapGeoJsonPaths(fileName)) {
        if (!(0, node_fs_1.existsSync)(filePath)) {
            continue;
        }
        try {
            const payload = JSON.parse((0, node_fs_1.readFileSync)(filePath, "utf8"));
            const features = payload &&
                typeof payload === "object" &&
                Array.isArray(payload.features)
                ? payload.features
                : [];
            const parsedFeatures = [];
            for (const feature of features) {
                if (!feature || typeof feature !== "object") {
                    continue;
                }
                const record = feature;
                const id = String(record.properties?.id ?? record.properties?.districtId ?? record.id ?? "").trim();
                const name = String(record.properties?.name ?? "").trim();
                if (!id || !name || !record.geometry) {
                    continue;
                }
                parsedFeatures.push({
                    id,
                    name,
                    geometry: record.geometry,
                });
            }
            if (cacheName === "districts") {
                cachedPoliticalDistrictFeatures = parsedFeatures;
            }
            else {
                cachedMunicipalityFeatures = parsedFeatures;
            }
            return parsedFeatures;
        }
        catch (error) {
            console.warn(`${cacheName}_geojson_load_failed`, {
                filePath,
                error: error instanceof Error ? error.message : String(error),
            });
        }
    }
    if (cacheName === "districts") {
        cachedPoliticalDistrictFeatures = [];
        return cachedPoliticalDistrictFeatures;
    }
    cachedMunicipalityFeatures = [];
    return cachedMunicipalityFeatures;
}
function loadPoliticalDistrictFeatures() {
    return loadMapFeatures(POLITICAL_DISTRICTS_GEOJSON_FILE, "districts");
}
function loadMunicipalityFeatures() {
    return loadMapFeatures(MUNICIPALITIES_GEOJSON_FILE, "municipalities");
}
function parseLanguageFromBody(rawValue) {
    if (rawValue === undefined || rawValue === null) {
        return { ok: true, value: undefined };
    }
    if (typeof rawValue !== "string") {
        return { ok: false, message: "lang must be a string when provided." };
    }
    const trimmed = rawValue.trim();
    if (!trimmed) {
        return { ok: true, value: undefined };
    }
    const parsed = (0, hitze_1.parseSupportedPushLanguage)(trimmed);
    if (!parsed) {
        return { ok: false, message: `Unsupported lang '${trimmed}'.` };
    }
    return { ok: true, value: parsed };
}
app.get("/", (_req, res) => {
    res.setHeader("Cache-Control", "no-store, no-cache, must-revalidate, proxy-revalidate");
    res.setHeader("Pragma", "no-cache");
    res.setHeader("Expires", "0");
    res.setHeader("Surrogate-Control", "no-store");
    res.status(200).type("html").send(renderIndexPage(developMode));
});
app.get("/health", (_req, res) => {
    res.status(200).json({ ok: true });
});
app.post("/cron/hitze", async (req, res) => {
    if (!isAuthorized(req)) {
        res.status(401).json({
            errorCode: "UNAUTHORIZED",
            message: "Missing or invalid Authorization header.",
        });
        return;
    }
    const result = await (0, hitze_1.executeHitzeCron)(req.method);
    if (result.headers) {
        for (const [key, value] of Object.entries(result.headers)) {
            res.setHeader(key, value);
        }
    }
    res.status(result.status).json(result.body);
});
const NAV_CSS = `
      .topnav {
        display: flex;
        flex-wrap: wrap;
        gap: 8px;
        margin-bottom: 22px;
      }

      .topnav a {
        display: inline-flex;
        align-items: center;
        padding: 8px 16px;
        border-radius: 999px;
        border: 1px solid var(--line);
        background: var(--panel-strong);
        color: var(--text);
        font-size: 0.92rem;
        font-weight: 600;
        text-decoration: none;
        transition: background 0.15s ease, color 0.15s ease;
      }

      .topnav a:hover {
        background: #fff7e6;
      }

      .topnav a[aria-current="page"] {
        background: linear-gradient(135deg, var(--accent), var(--accent-dark));
        border-color: transparent;
        color: white;
      }
`;
const NAV_LINKS = [
    { href: "/", label: "← Übersicht" },
    { href: "/test/push/ui", label: "Testversand" },
    { href: "/test/warnings/ui", label: "Aktuelle Warnungen" },
    { href: "/test/pushover/ui", label: "Pushover" },
];
function renderTopNav(activeHref) {
    return `<nav class="topnav">${NAV_LINKS.map((link) => {
        const aria = link.href === activeHref ? ' aria-current="page"' : "";
        return `<a href="${link.href}"${aria}>${link.label}</a>`;
    }).join("")}</nav>`;
}
function renderIndexPage(developMode) {
    const developCards = developMode
        ? `
          <a class="card" href="/test/push/ui">
            <h2>Testversand</h2>
            <p>Manuelle Push-Notifications an einzelne oder mehrere Gemeinden senden — zum Testen von Titel, Text und Sprache.</p>
            <span class="arrow">/test/push/ui →</span>
          </a>

          <a class="card" href="/test/warnings/ui">
            <h2>Aktuelle Warnungen</h2>
            <p>Live-Snapshot der GeoSphere-API: betroffene Gemeinden, Warnstufen, Zeiträume. Kein Push, kein Redis-Write.</p>
            <span class="arrow">/test/warnings/ui →</span>
          </a>

          <a class="card" href="/test/pushover/ui">
            <h2>Pushover-Reports</h2>
            <p>Backend-Reports für versendete Hitzewarnungen anzeigen und ein- oder ausschalten.</p>
            <span class="arrow">/test/pushover/ui →</span>
          </a>`
        : `
          <div class="card card--info">
            <h2>Develop-Seiten deaktiviert</h2>
            <p>Testversand und Warnungs-Snapshot sind nur verfügbar, wenn beim Start <code>develop=true</code> (oder <code>DEVELOP=true</code>) gesetzt ist.</p>
          </div>`;
    return `<!doctype html>
<html lang="de">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>Hitze-V Backend</title>
    <style>
      :root {
        color-scheme: light;
        --bg: #f4efe7;
        --panel: #fffaf3;
        --panel-strong: #fff4df;
        --line: #d8cbb9;
        --text: #2b241c;
        --muted: #6e6255;
        --accent: #c74b2a;
        --accent-dark: #8f2f17;
      }

      * { box-sizing: border-box; }

      body {
        margin: 0;
        font-family: "Avenir Next", "Segoe UI", sans-serif;
        background:
          radial-gradient(circle at top right, rgba(199, 75, 42, 0.15), transparent 30%),
          linear-gradient(180deg, #f9f4ec 0%, var(--bg) 100%);
        color: var(--text);
        min-height: 100vh;
      }

      main {
        max-width: 1160px;
        margin: 0 auto;
        padding: 32px 20px 40px;
      }

      h1 {
        margin: 0 0 12px;
        font-size: clamp(2rem, 4vw, 3.4rem);
        line-height: 0.95;
        letter-spacing: -0.04em;
      }

      .subtitle {
        margin: 0 0 28px;
        color: var(--muted);
        font-size: 1rem;
      }

      .mode-pill {
        display: inline-flex;
        align-items: center;
        gap: 6px;
        padding: 4px 12px;
        border-radius: 999px;
        font-size: 0.78rem;
        font-weight: 700;
        letter-spacing: 0.04em;
        text-transform: uppercase;
        margin-left: 8px;
      }

      .mode-pill.on {
        background: #edf8ee;
        color: #2c6b3a;
        border: 1px solid #8ac49a;
      }

      .mode-pill.off {
        background: var(--panel-strong);
        color: var(--muted);
        border: 1px solid var(--line);
      }

      .grid {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(260px, 1fr));
        gap: 16px;
      }

      .card {
        display: block;
        background: rgba(255, 250, 243, 0.94);
        border: 1px solid rgba(216, 203, 185, 0.85);
        border-radius: 24px;
        box-shadow: 0 14px 40px rgba(82, 57, 30, 0.08);
        padding: 22px;
        text-decoration: none;
        color: var(--text);
        transition: transform 0.15s ease, box-shadow 0.15s ease;
      }

      a.card:hover {
        transform: translateY(-2px);
        box-shadow: 0 18px 48px rgba(82, 57, 30, 0.14);
      }

      .card h2 {
        margin: 0 0 8px;
        font-size: 1.2rem;
      }

      .card p {
        margin: 0 0 12px;
        color: var(--muted);
        font-size: 0.95rem;
      }

      .card .arrow {
        font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
        font-size: 0.82rem;
        color: var(--accent-dark);
      }

      .card--info {
        background: var(--panel-strong);
      }

      .card--muted {
        opacity: 0.95;
      }

      code {
        font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
        font-size: 0.88em;
        background: rgba(199, 75, 42, 0.08);
        padding: 1px 6px;
        border-radius: 6px;
      }
${NAV_CSS}
    </style>
  </head>
  <body>
    <main>
      ${renderTopNav("/")}
      <h1>Hitze-V Backend<span class="mode-pill ${developMode ? "on" : "off"}">${developMode ? "develop on" : "develop off"}</span></h1>
      <p class="subtitle">Übersicht aller verfügbaren Oberflächen und Endpunkte.</p>

      <div class="grid">
${developCards}

          <div class="card card--muted">
            <h2>Health-Check</h2>
            <p>JSON-Endpoint für Uptime-Monitoring.</p>
            <span class="arrow"><a href="/health">GET /health →</a></span>
          </div>

          <div class="card card--muted">
            <h2>Cron-Trigger</h2>
            <p>Stündlicher Auslöser für die Hitze-Auswertung. <code>POST</code> mit <code>Authorization: Bearer &lt;CRON_SECRET&gt;</code>.</p>
            <span class="arrow">POST /cron/hitze</span>
          </div>
      </div>
    </main>
  </body>
</html>`;
}
function renderPushoverSettingsPage() {
    return `<!doctype html>
<html lang="de">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>Hitze-V · Pushover</title>
    <style>
      :root {
        color-scheme: light;
        --bg: #f4efe7;
        --panel: #fffaf3;
        --panel-strong: #fff4df;
        --line: #d8cbb9;
        --text: #2b241c;
        --muted: #6e6255;
        --accent: #c74b2a;
        --accent-dark: #8f2f17;
        --ok: #2c6b3a;
        --danger: #8f2f17;
      }

      * { box-sizing: border-box; }

      body {
        margin: 0;
        font-family: "Avenir Next", "Segoe UI", sans-serif;
        background: linear-gradient(180deg, #f9f4ec 0%, var(--bg) 100%);
        color: var(--text);
        min-height: 100vh;
      }

      main {
        max-width: 820px;
        margin: 0 auto;
        padding: 32px 20px 40px;
      }

      h1 {
        margin: 0 0 10px;
        font-size: clamp(2rem, 4vw, 3rem);
        line-height: 1;
      }

      .subtitle {
        margin: 0 0 24px;
        color: var(--muted);
      }

      .panel {
        background: rgba(255, 250, 243, 0.96);
        border: 1px solid rgba(216, 203, 185, 0.9);
        border-radius: 22px;
        box-shadow: 0 14px 40px rgba(82, 57, 30, 0.08);
        padding: 22px;
      }

      .status-grid {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(170px, 1fr));
        gap: 12px;
        margin: 18px 0;
      }

      .status-item {
        border: 1px solid var(--line);
        border-radius: 16px;
        background: #fffdf9;
        padding: 14px;
      }

      .status-item span {
        display: block;
        color: var(--muted);
        font-size: 0.8rem;
        margin-bottom: 4px;
      }

      .status-item strong {
        font-size: 1rem;
      }

      .switch-row {
        display: flex;
        align-items: center;
        justify-content: space-between;
        gap: 16px;
        border-top: 1px solid var(--line);
        padding-top: 18px;
        margin-top: 18px;
      }

      .switch-copy strong {
        display: block;
        margin-bottom: 4px;
      }

      .switch-copy span,
      .message {
        color: var(--muted);
        font-size: 0.92rem;
      }

      .toggle {
        position: relative;
        display: inline-flex;
        width: 66px;
        height: 38px;
        flex: 0 0 auto;
      }

      .toggle input {
        opacity: 0;
        width: 0;
        height: 0;
      }

      .slider {
        position: absolute;
        cursor: pointer;
        inset: 0;
        background: #d8cbb9;
        border-radius: 999px;
        transition: background 0.18s ease;
      }

      .slider:before {
        content: "";
        position: absolute;
        height: 30px;
        width: 30px;
        left: 4px;
        bottom: 4px;
        background: white;
        border-radius: 50%;
        box-shadow: 0 3px 10px rgba(52, 38, 22, 0.25);
        transition: transform 0.18s ease;
      }

      .toggle input:checked + .slider {
        background: var(--ok);
      }

      .toggle input:checked + .slider:before {
        transform: translateX(28px);
      }

      .badge {
        display: inline-flex;
        align-items: center;
        padding: 5px 10px;
        border-radius: 999px;
        font-size: 0.8rem;
        font-weight: 700;
        background: var(--panel-strong);
        border: 1px solid var(--line);
      }

      .badge.on {
        background: #edf8ee;
        border-color: #8ac49a;
        color: var(--ok);
      }

      .badge.off {
        background: #fff1e9;
        border-color: #e1a185;
        color: var(--danger);
      }

      button {
        border: 0;
        border-radius: 999px;
        padding: 10px 14px;
        background: var(--panel-strong);
        color: var(--text);
        font: inherit;
        font-weight: 700;
        cursor: pointer;
      }

      button:hover {
        background: #fff7e6;
      }

      button:disabled,
      .toggle input:disabled + .slider {
        cursor: not-allowed;
        opacity: 0.55;
      }

      .actions {
        display: flex;
        align-items: center;
        justify-content: space-between;
        gap: 12px;
        margin-top: 18px;
      }

      .message.error {
        color: var(--danger);
      }

${NAV_CSS}
    </style>
  </head>
  <body>
    <main>
      ${renderTopNav("/test/pushover/ui")}
      <h1>Pushover-Reports</h1>
      <p class="subtitle">Steuert nur die Pushover-Zusammenfassung nach versendeten Hitzewarnungen. Die Firebase-Pushes an App-Nutzer bleiben unverändert aktiv.</p>

      <section class="panel">
        <span id="stateBadge" class="badge">Status wird geladen</span>

        <div class="status-grid">
          <div class="status-item">
            <span>Konfiguration</span>
            <strong id="configuredValue">-</strong>
          </div>
          <div class="status-item">
            <span>Speicherung</span>
            <strong id="persistenceValue">-</strong>
          </div>
          <div class="status-item">
            <span>Default</span>
            <strong id="defaultValue">-</strong>
          </div>
        </div>

        <div class="switch-row">
          <div class="switch-copy">
            <strong>Hitzewarnungs-Reports per Pushover senden</strong>
            <span>Beim Ausschalten werden Cron-Läufe weiter ausgeführt, aber ohne Pushover-Report.</span>
          </div>
          <label class="toggle" aria-label="Pushover-Reports aktivieren">
            <input id="enabledToggle" type="checkbox" />
            <span class="slider"></span>
          </label>
        </div>

        <div class="actions">
          <p id="message" class="message"></p>
          <button id="reloadButton" type="button">Neu laden</button>
        </div>
      </section>
    </main>

    <script>
      const stateBadge = document.getElementById("stateBadge");
      const configuredValue = document.getElementById("configuredValue");
      const persistenceValue = document.getElementById("persistenceValue");
      const defaultValue = document.getElementById("defaultValue");
      const enabledToggle = document.getElementById("enabledToggle");
      const message = document.getElementById("message");
      const reloadButton = document.getElementById("reloadButton");
      let isApplyingRemoteState = false;

      function label(value) {
        return value ? "Ein" : "Aus";
      }

      function setMessage(text, isError = false) {
        message.textContent = text || "";
        message.classList.toggle("error", Boolean(isError));
      }

      function renderStatus(status) {
        isApplyingRemoteState = true;
        enabledToggle.checked = Boolean(status.enabled);
        enabledToggle.disabled = !status.configured;
        isApplyingRemoteState = false;

        stateBadge.textContent = status.enabled ? "Aktiv" : "Deaktiviert";
        stateBadge.className = "badge " + (status.enabled ? "on" : "off");
        configuredValue.textContent = status.configured ? "PUSHOVER_* gesetzt" : "Nicht konfiguriert";
        persistenceValue.textContent = status.persistence === "redis" ? "Redis" : "Prozessspeicher";
        defaultValue.textContent = label(status.defaultEnabled);

        if (!status.configured) {
          setMessage("PUSHOVER_APP_TOKEN und PUSHOVER_USER_KEY fehlen. Einschalten ist erst nach der Konfiguration wirksam.", true);
        } else {
          setMessage(status.enabled ? "Pushover-Reports sind aktiv." : "Pushover-Reports sind deaktiviert.");
        }
      }

      async function loadStatus() {
        enabledToggle.disabled = true;
        setMessage("Status wird geladen...");
        try {
          const response = await fetch("/test/pushover/status", { cache: "no-store" });
          const status = await response.json();
          if (!response.ok) {
            throw new Error(status.message || "Status konnte nicht geladen werden.");
          }
          renderStatus(status);
        } catch (error) {
          setMessage(error instanceof Error ? error.message : String(error), true);
        }
      }

      async function saveStatus(enabled) {
        enabledToggle.disabled = true;
        setMessage("Speichere...");
        try {
          const response = await fetch("/test/pushover/status", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ enabled }),
          });
          const status = await response.json();
          if (!response.ok) {
            throw new Error(status.message || "Status konnte nicht gespeichert werden.");
          }
          renderStatus(status);
        } catch (error) {
          setMessage(error instanceof Error ? error.message : String(error), true);
          await loadStatus();
        }
      }

      enabledToggle.addEventListener("change", () => {
        if (isApplyingRemoteState) return;
        void saveStatus(enabledToggle.checked);
      });

      reloadButton.addEventListener("click", () => {
        void loadStatus();
      });

      void loadStatus();
    </script>
  </body>
</html>`;
}
function renderTestPushPage(municipalities, supportedLanguages, defaultLanguage) {
    const municipalityPayload = JSON.stringify(municipalities).replace(/</g, "\\u003c");
    const languagePayload = JSON.stringify(supportedLanguages).replace(/</g, "\\u003c");
    const defaultLanguagePayload = JSON.stringify(defaultLanguage).replace(/</g, "\\u003c");
    return `<!doctype html>
<html lang="de">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>Hitze-V Testversand</title>
    <style>
      :root {
        color-scheme: light;
        --bg: #f4efe7;
        --panel: #fffaf3;
        --panel-strong: #fff4df;
        --line: #d8cbb9;
        --text: #2b241c;
        --muted: #6e6255;
        --accent: #c74b2a;
        --accent-dark: #8f2f17;
        --success-bg: #edf8ee;
        --success-line: #8ac49a;
        --error-bg: #fff0ec;
        --error-line: #e0a090;
      }

      * {
        box-sizing: border-box;
      }

      body {
        margin: 0;
        font-family: "Avenir Next", "Segoe UI", sans-serif;
        background:
          radial-gradient(circle at top right, rgba(199, 75, 42, 0.15), transparent 30%),
          linear-gradient(180deg, #f9f4ec 0%, var(--bg) 100%);
        color: var(--text);
      }

      main {
        max-width: 1160px;
        margin: 0 auto;
        padding: 32px 20px 40px;
      }

      h1 {
        margin: 0 0 12px;
        font-size: clamp(2rem, 4vw, 3.4rem);
        line-height: 0.95;
        letter-spacing: -0.04em;
      }

      p {
        margin: 0;
        color: var(--muted);
      }

      .layout {
        display: grid;
        grid-template-columns: 360px minmax(0, 1fr);
        gap: 20px;
        margin-top: 28px;
      }

      .panel {
        background: rgba(255, 250, 243, 0.94);
        border: 1px solid rgba(216, 203, 185, 0.85);
        border-radius: 24px;
        box-shadow: 0 14px 40px rgba(82, 57, 30, 0.08);
        padding: 20px;
      }

      .panel h2 {
        margin: 0 0 14px;
        font-size: 1.05rem;
      }

      .stack {
        display: grid;
        gap: 12px;
      }

      label {
        display: grid;
        gap: 6px;
        font-size: 0.94rem;
        font-weight: 600;
      }

      input[type="text"],
      select,
      textarea {
        width: 100%;
        border: 1px solid var(--line);
        border-radius: 14px;
        padding: 12px 14px;
        font: inherit;
        color: var(--text);
        background: #fffdf9;
      }

      textarea {
        min-height: 110px;
        resize: vertical;
      }

      button {
        border: 0;
        border-radius: 999px;
        padding: 11px 16px;
        font: inherit;
        font-weight: 700;
        cursor: pointer;
        color: white;
        background: linear-gradient(135deg, var(--accent), var(--accent-dark));
      }

      button.secondary {
        color: var(--text);
        background: var(--panel-strong);
        border: 1px solid var(--line);
      }

      button:disabled {
        cursor: wait;
        opacity: 0.7;
      }

      .button-row {
        display: flex;
        flex-wrap: wrap;
        gap: 10px;
      }

      .summary {
        padding: 14px 16px;
        border-radius: 18px;
        background: var(--panel-strong);
        border: 1px solid var(--line);
        font-size: 0.94rem;
      }

      .list {
        display: grid;
        gap: 8px;
        max-height: 62vh;
        overflow: auto;
        padding-right: 4px;
      }

      .item {
        display: grid;
        grid-template-columns: auto 1fr;
        gap: 12px;
        align-items: start;
        padding: 12px 14px;
        border-radius: 18px;
        border: 1px solid var(--line);
        background: #fffdf9;
      }

      .item strong {
        display: block;
      }

      .item small {
        display: block;
        margin-top: 4px;
        color: var(--muted);
      }

      .status {
        margin-top: 14px;
        border-radius: 18px;
        padding: 14px 16px;
        font-size: 0.92rem;
        white-space: pre-wrap;
        word-break: break-word;
        display: none;
      }

      .status.success {
        display: block;
        background: var(--success-bg);
        border: 1px solid var(--success-line);
      }

      .status.error {
        display: block;
        background: var(--error-bg);
        border: 1px solid var(--error-line);
      }

      .meta {
        margin-top: 8px;
        font-size: 0.86rem;
        color: var(--muted);
      }

      @media (max-width: 900px) {
        .layout {
          grid-template-columns: 1fr;
        }

        .list {
          max-height: none;
        }
      }
${NAV_CSS}
    </style>
  </head>
  <body>
    <main>
      ${renderTopNav("/test/push/ui")}
      <h1>Hitze-V Testversand</h1>

      <div class="layout">
        <section class="panel stack">
          <div>
            <h2>Nachricht</h2>
            <p>Diese Oberfläche ist nur aktiv, wenn <code>develop=true</code> oder <code>DEVELOP=true</code> gesetzt ist.</p>
          </div>

          <label>
            Titel
            <input id="title" type="text" value="Test: Hitze-Warnung" />
          </label>

          <label>
            Nachricht
            <textarea id="body">Dies ist eine manuelle Testnachricht vom Backend.</textarea>
          </label>

          <label>
            Sprache
            <select id="lang"></select>
          </label>

          <div class="summary" id="summary"></div>

          <div class="button-row">
            <button id="sendButton" type="button">Testnachricht senden</button>
            <button id="clearSelectionButton" class="secondary" type="button">Auswahl leeren</button>
          </div>

          <pre id="status" class="status"></pre>
        </section>

        <section class="panel stack">
          <div class="stack">
            <div>
              <h2>Empfänger wählen</h2>
              <p>Gemeinden können direkt über Kennziffer oder Name gefiltert und ausgewählt werden.</p>
            </div>

            <label>
              Suche
              <input id="search" type="text" placeholder="z. B. 10301 oder Eisenstadt" />
            </label>

            <div class="button-row">
              <button id="selectVisibleButton" class="secondary" type="button">Sichtbare wählen</button>
              <button id="clearVisibleButton" class="secondary" type="button">Sichtbare abwählen</button>
            </div>

            <div class="meta" id="meta"></div>
          </div>

          <div class="list" id="municipalityList"></div>
        </section>
      </div>
    </main>

    <script>
      const municipalities = ${municipalityPayload};
      const supportedLanguages = ${languagePayload};
      const defaultLanguage = ${defaultLanguagePayload};
      const selectedIds = new Set();

      const titleInput = document.getElementById("title");
      const bodyInput = document.getElementById("body");
      const languageSelect = document.getElementById("lang");
      const searchInput = document.getElementById("search");
      const municipalityList = document.getElementById("municipalityList");
      const summary = document.getElementById("summary");
      const meta = document.getElementById("meta");
      const status = document.getElementById("status");
      const sendButton = document.getElementById("sendButton");
      const selectVisibleButton = document.getElementById("selectVisibleButton");
      const clearVisibleButton = document.getElementById("clearVisibleButton");
      const clearSelectionButton = document.getElementById("clearSelectionButton");

      function selectedLanguage() {
        const value = languageSelect.value || defaultLanguage;
        return supportedLanguages.includes(value) ? value : defaultLanguage;
      }

      for (const languageCode of supportedLanguages) {
        const option = document.createElement("option");
        option.value = languageCode;
        option.textContent = languageCode;
        if (languageCode === defaultLanguage) {
          option.selected = true;
        }
        languageSelect.appendChild(option);
      }

      function queryText() {
        return searchInput.value.trim().toLowerCase();
      }

      function filteredMunicipalities() {
        const query = queryText();
        if (!query) {
          return municipalities;
        }

        return municipalities.filter((municipality) => {
          const haystack = [
            municipality.municipalityId,
            municipality.name,
          ].join(" ").toLowerCase();
          return haystack.includes(query);
        });
      }

      function updateSummary() {
        const filtered = filteredMunicipalities();
        summary.textContent =
          selectedIds.size + " Empfaenger ausgewaehlt" + " · Sprache: " + selectedLanguage();
        meta.textContent = filtered.length + " sichtbar von " + municipalities.length + " Einträgen";
      }

      function setStatus(message, type) {
        status.textContent = message;
        status.className = "status " + type;
      }

      function clearStatus() {
        status.textContent = "";
        status.className = "status";
      }

      function renderList() {
        municipalityList.innerHTML = "";

        for (const municipality of filteredMunicipalities()) {
          const label = document.createElement("label");
          label.className = "item";

          const checkbox = document.createElement("input");
          checkbox.type = "checkbox";
          checkbox.checked = selectedIds.has(municipality.municipalityId);
          checkbox.addEventListener("change", () => {
            if (checkbox.checked) {
              selectedIds.add(municipality.municipalityId);
            } else {
              selectedIds.delete(municipality.municipalityId);
            }
            updateSummary();
          });

          const text = document.createElement("div");
          text.innerHTML =
            "<strong>" + municipality.municipalityId + " · " + municipality.name + "</strong>" +
            "<small>Topic warngebiet_" + municipality.municipalityId + "_" + selectedLanguage() + "</small>";

          label.appendChild(checkbox);
          label.appendChild(text);
          municipalityList.appendChild(label);
        }
      }

      function render() {
        renderList();
        updateSummary();
      }

      searchInput.addEventListener("input", render);
      languageSelect.addEventListener("change", render);

      selectVisibleButton.addEventListener("click", () => {
        for (const municipality of filteredMunicipalities()) {
          selectedIds.add(municipality.municipalityId);
        }
        render();
      });

      clearVisibleButton.addEventListener("click", () => {
        for (const municipality of filteredMunicipalities()) {
          selectedIds.delete(municipality.municipalityId);
        }
        render();
      });

      clearSelectionButton.addEventListener("click", () => {
        selectedIds.clear();
        clearStatus();
        render();
      });

      sendButton.addEventListener("click", async () => {
        clearStatus();

        const municipalityIds = Array.from(selectedIds).sort();
        if (municipalityIds.length === 0) {
          setStatus("Bitte mindestens einen Empfänger auswählen.", "error");
          return;
        }

        sendButton.disabled = true;

        try {
          const response = await fetch("/test/push/bulk", {
            method: "POST",
            headers: {
              "Content-Type": "application/json",
            },
            body: JSON.stringify({
              municipalityIds,
              title: titleInput.value,
              body: bodyInput.value,
              lang: selectedLanguage(),
            }),
          });

          const result = await response.json();
          if (!response.ok) {
            throw new Error(result.message || "Testversand fehlgeschlagen.");
          }

          const failedCount = result.failedCount || 0;
          const summaryLine = failedCount > 0
            ? "Teilweise versendet. Erfolgreich: " + result.sentCount + ", Fehler: " + failedCount
            : "Versand erfolgreich. Empfänger: " + result.sentCount;
          const detailBlocks = ["Erfolgreich:\\n" + JSON.stringify(result.recipients, null, 2)];
          if (failedCount > 0) {
            detailBlocks.push("Fehler:\\n" + JSON.stringify(result.failures, null, 2));
          }
          setStatus(
            summaryLine + "\\n\\n" + detailBlocks.join("\\n\\n"),
            failedCount > 0 ? "error" : "success"
          );
        } catch (error) {
          setStatus(error instanceof Error ? error.message : String(error), "error");
        } finally {
          sendButton.disabled = false;
        }
      });

      render();
    </script>
  </body>
</html>`;
}
function renderWarningsPage() {
    return `<!doctype html>
<html lang="de">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>Hitze-V · Aktuelle Warnungen</title>
    <style>
      :root {
        color-scheme: light;
        --bg: #f4efe7;
        --panel: #fffaf3;
        --panel-strong: #fff4df;
        --line: #d8cbb9;
        --text: #2b241c;
        --muted: #6e6255;
        --accent: #c74b2a;
        --accent-dark: #8f2f17;
        --error-bg: #fff0ec;
        --error-line: #e0a090;
        --level-0: #8abf78;
        --level-1: #f0d28a;
        --level-2: #e5933b;
        --level-3: #c74b2a;
        --level-4: #7e2012;
      }

      * {
        box-sizing: border-box;
      }

      body {
        margin: 0;
        font-family: "Avenir Next", "Segoe UI", sans-serif;
        background:
          radial-gradient(circle at top right, rgba(199, 75, 42, 0.15), transparent 30%),
          linear-gradient(180deg, #f9f4ec 0%, var(--bg) 100%);
        color: var(--text);
      }

      main {
        max-width: 1160px;
        margin: 0 auto;
        padding: 32px 20px 40px;
      }

      h1 {
        margin: 0 0 12px;
        font-size: clamp(2rem, 4vw, 3.4rem);
        line-height: 0.95;
        letter-spacing: -0.04em;
      }

      h2 {
        margin: 0 0 14px;
        font-size: 1.05rem;
      }

      p {
        margin: 0;
        color: var(--muted);
      }

      a {
        color: var(--accent-dark);
      }

      .toolbar {
        display: flex;
        flex-wrap: wrap;
        align-items: center;
        gap: 14px;
        margin: 22px 0 18px;
      }

      .toolbar .status {
        color: var(--muted);
        font-size: 0.92rem;
      }

      button {
        border: 0;
        border-radius: 999px;
        padding: 12px 22px;
        font: inherit;
        font-weight: 700;
        cursor: pointer;
        color: white;
        background: linear-gradient(135deg, var(--accent), var(--accent-dark));
      }

      button:disabled {
        cursor: wait;
        opacity: 0.7;
      }

      .panel {
        background: rgba(255, 250, 243, 0.94);
        border: 1px solid rgba(216, 203, 185, 0.85);
        border-radius: 24px;
        box-shadow: 0 14px 40px rgba(82, 57, 30, 0.08);
        padding: 20px;
        margin-bottom: 18px;
      }

      .meta-grid {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
        gap: 12px;
      }

      .meta-grid div {
        padding: 12px 14px;
        border-radius: 16px;
        background: var(--panel-strong);
        border: 1px solid var(--line);
      }

      .meta-grid strong {
        display: block;
        font-size: 0.78rem;
        text-transform: uppercase;
        letter-spacing: 0.06em;
        color: var(--muted);
        margin-bottom: 4px;
      }

      .meta-grid span {
        font-size: 0.98rem;
        word-break: break-word;
      }

      .map-layout {
        display: block;
      }

      .day-filter-grid {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(170px, 1fr));
        gap: 10px;
        margin-bottom: 16px;
      }

      .day-filter {
        display: grid;
        grid-template-columns: auto 1fr;
        gap: 10px;
        align-items: start;
        padding: 12px 14px;
        border-radius: 16px;
        border: 1px solid var(--line);
        background: #fffdf9;
        cursor: pointer;
      }

      .day-filter input {
        width: 18px;
        height: 18px;
        margin: 2px 0 0;
        accent-color: var(--accent);
      }

      .day-filter strong {
        display: block;
        color: var(--text);
        margin-bottom: 2px;
      }

      .day-filter span {
        display: block;
        color: var(--muted);
        font-size: 0.86rem;
        line-height: 1.35;
      }

      .map-summary {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
        gap: 10px;
        margin-bottom: 16px;
      }

      .map-summary div {
        border: 1px solid var(--line);
        border-radius: 16px;
        background: var(--panel-strong);
        padding: 11px 12px;
      }

      .map-summary strong {
        display: block;
        font-size: 0.76rem;
        text-transform: uppercase;
        letter-spacing: 0.06em;
        color: var(--muted);
        margin-bottom: 4px;
      }

      .map-controls {
        display: contents;
      }

      .district-search {
        width: 100%;
        border: 1px solid var(--line);
        border-radius: 999px;
        background: #fffdf9;
        color: var(--text);
        font: inherit;
        padding: 11px 16px;
      }

      .zoom-controls {
        display: flex;
        flex-direction: column;
        gap: 8px;
      }

      .icon-button {
        width: 44px;
        height: 44px;
        padding: 0;
        border-radius: 999px;
        line-height: 1;
        font-size: 1.05rem;
        box-shadow: 0 8px 18px rgba(59, 42, 26, 0.18);
      }

      .map-frame {
        min-height: 430px;
        border-radius: 18px;
        border: 1px solid var(--line);
        background:
          radial-gradient(circle at 50% 48%, rgba(138, 191, 120, 0.28), transparent 58%),
          linear-gradient(180deg, rgba(232, 247, 224, 0.94), rgba(250, 255, 247, 0.98));
        overflow: hidden;
        position: relative;
        touch-action: none;
      }

      .map-canvas,
      .map-canvas svg {
        display: block;
        width: 100%;
      }

      .map-canvas svg {
        height: auto;
        min-height: 430px;
        cursor: grab;
        user-select: none;
      }

      .map-frame.dragging svg {
        cursor: grabbing;
      }

      .map-search-overlay {
        position: absolute;
        top: 14px;
        left: 14px;
        right: 82px;
        z-index: 4;
        max-width: 420px;
        pointer-events: auto;
      }

      .map-zoom-overlay {
        position: absolute;
        top: 14px;
        right: 14px;
        z-index: 4;
      }

      .map-legend-overlay {
        position: absolute;
        left: 14px;
        bottom: 14px;
        z-index: 4;
        max-width: 230px;
        box-shadow: 0 8px 22px rgba(58, 42, 25, 0.14);
      }

      .map-hover {
        position: absolute;
        z-index: 5;
        display: none;
        max-width: 260px;
        border: 1px solid var(--line);
        border-radius: 14px;
        background: #fffdf9;
        box-shadow: 0 10px 26px rgba(57, 40, 24, 0.2);
        padding: 10px 12px;
        pointer-events: none;
        font-size: 0.86rem;
      }

      .map-hover strong {
        display: block;
        color: var(--text);
        margin-bottom: 2px;
      }

      .map-hover span {
        display: block;
        color: var(--muted);
      }

      .map-empty {
        min-height: 260px;
        display: grid;
        place-items: center;
        color: var(--muted);
        text-align: center;
        padding: 24px;
      }

      .map-feature {
        stroke: rgba(61, 43, 25, 0.48);
        stroke-width: 1.1;
        vector-effect: non-scaling-stroke;
      }

      .map-district,
      .map-municipality {
        fill: rgba(138, 191, 120, 0.72);
        stroke: rgba(72, 118, 69, 0.48);
        stroke-width: 0.7;
        vector-effect: non-scaling-stroke;
      }

      .map-district.level-2,
      .map-municipality.level-2,
      .map-feature.level-2 {
        fill: rgba(229, 147, 59, 0.76);
      }

      .map-district.level-3,
      .map-municipality.level-3,
      .map-feature.level-3 {
        fill: rgba(199, 75, 42, 0.8);
      }

      .map-district.level-4,
      .map-municipality.level-4,
      .map-feature.level-4 {
        fill: rgba(126, 32, 18, 0.86);
      }

      .map-warning-outline {
        fill: transparent;
        stroke: rgba(45, 34, 21, 0.38);
        stroke-width: 1.4;
        pointer-events: none;
        vector-effect: non-scaling-stroke;
      }

      .map-district:hover,
      .map-municipality:hover,
      .map-feature:hover {
        stroke: rgba(43, 36, 28, 0.9);
        stroke-width: 1.6;
      }

      .map-district.selected,
      .map-municipality.selected {
        stroke: rgba(35, 28, 20, 0.95);
        stroke-width: 2.4;
        filter: drop-shadow(0 4px 8px rgba(44, 34, 22, 0.26));
      }

      .map-side {
        display: grid;
        gap: 12px;
      }

      .map-note,
      .legend {
        border: 1px solid var(--line);
        border-radius: 16px;
        background: var(--panel-strong);
        padding: 12px 14px;
        color: var(--muted);
        font-size: 0.9rem;
      }

      .legend {
        display: grid;
        gap: 8px;
      }

      .legend-row {
        display: flex;
        align-items: center;
        gap: 8px;
        color: var(--text);
      }

      .legend-swatch {
        width: 18px;
        height: 18px;
        border-radius: 5px;
        border: 1px solid rgba(61, 43, 25, 0.35);
      }

      .legend-swatch.level-0 { background: var(--level-0); }
      .legend-swatch.level-2 { background: var(--level-2); }
      .legend-swatch.level-3 { background: var(--level-3); }
      .legend-swatch.level-4 { background: var(--level-4); }

      .map-feature-list {
        display: grid;
        gap: 8px;
        max-height: 260px;
        overflow: auto;
      }

      .district-list {
        display: grid;
        gap: 8px;
        max-height: 220px;
        overflow: auto;
      }

      .district-item {
        display: grid;
        grid-template-columns: 76px 1fr;
        gap: 10px;
        align-items: center;
        border: 1px solid var(--line);
        border-radius: 14px;
        background: #fffdf9;
        padding: 9px 10px;
        font-size: 0.86rem;
      }

      .map-feature-item {
        border: 1px solid var(--line);
        border-radius: 14px;
        background: #fffdf9;
        padding: 10px 12px;
        font-size: 0.86rem;
      }

      .map-feature-item strong {
        display: block;
        color: var(--text);
        margin-bottom: 3px;
      }

      .district-item strong {
        display: block;
        color: var(--text);
        margin-bottom: 3px;
      }

      .map-feature-item span {
        color: var(--muted);
      }

      .district-item span {
        color: var(--muted);
      }

      .municipality-list {
        display: grid;
        gap: 10px;
      }

      .municipality {
        display: grid;
        grid-template-columns: 60px 1fr auto;
        gap: 16px;
        align-items: center;
        padding: 14px 16px;
        border-radius: 18px;
        border: 1px solid var(--line);
        background: #fffdf9;
      }

      .badge {
        display: inline-flex;
        align-items: center;
        justify-content: center;
        min-width: 44px;
        padding: 6px 10px;
        border-radius: 999px;
        color: white;
        font-weight: 800;
        background: var(--level-1);
      }

      .badge.level-2 { background: var(--level-2); }
      .badge.level-3 { background: var(--level-3); }
      .badge.level-4 { background: var(--level-4); }

      .municipality .title {
        font-weight: 700;
      }

      .municipality .time {
        color: var(--muted);
        font-size: 0.9rem;
        margin-top: 4px;
      }

      .municipality details {
        margin-top: 6px;
        font-size: 0.86rem;
        color: var(--muted);
      }

      .municipality details ul {
        margin: 6px 0 0;
        padding-left: 18px;
      }

      .municipality .right {
        text-align: right;
        color: var(--muted);
        font-size: 0.86rem;
        white-space: nowrap;
      }

      .empty {
        padding: 24px;
        text-align: center;
        color: var(--muted);
      }

      .error {
        background: var(--error-bg);
        border: 1px solid var(--error-line);
        padding: 14px 16px;
        border-radius: 18px;
        color: var(--accent-dark);
        margin-bottom: 18px;
        white-space: pre-wrap;
        display: none;
      }

      .error.active {
        display: block;
      }

      @media (max-width: 600px) {
        .map-search-overlay {
          top: 12px;
          left: 12px;
          right: 62px;
        }

        .map-zoom-overlay {
          top: 12px;
          right: 12px;
        }

        .map-legend-overlay {
          left: 12px;
          right: 12px;
          bottom: 12px;
          max-width: none;
        }

        .map-layout {
          grid-template-columns: 1fr;
        }

        .municipality {
          grid-template-columns: 50px 1fr;
        }
        .municipality .right {
          grid-column: 1 / -1;
          text-align: left;
        }
      }
${NAV_CSS}
    </style>
  </head>
  <body>
    <main>
      ${renderTopNav("/test/warnings/ui")}
      <h1>Aktuelle Hitzewarnungen</h1>
      <p>Live-Snapshot direkt aus der GeoSphere-API · keine Pushes, kein Redis-Write.</p>

      <div class="toolbar">
        <button id="refreshButton" type="button">Aktualisieren</button>
        <span class="status" id="status">Lade…</span>
      </div>

      <div id="error" class="error"></div>

      <section class="panel">
        <h2>Metadaten</h2>
        <div class="meta-grid" id="meta"></div>
      </section>

      <section class="panel">
        <h2>Kartenansicht</h2>
        <div id="dayFilters" class="day-filter-grid"></div>
        <div id="mapSummary" class="map-summary"></div>
        <div class="map-layout">
          <div id="map" class="map-frame">
            <div id="mapCanvas" class="map-canvas"></div>
            <div class="map-search-overlay">
              <input id="districtSearch" class="district-search" list="districtOptions" type="search" placeholder="Gemeinde oder Bezirk suchen..." autocomplete="off" />
              <datalist id="districtOptions"></datalist>
            </div>
            <div class="zoom-controls map-zoom-overlay" aria-label="Kartenzoom">
              <button id="zoomInButton" class="icon-button" type="button" title="Hineinzoomen">+</button>
              <button id="zoomOutButton" class="icon-button" type="button" title="Herauszoomen">−</button>
              <button id="zoomResetButton" class="icon-button" type="button" title="Ansicht zurücksetzen">↺</button>
            </div>
            <div class="legend map-legend-overlay">
              <div class="legend-row"><span class="legend-swatch level-0"></span><span>Keine Hitzewarnung</span></div>
              <div class="legend-row"><span class="legend-swatch level-2"></span><span>Stufe 2</span></div>
              <div class="legend-row"><span class="legend-swatch level-3"></span><span>Stufe 3</span></div>
              <div class="legend-row"><span class="legend-swatch level-4"></span><span>Stufe 4</span></div>
            </div>
            <div id="mapHover" class="map-hover"></div>
          </div>
        </div>
      </section>

      <section class="panel">
        <h2>Betroffene Gemeinden</h2>
        <div id="municipalities" class="municipality-list"></div>
      </section>
    </main>

    <script>
      const refreshButton = document.getElementById("refreshButton");
      const statusEl = document.getElementById("status");
      const errorEl = document.getElementById("error");
      const metaEl = document.getElementById("meta");
      const municipalitiesEl = document.getElementById("municipalities");
      const dayFiltersEl = document.getElementById("dayFilters");
      const mapSummaryEl = document.getElementById("mapSummary");
      const mapEl = document.getElementById("map");
      const mapCanvasEl = document.getElementById("mapCanvas");
      const mapHoverEl = document.getElementById("mapHover");
      const districtSearchEl = document.getElementById("districtSearch");
      const districtOptionsEl = document.getElementById("districtOptions");
      const zoomInButton = document.getElementById("zoomInButton");
      const zoomOutButton = document.getElementById("zoomOutButton");
      const zoomResetButton = document.getElementById("zoomResetButton");
      let currentSnapshot = null;
      let selectedDayKeys = new Set();
      let selectedArea = null;
      let mapSvgEl = null;
      let currentViewBox = { x: 0, y: 0, width: 1000, height: 620 };
      let districtBoundsById = new Map();
      let municipalityBoundsById = new Map();
      let dragState = null;

      const timeFmt = new Intl.DateTimeFormat("de-AT", {
        timeZone: "Europe/Vienna",
        dateStyle: "short",
        timeStyle: "short",
      });
      const dayKeyFmt = new Intl.DateTimeFormat("en-CA", {
        timeZone: "Europe/Vienna",
        year: "numeric",
        month: "2-digit",
        day: "2-digit",
      });
      const dayLabelFmt = new Intl.DateTimeFormat("de-AT", {
        timeZone: "Europe/Vienna",
        weekday: "short",
        day: "2-digit",
        month: "2-digit",
      });

      function formatTime(iso) {
        if (!iso) return "—";
        const date = new Date(iso);
        if (Number.isNaN(date.getTime())) return iso;
        return timeFmt.format(date);
      }

      function dayKey(date) {
        const parts = dayKeyFmt.formatToParts(date);
        const partValue = (type) => parts.find((part) => part.type === type)?.value;
        const year = partValue("year");
        const month = partValue("month");
        const day = partValue("day");
        return year && month && day ? year + "-" + month + "-" + day : "";
      }

      function parseDayKey(key) {
        const parts = String(key).split("-").map(Number);
        if (parts.length !== 3 || parts.some((part) => !Number.isFinite(part))) {
          return null;
        }
        return new Date(Date.UTC(parts[0], parts[1] - 1, parts[2], 12, 0, 0));
      }

      function addDays(date, days) {
        const next = new Date(date);
        next.setUTCDate(next.getUTCDate() + days);
        return next;
      }

      function dayLabel(key) {
        const parsed = parseDayKey(key);
        if (!parsed) return key;
        const today = parseDayKey(dayKey(new Date()));
        const tomorrow = today ? addDays(today, 1) : null;

        if (today && key === dayKey(today)) return "Heute";
        if (tomorrow && key === dayKey(tomorrow)) return "Morgen";
        return dayLabelFmt.format(parsed);
      }

      function featureDayKeys(feature) {
        const start = feature.start ? new Date(feature.start) : null;
        const end = feature.end ? new Date(feature.end) : null;
        if (!start || Number.isNaN(start.getTime())) return [];

        const startKey = dayKey(start);
        const endKey = end && !Number.isNaN(end.getTime()) ? dayKey(end) : startKey;
        const cursor = parseDayKey(startKey);
        const last = parseDayKey(endKey);
        if (!cursor || !last) return [startKey];

        const keys = [];
        for (let current = cursor; current <= last; current = addDays(current, 1)) {
          keys.push(dayKey(current));
        }
        return keys;
      }

      function selectedFeatures(snapshot) {
        const features = Array.isArray(snapshot.mapFeatures) ? snapshot.mapFeatures : [];
        if (selectedDayKeys.size === 0) return [];

        return features
          .filter((feature) => featureDayKeys(feature).some((key) => selectedDayKeys.has(key)))
          .sort((left, right) => {
            const levelDelta = (Number(left.level) || 0) - (Number(right.level) || 0);
            if (levelDelta !== 0) return levelDelta;
            return String(left.start || "").localeCompare(String(right.start || ""));
          });
      }

      function selectedMunicipalities(snapshot) {
        const selectedIds = new Set(
          selectedFeatures(snapshot).flatMap((feature) =>
            Array.isArray(feature.municipalityIds) ? feature.municipalityIds : []
          )
        );

        return snapshot.affectedMunicipalities.filter((municipality) =>
          selectedIds.has(municipality.municipalityId)
        );
      }

      function districtCode(municipalityId) {
        return String(municipalityId || "").slice(0, 3);
      }

      function districtAggregates(snapshot) {
        const districts = new Map();
        for (const feature of selectedFeatures(snapshot)) {
          for (const municipalityId of Array.isArray(feature.municipalityIds) ? feature.municipalityIds : []) {
            const code = districtCode(municipalityId);
            if (!code) continue;

            const existing = districts.get(code) || {
              code,
              municipalityIds: new Set(),
              warningIds: new Set(),
              maxLevel: 0,
            };
            existing.municipalityIds.add(municipalityId);
            existing.warningIds.add(feature.id);
            existing.maxLevel = Math.max(existing.maxLevel, Number(feature.level) || 0);
            districts.set(code, existing);
          }
        }
        return districts;
      }

      function municipalityAggregates(snapshot) {
        const municipalities = new Map();
        for (const feature of selectedFeatures(snapshot)) {
          for (const municipalityId of Array.isArray(feature.municipalityIds) ? feature.municipalityIds : []) {
            const existing = municipalities.get(municipalityId) || {
              municipalityId,
              warningIds: new Set(),
              maxLevel: 0,
            };
            existing.warningIds.add(feature.id);
            existing.maxLevel = Math.max(existing.maxLevel, Number(feature.level) || 0);
            municipalities.set(municipalityId, existing);
          }
        }
        return municipalities;
      }

      function normalizeSearchText(value) {
        return String(value || "")
          .normalize("NFD")
          .replace(/[\\u0300-\\u036f]/g, "")
          .toLowerCase()
          .replace(/[^a-z0-9]+/g, " ")
          .trim();
      }

      function districtLabel(district) {
        return district.id + " · " + district.name;
      }

      function districtSearchHaystack(district) {
        return normalizeSearchText(district.id + " " + district.name);
      }

      function areaLabel(area) {
        return (area.kind === "municipality" ? "Gemeinde " : "Bezirk ") + area.id + " · " + area.name;
      }

      function areaSearchHaystack(area) {
        return normalizeSearchText(area.kind + " " + area.id + " " + area.name);
      }

      function boundsForPoints(points) {
        const xs = points.map((point) => point[0]);
        const ys = points.map((point) => point[1]);
        return {
          minX: Math.min(...xs),
          maxX: Math.max(...xs),
          minY: Math.min(...ys),
          maxY: Math.max(...ys),
        };
      }

      function mergeBounds(left, right) {
        if (!left) return right;
        return {
          minX: Math.min(left.minX, right.minX),
          maxX: Math.max(left.maxX, right.maxX),
          minY: Math.min(left.minY, right.minY),
          maxY: Math.max(left.maxY, right.maxY),
        };
      }

      function applyViewBox(viewBox) {
        currentViewBox = {
          x: Math.max(0, Math.min(1000 - viewBox.width, viewBox.x)),
          y: Math.max(0, Math.min(620 - viewBox.height, viewBox.y)),
          width: viewBox.width,
          height: viewBox.height,
        };
        if (mapSvgEl) {
          mapSvgEl.setAttribute(
            "viewBox",
            currentViewBox.x + " " + currentViewBox.y + " " + currentViewBox.width + " " + currentViewBox.height
          );
        }
      }

      function panMap(deltaClientX, deltaClientY, originViewBox, mapRect) {
        if (!mapRect || mapRect.width <= 0 || mapRect.height <= 0) {
          return;
        }

        const deltaX = deltaClientX * (originViewBox.width / mapRect.width);
        const deltaY = deltaClientY * (originViewBox.height / mapRect.height);
        applyViewBox({
          x: originViewBox.x - deltaX,
          y: originViewBox.y - deltaY,
          width: originViewBox.width,
          height: originViewBox.height,
        });
      }

      function beginMapDrag(event) {
        if (!mapSvgEl || event.button !== 0) {
          return;
        }

        dragState = {
          pointerId: event.pointerId,
          startX: event.clientX,
          startY: event.clientY,
          originViewBox: { ...currentViewBox },
          mapRect: mapSvgEl.getBoundingClientRect(),
        };
        mapEl.classList.add("dragging");
        mapSvgEl.setPointerCapture(event.pointerId);
        event.preventDefault();
      }

      function updateMapDrag(event) {
        if (!dragState || dragState.pointerId !== event.pointerId) {
          return;
        }

        panMap(
          event.clientX - dragState.startX,
          event.clientY - dragState.startY,
          dragState.originViewBox,
          dragState.mapRect
        );
      }

      function endMapDrag(event) {
        if (!dragState || dragState.pointerId !== event.pointerId) {
          return;
        }

        if (mapSvgEl && mapSvgEl.hasPointerCapture(event.pointerId)) {
          mapSvgEl.releasePointerCapture(event.pointerId);
        }
        dragState = null;
        mapEl.classList.remove("dragging");
      }

      function attachMapPanHandlers(svg) {
        svg.addEventListener("pointerdown", beginMapDrag);
        svg.addEventListener("pointermove", updateMapDrag);
        svg.addEventListener("pointerup", endMapDrag);
        svg.addEventListener("pointercancel", endMapDrag);
        svg.addEventListener("wheel", (event) => {
          event.preventDefault();
          zoomMapAt(event.deltaY < 0 ? 0.82 : 1.18, event.clientX, event.clientY);
        }, { passive: false });
        svg.addEventListener("lostpointercapture", () => {
          dragState = null;
          mapEl.classList.remove("dragging");
        });
      }

      function showMapHover(event, title, detail) {
        mapHoverEl.innerHTML = "";
        const strong = document.createElement("strong");
        strong.textContent = title;
        const span = document.createElement("span");
        span.textContent = detail;
        mapHoverEl.appendChild(strong);
        mapHoverEl.appendChild(span);
        mapHoverEl.style.display = "block";
        moveMapHover(event);
      }

      function moveMapHover(event) {
        if (mapHoverEl.style.display !== "block") return;
        const rect = mapEl.getBoundingClientRect();
        const maxX = Math.max(12, rect.width - 280);
        const maxY = Math.max(12, rect.height - 80);
        const x = Math.min(maxX, Math.max(12, event.clientX - rect.left + 14));
        const y = Math.min(maxY, Math.max(12, event.clientY - rect.top + 14));
        mapHoverEl.style.left = x + "px";
        mapHoverEl.style.top = y + "px";
      }

      function hideMapHover() {
        mapHoverEl.style.display = "none";
      }

      function resetMapView() {
        selectedArea = null;
        districtSearchEl.value = "";
        applyViewBox({ x: 0, y: 0, width: 1000, height: 620 });
        mapCanvasEl.querySelectorAll(".selected").forEach((node) => {
          node.classList.remove("selected");
        });
      }

      function zoomMap(factor) {
        const nextWidth = Math.min(1000, Math.max(90, currentViewBox.width * factor));
        const nextHeight = Math.min(620, Math.max(56, currentViewBox.height * factor));
        const centerX = currentViewBox.x + currentViewBox.width / 2;
        const centerY = currentViewBox.y + currentViewBox.height / 2;
        applyViewBox({
          x: Math.max(0, Math.min(1000 - nextWidth, centerX - nextWidth / 2)),
          y: Math.max(0, Math.min(620 - nextHeight, centerY - nextHeight / 2)),
          width: nextWidth,
          height: nextHeight,
        });
      }

      function zoomToBounds(bounds) {
        const padding = 24;
        const width = Math.max(70, bounds.maxX - bounds.minX + padding * 2);
        const height = Math.max(44, bounds.maxY - bounds.minY + padding * 2);
        const aspect = 1000 / 620;
        let viewWidth = width;
        let viewHeight = height;

        if (viewWidth / viewHeight > aspect) {
          viewHeight = viewWidth / aspect;
        } else {
          viewWidth = viewHeight * aspect;
        }

        viewWidth = Math.min(1000, viewWidth);
        viewHeight = Math.min(620, viewHeight);
        const centerX = (bounds.minX + bounds.maxX) / 2;
        const centerY = (bounds.minY + bounds.maxY) / 2;

        applyViewBox({
          x: Math.max(0, Math.min(1000 - viewWidth, centerX - viewWidth / 2)),
          y: Math.max(0, Math.min(620 - viewHeight, centerY - viewHeight / 2)),
          width: viewWidth,
          height: viewHeight,
        });
      }

      function zoomMapAt(factor, clientX, clientY) {
        if (!mapSvgEl) {
          zoomMap(factor);
          return;
        }

        const rect = mapSvgEl.getBoundingClientRect();
        if (!rect || rect.width <= 0 || rect.height <= 0) {
          zoomMap(factor);
          return;
        }

        const pointerX = currentViewBox.x + ((clientX - rect.left) / rect.width) * currentViewBox.width;
        const pointerY = currentViewBox.y + ((clientY - rect.top) / rect.height) * currentViewBox.height;
        const nextWidth = Math.min(1000, Math.max(90, currentViewBox.width * factor));
        const nextHeight = Math.min(620, Math.max(56, currentViewBox.height * factor));
        const ratioX = (pointerX - currentViewBox.x) / currentViewBox.width;
        const ratioY = (pointerY - currentViewBox.y) / currentViewBox.height;

        applyViewBox({
          x: pointerX - nextWidth * ratioX,
          y: pointerY - nextHeight * ratioY,
          width: nextWidth,
          height: nextHeight,
        });
      }

      function selectArea(area) {
        selectedArea = area;
        mapCanvasEl.querySelectorAll(".selected").forEach((node) => {
          node.classList.remove("selected");
        });

        const attr = area.kind === "municipality" ? "data-municipality-id" : "data-district-id";
        const selected = mapCanvasEl.querySelector("[" + attr + "='" + area.id + "']");
        if (selected) {
          selected.classList.add("selected");
        }

        const bounds = area.kind === "municipality"
          ? municipalityBoundsById.get(area.id)
          : districtBoundsById.get(area.id);
        if (bounds) {
          zoomToBounds(bounds);
        }
      }

      function findAreaBySearchValue(value) {
        if (!currentSnapshot) return null;
        const query = normalizeSearchText(value);
        if (!query) return null;

        const municipalities = Array.isArray(currentSnapshot.municipalityFeatures)
          ? currentSnapshot.municipalityFeatures.map((area) => ({ ...area, kind: "municipality" }))
          : [];
        const districts = Array.isArray(currentSnapshot.districtFeatures)
          ? currentSnapshot.districtFeatures.map((area) => ({ ...area, kind: "district" }))
          : [];
        return [...municipalities, ...districts].find((area) => areaSearchHaystack(area).includes(query)) || null;
      }

      function renderDistrictSearchOptions(snapshot) {
        districtOptionsEl.innerHTML = "";
        const municipalities = Array.isArray(snapshot.municipalityFeatures)
          ? snapshot.municipalityFeatures.map((area) => ({ ...area, kind: "municipality" }))
          : [];
        const districts = Array.isArray(snapshot.districtFeatures)
          ? snapshot.districtFeatures.map((area) => ({ ...area, kind: "district" }))
          : [];
        const areas = [...municipalities, ...districts].sort((left, right) =>
          areaLabel(left).localeCompare(areaLabel(right), "de-AT")
        );

        for (const area of areas) {
          const option = document.createElement("option");
          option.value = areaLabel(area);
          districtOptionsEl.appendChild(option);
        }
      }

      function setError(message) {
        if (!message) {
          errorEl.textContent = "";
          errorEl.classList.remove("active");
          return;
        }
        errorEl.textContent = message;
        errorEl.classList.add("active");
      }

      function renderMeta(snapshot) {
        const entries = [
          ["Quelle", snapshot.source + (snapshot.sourceUrl ? " · " + snapshot.sourceUrl : "")],
          ["Min. Warnstufe", String(snapshot.minWarningLevel)],
          ["Features roh", String(snapshot.rawFeatureCount)],
          ["Akzeptierte Warnungen", String(snapshot.acceptedWarningCount)],
          ["Betroffene Gemeinden", String(snapshot.affectedMunicipalities.length)],
          ["Request-ID", snapshot.requestId],
        ];
        metaEl.innerHTML = "";
        for (const [label, value] of entries) {
          const cell = document.createElement("div");
          const lbl = document.createElement("strong");
          lbl.textContent = label;
          const val = document.createElement("span");
          val.textContent = value;
          cell.appendChild(lbl);
          cell.appendChild(val);
          metaEl.appendChild(cell);
        }
      }

      function geometryRings(geometry) {
        if (!geometry || !Array.isArray(geometry.coordinates)) return [];

        if (geometry.type === "Polygon") {
          return geometry.coordinates.filter((ring) => Array.isArray(ring) && ring.length > 2);
        }

        if (geometry.type === "MultiPolygon") {
          return geometry.coordinates.flatMap((polygon) =>
            Array.isArray(polygon)
              ? polygon.filter((ring) => Array.isArray(ring) && ring.length > 2)
              : []
          );
        }

        return [];
      }

      function collectMapRings(features) {
        const rings = [];
        for (const feature of features) {
          for (const ring of geometryRings(feature.geometry)) {
            const points = ring
              .map((point) => Array.isArray(point) && point.length >= 2
                ? [Number(point[0]), Number(point[1])]
                : null
              )
              .filter((point) => point && Number.isFinite(point[0]) && Number.isFinite(point[1]));

            if (points.length > 2) {
              rings.push({ feature, points });
            }
          }
        }
        return rings;
      }

      function summarizeFeatures(features) {
        const municipalityIds = new Set();
        const districtCodes = new Set();
        let maxLevel = 0;

        for (const feature of features) {
          maxLevel = Math.max(maxLevel, Number(feature.level) || 0);
          for (const municipalityId of Array.isArray(feature.municipalityIds) ? feature.municipalityIds : []) {
            municipalityIds.add(municipalityId);
            const code = districtCode(municipalityId);
            if (code) districtCodes.add(code);
          }
        }

        return {
          warnings: features.length,
          municipalities: municipalityIds.size,
          districts: districtCodes.size,
          maxLevel,
        };
      }

      function availableDayKeys(snapshot) {
        const keys = new Set();
        const features = Array.isArray(snapshot.mapFeatures) ? snapshot.mapFeatures : [];
        for (const feature of features) {
          for (const key of featureDayKeys(feature)) {
            keys.add(key);
          }
        }
        return Array.from(keys).sort();
      }

      function featuresForDay(snapshot, key) {
        const features = Array.isArray(snapshot.mapFeatures) ? snapshot.mapFeatures : [];
        return features.filter((feature) => featureDayKeys(feature).includes(key));
      }

      function renderDayFilters(snapshot) {
        const keys = availableDayKeys(snapshot);
        dayFiltersEl.innerHTML = "";

        if (keys.length === 0) {
          const empty = document.createElement("div");
          empty.className = "empty";
          empty.textContent = "Keine Tage mit Hitzewarnungen im aktuellen Snapshot.";
          dayFiltersEl.appendChild(empty);
          return;
        }

        const stillSelected = keys.filter((key) => selectedDayKeys.has(key));
        if (selectedDayKeys.size === 0 || stillSelected.length === 0) {
          selectedDayKeys = new Set(keys);
        } else if (stillSelected.length !== selectedDayKeys.size) {
          selectedDayKeys = new Set(stillSelected);
        }

        for (const key of keys) {
          const features = featuresForDay(snapshot, key);
          const summary = summarizeFeatures(features);
          const label = document.createElement("label");
          label.className = "day-filter";
          const checkbox = document.createElement("input");
          checkbox.type = "checkbox";
          checkbox.value = key;
          checkbox.checked = selectedDayKeys.has(key);

          const body = document.createElement("div");
          const title = document.createElement("strong");
          title.textContent = dayLabel(key);
          const details = document.createElement("span");
          details.textContent =
            summary.warnings + " Warnung(en) · " +
            summary.municipalities + " Gemeinde(n) · " +
            summary.districts + " Bezirk(e)";

          body.appendChild(title);
          body.appendChild(details);
          label.appendChild(checkbox);
          label.appendChild(body);
          dayFiltersEl.appendChild(label);
        }
      }

      function renderMapSummary(snapshot) {
        const features = selectedFeatures(snapshot);
        const summary = summarizeFeatures(features);
        const entries = [
          ["Ausgewählte Tage", String(selectedDayKeys.size)],
          ["Warnungen", String(summary.warnings)],
          ["Gemeinden", String(summary.municipalities)],
          ["Bezirke", String(summary.districts)],
          ["Max. Stufe", summary.maxLevel > 0 ? "Stufe " + summary.maxLevel : "Keine"],
        ];

        mapSummaryEl.innerHTML = "";
        for (const [label, value] of entries) {
          const cell = document.createElement("div");
          const lbl = document.createElement("strong");
          lbl.textContent = label;
          const val = document.createElement("span");
          val.textContent = value;
          cell.appendChild(lbl);
          cell.appendChild(val);
          mapSummaryEl.appendChild(cell);
        }
      }

      function renderMap(snapshot) {
        const districtFeatures = Array.isArray(snapshot.districtFeatures) ? snapshot.districtFeatures : [];
        const municipalityFeatures = Array.isArray(snapshot.municipalityFeatures) ? snapshot.municipalityFeatures : [];
        const allFeatures = Array.isArray(snapshot.mapFeatures) ? snapshot.mapFeatures : [];
        const features = selectedFeatures(snapshot);
        const districtRings = collectMapRings(districtFeatures);
        const municipalityRings = collectMapRings(municipalityFeatures);
        const baseRings = municipalityRings.length > 0
          ? municipalityRings
          : districtRings.length > 0
            ? districtRings
            : collectMapRings(allFeatures);
        const rings = collectMapRings(features);

        mapCanvasEl.innerHTML = "";
        hideMapHover();
        mapSvgEl = null;
        districtBoundsById = new Map();
        municipalityBoundsById = new Map();

        if (baseRings.length === 0) {
          const empty = document.createElement("div");
          empty.className = "map-empty";
          empty.textContent = "Keine Warnpolygone im aktuellen Snapshot.";
          mapCanvasEl.appendChild(empty);
          return;
        }

        const width = 1000;
        const height = 620;
        const padding = 32;
        const austriaBounds = {
          minX: 100000,
          maxX: 690000,
          minY: 250000,
          maxY: 580000,
        };
        const minX = austriaBounds.minX;
        const maxX = austriaBounds.maxX;
        const minY = austriaBounds.minY;
        const maxY = austriaBounds.maxY;
        const scale = Math.min(
          (width - padding * 2) / Math.max(1, maxX - minX),
          (height - padding * 2) / Math.max(1, maxY - minY)
        );
        const usedWidth = (maxX - minX) * scale;
        const usedHeight = (maxY - minY) * scale;
        const offsetX = (width - usedWidth) / 2;
        const offsetY = (height - usedHeight) / 2;

        const project = ([x, y]) => [
          offsetX + (x - minX) * scale,
          height - (offsetY + (y - minY) * scale),
        ];

        const svg = document.createElementNS("http://www.w3.org/2000/svg", "svg");
        svg.setAttribute("viewBox", "0 0 " + width + " " + height);
        svg.setAttribute("role", "img");
        svg.setAttribute("aria-label", "Karte der aktuellen Hitzewarnungen in Österreich");
        attachMapPanHandlers(svg);

        const districtLevels = districtAggregates(snapshot);
        const municipalityLevels = municipalityAggregates(snapshot);

        if (municipalityRings.length > 0) {
          const byMunicipality = new Map();
          for (const ring of municipalityRings) {
            const municipality = ring.feature;
            const entry = byMunicipality.get(municipality.id) || { municipality, paths: [], bounds: null };
            const projected = ring.points.map(project);
            entry.bounds = mergeBounds(entry.bounds, boundsForPoints(projected));
            entry.paths.push(projected.map(([x, y], index) =>
              (index === 0 ? "M" : "L") + x.toFixed(1) + " " + y.toFixed(1)
            ).join(" ") + " Z");
            byMunicipality.set(municipality.id, entry);
          }

          for (const entry of byMunicipality.values()) {
            const aggregate = municipalityLevels.get(entry.municipality.id);
            const level = aggregate ? aggregate.maxLevel : 0;
            const path = document.createElementNS("http://www.w3.org/2000/svg", "path");
            path.setAttribute("class", "map-municipality level-" + level);
            path.setAttribute("d", entry.paths.join(" "));
            path.setAttribute("data-municipality-id", entry.municipality.id);
            path.setAttribute("tabindex", "0");
            if (entry.bounds) {
              municipalityBoundsById.set(entry.municipality.id, entry.bounds);
            }

            const detail = aggregate
              ? "Stufe " + level + " · " + aggregate.warningIds.size + " Warnung(en)"
              : "Keine Hitzewarnung";
            const title = document.createElementNS("http://www.w3.org/2000/svg", "title");
            title.textContent = entry.municipality.id + " · " + entry.municipality.name + " · " + detail;
            path.appendChild(title);
            path.addEventListener("mouseenter", (event) => {
              showMapHover(event, entry.municipality.name, entry.municipality.id + " · " + detail);
            });
            path.addEventListener("mouseover", (event) => {
              showMapHover(event, entry.municipality.name, entry.municipality.id + " · " + detail);
            });
            path.addEventListener("pointerenter", (event) => {
              showMapHover(event, entry.municipality.name, entry.municipality.id + " · " + detail);
            });
            path.addEventListener("pointermove", moveMapHover);
            path.addEventListener("pointerleave", hideMapHover);
            path.addEventListener("mousemove", moveMapHover);
            path.addEventListener("mouseleave", hideMapHover);
            path.addEventListener("click", () => {
              const area = { ...entry.municipality, kind: "municipality" };
              districtSearchEl.value = areaLabel(area);
              selectArea(area);
            });
            svg.appendChild(path);
          }
        } else if (districtRings.length > 0) {
          const byDistrict = new Map();
          for (const ring of districtRings) {
            const district = ring.feature;
            const entry = byDistrict.get(district.id) || { district, paths: [], bounds: null };
            const projected = ring.points.map(project);
            entry.bounds = mergeBounds(entry.bounds, boundsForPoints(projected));
            entry.paths.push(projected.map(([x, y], index) =>
              (index === 0 ? "M" : "L") + x.toFixed(1) + " " + y.toFixed(1)
            ).join(" ") + " Z");
            byDistrict.set(district.id, entry);
          }

          for (const entry of byDistrict.values()) {
            const aggregate = districtLevels.get(entry.district.id);
            const level = aggregate ? aggregate.maxLevel : 0;
            const path = document.createElementNS("http://www.w3.org/2000/svg", "path");
            path.setAttribute("class", "map-district level-" + level);
            path.setAttribute("d", entry.paths.join(" "));
            path.setAttribute("data-district-id", entry.district.id);
            path.setAttribute("tabindex", "0");
            if (entry.bounds) {
              districtBoundsById.set(entry.district.id, entry.bounds);
            }

            const title = document.createElementNS("http://www.w3.org/2000/svg", "title");
            title.textContent = aggregate
              ? entry.district.id + " · " + entry.district.name + " · Stufe " + level
              : entry.district.id + " · " + entry.district.name + " · Keine Hitzewarnung";
            path.appendChild(title);
            path.addEventListener("click", () => {
              const area = { ...entry.district, kind: "district" };
              districtSearchEl.value = areaLabel(area);
              selectArea(area);
            });
            svg.appendChild(path);
          }
        } else {
          const basePath = document.createElementNS("http://www.w3.org/2000/svg", "path");
          basePath.setAttribute("class", "map-district level-0");
          basePath.setAttribute(
            "d",
            baseRings
              .map((ring) =>
                ring.points
                  .map(project)
                  .map(([x, y], index) => (index === 0 ? "M" : "L") + x.toFixed(1) + " " + y.toFixed(1))
                  .join(" ") + " Z"
              )
              .join(" ")
          );
          const baseTitle = document.createElementNS("http://www.w3.org/2000/svg", "title");
          baseTitle.textContent = "Keine Hitzewarnung in nicht farbig überlagerten Bereichen";
          basePath.appendChild(baseTitle);
          svg.appendChild(basePath);
        }

        const byFeature = new Map();
        for (const ring of rings) {
          const entry = byFeature.get(ring.feature.id) || { feature: ring.feature, paths: [] };
          const projected = ring.points.map(project);
          entry.paths.push(projected.map(([x, y], index) =>
            (index === 0 ? "M" : "L") + x.toFixed(1) + " " + y.toFixed(1)
          ).join(" ") + " Z");
          byFeature.set(ring.feature.id, entry);
        }

        for (const entry of byFeature.values()) {
          const path = document.createElementNS("http://www.w3.org/2000/svg", "path");
          path.setAttribute(
            "class",
            municipalityRings.length > 0 || districtRings.length > 0
              ? "map-warning-outline"
              : "map-feature level-" + entry.feature.level
          );
          path.setAttribute("d", entry.paths.join(" "));

          const title = document.createElementNS("http://www.w3.org/2000/svg", "title");
          title.textContent =
            entry.feature.id +
            " · Stufe " + entry.feature.level +
            " · " + entry.feature.municipalityCount + " Gemeinde(n)" +
            " · " + formatTime(entry.feature.start) + " → " + formatTime(entry.feature.end);
          path.appendChild(title);
          svg.appendChild(path);
        }

        mapSvgEl = svg;
        mapCanvasEl.appendChild(svg);
        if (
          selectedArea &&
          (
            (selectedArea.kind === "municipality" && municipalityBoundsById.has(selectedArea.id)) ||
            (selectedArea.kind === "district" && districtBoundsById.has(selectedArea.id))
          )
        ) {
          selectArea(selectedArea);
        } else {
          applyViewBox(currentViewBox);
        }
      }

      function renderMunicipalities(snapshot) {
        municipalitiesEl.innerHTML = "";
        const municipalities = selectedMunicipalities(snapshot);

        if (municipalities.length === 0) {
          const empty = document.createElement("div");
          empty.className = "empty";
          empty.textContent = selectedDayKeys.size === 0
            ? "Keine Tage ausgewählt."
            : "Keine Hitzewarnungen in der aktuellen Tagesauswahl.";
          municipalitiesEl.appendChild(empty);
          return;
        }

        for (const m of municipalities) {
          const row = document.createElement("div");
          row.className = "municipality";

          const badge = document.createElement("span");
          badge.className = "badge level-" + m.maxLevel;
          badge.textContent = "Stufe " + m.maxLevel;

          const middle = document.createElement("div");
          const title = document.createElement("div");
          title.className = "title";
          title.textContent = m.municipalityId + " · " + m.name;
          middle.appendChild(title);

          const time = document.createElement("div");
          time.className = "time";
          time.textContent = formatTime(m.start) + " → " + formatTime(m.end);
          middle.appendChild(time);

          if (m.contributingWarningIds.length > 0) {
            const details = document.createElement("details");
            const summary = document.createElement("summary");
            summary.textContent = m.contributingWarningIds.length + " beitragende Warnung(en)";
            details.appendChild(summary);
            const list = document.createElement("ul");
            for (const id of m.contributingWarningIds) {
              const li = document.createElement("li");
              li.textContent = id;
              list.appendChild(li);
            }
            details.appendChild(list);
            middle.appendChild(details);
          }

          const right = document.createElement("div");
          right.className = "right";
          right.textContent = m.contributingWarningIds.length + " Warnung(en)";

          row.appendChild(badge);
          row.appendChild(middle);
          row.appendChild(right);
          municipalitiesEl.appendChild(row);
        }
      }

      async function loadSnapshot() {
        refreshButton.disabled = true;
        statusEl.textContent = "Lade…";

        try {
          const response = await fetch("/test/warnings/data", { cache: "no-store" });
          const result = await response.json();

          if (!response.ok) {
            throw new Error(
              (result && (result.message || result.errorCode)) || "Snapshot konnte nicht geladen werden."
            );
          }

          setError("");
          currentSnapshot = result;
          renderMeta(result);
          renderDayFilters(result);
          renderDistrictSearchOptions(result);
          renderMapSummary(result);
          renderMap(result);
          renderMunicipalities(result);
          statusEl.textContent =
            "Zuletzt geladen: " + formatTime(result.fetchedAt) + " · Dauer: " + result.durationMs + " ms";
        } catch (error) {
          setError(error instanceof Error ? error.message : String(error));
          statusEl.textContent = "Letzter Versuch fehlgeschlagen.";
        } finally {
          refreshButton.disabled = false;
        }
      }

      refreshButton.addEventListener("click", () => {
        void loadSnapshot();
      });

      dayFiltersEl.addEventListener("change", (event) => {
        const target = event.target;
        if (!(target instanceof HTMLInputElement) || target.type !== "checkbox" || !currentSnapshot) {
          return;
        }

        if (target.checked) {
          selectedDayKeys.add(target.value);
        } else {
          selectedDayKeys.delete(target.value);
        }

        renderMapSummary(currentSnapshot);
        renderMap(currentSnapshot);
        renderMunicipalities(currentSnapshot);
      });

      districtSearchEl.addEventListener("change", () => {
        const area = findAreaBySearchValue(districtSearchEl.value);
        if (area) {
          districtSearchEl.value = areaLabel(area);
          selectArea(area);
        } else if (!districtSearchEl.value.trim()) {
          resetMapView();
        }
      });

      districtSearchEl.addEventListener("keydown", (event) => {
        if (event.key !== "Enter") {
          return;
        }
        event.preventDefault();
        const area = findAreaBySearchValue(districtSearchEl.value);
        if (area) {
          districtSearchEl.value = areaLabel(area);
          selectArea(area);
        }
      });

      zoomInButton.addEventListener("click", () => {
        zoomMap(0.72);
      });

      zoomOutButton.addEventListener("click", () => {
        zoomMap(1.38);
      });

      zoomResetButton.addEventListener("click", () => {
        resetMapView();
      });

      void loadSnapshot();
    </script>
  </body>
</html>`;
}
if (developMode) {
    app.get("/test", (_req, res) => {
        res.redirect("/test/push/ui");
    });
    app.get("/test/push/ui", (_req, res) => {
        res.setHeader("Cache-Control", "no-store, no-cache, must-revalidate, proxy-revalidate");
        res.setHeader("Pragma", "no-cache");
        res.setHeader("Expires", "0");
        res.setHeader("Surrogate-Control", "no-store");
        res
            .status(200)
            .type("html")
            .send(renderTestPushPage((0, hitze_1.listTestMunicipalityOptions)(), (0, hitze_1.listSupportedPushLanguages)(), hitze_1.DEFAULT_PUSH_LANGUAGE));
    });
    app.get("/test/warnings/ui", (_req, res) => {
        res.setHeader("Cache-Control", "no-store, no-cache, must-revalidate, proxy-revalidate");
        res.setHeader("Pragma", "no-cache");
        res.setHeader("Expires", "0");
        res.setHeader("Surrogate-Control", "no-store");
        res.status(200).type("html").send(renderWarningsPage());
    });
    app.get("/test/pushover/ui", (_req, res) => {
        res.setHeader("Cache-Control", "no-store, no-cache, must-revalidate, proxy-revalidate");
        res.setHeader("Pragma", "no-cache");
        res.setHeader("Expires", "0");
        res.setHeader("Surrogate-Control", "no-store");
        res.status(200).type("html").send(renderPushoverSettingsPage());
    });
    app.get("/test/pushover/status", async (_req, res) => {
        res.setHeader("Cache-Control", "no-store, no-cache, must-revalidate, proxy-revalidate");
        res.setHeader("Pragma", "no-cache");
        res.setHeader("Expires", "0");
        res.setHeader("Surrogate-Control", "no-store");
        try {
            res.status(200).json(await (0, pushover_1.getPushoverReportStatus)());
        }
        catch (error) {
            res.status(500).json({
                errorCode: "PUSHOVER_STATUS_FAILED",
                message: error instanceof Error ? error.message : String(error),
            });
        }
    });
    app.post("/test/pushover/status", async (req, res) => {
        const enabled = req.body?.enabled;
        if (typeof enabled !== "boolean") {
            res.status(400).json({
                errorCode: "INVALID_INPUT",
                message: "enabled must be a boolean.",
            });
            return;
        }
        try {
            res.status(200).json(await (0, pushover_1.setPushoverReportsEnabled)(enabled));
        }
        catch (error) {
            res.status(500).json({
                errorCode: "PUSHOVER_STATUS_SAVE_FAILED",
                message: error instanceof Error ? error.message : String(error),
            });
        }
    });
    app.get("/test/warnings/data", async (_req, res) => {
        res.setHeader("Cache-Control", "no-store, no-cache, must-revalidate, proxy-revalidate");
        res.setHeader("Pragma", "no-cache");
        res.setHeader("Expires", "0");
        res.setHeader("Surrogate-Control", "no-store");
        try {
            const snapshot = await (0, hitze_1.loadCurrentWarningsSnapshot)();
            res.status(200).json({
                ...snapshot,
                districtFeatures: loadPoliticalDistrictFeatures(),
                municipalityFeatures: loadMunicipalityFeatures(),
            });
        }
        catch (error) {
            const err = error;
            const status = typeof err?.status === "number" ? err.status : 500;
            res.status(status).json({
                errorCode: err?.code ?? "WARNINGS_SNAPSHOT_FAILED",
                message: error instanceof Error ? error.message : String(error),
            });
        }
    });
    app.post("/test/push", async (req, res) => {
        const municipalityId = typeof req.body?.municipalityId === "string" ? req.body.municipalityId : "";
        const title = typeof req.body?.title === "string" ? req.body.title : undefined;
        const body = typeof req.body?.body === "string" ? req.body.body : undefined;
        const parsedLang = parseLanguageFromBody(req.body?.lang);
        if (!parsedLang.ok) {
            res.status(400).json({
                errorCode: "INVALID_INPUT",
                message: parsedLang.message,
            });
            return;
        }
        if (!municipalityId.trim()) {
            res.status(400).json({
                errorCode: "INVALID_INPUT",
                message: "municipalityId is required in JSON body.",
            });
            return;
        }
        try {
            const result = await (0, hitze_1.sendTestPushNotification)({
                municipalityId,
                title,
                body,
                languageCode: parsedLang.value,
            });
            res.status(200).json({
                ok: true,
                municipalityId: municipalityId.trim(),
                topic: result.topic,
                lang: result.languageCode,
                messageId: result.messageId,
            });
        }
        catch (error) {
            res.status(500).json({
                errorCode: "TEST_PUSH_FAILED",
                message: error instanceof Error ? error.message : String(error),
            });
        }
    });
    app.post("/test/push/bulk", async (req, res) => {
        const municipalityIdsRaw = Array.isArray(req.body?.municipalityIds)
            ? req.body.municipalityIds
            : [];
        const municipalityIds = municipalityIdsRaw.filter((entry) => typeof entry === "string");
        const title = typeof req.body?.title === "string" ? req.body.title : undefined;
        const body = typeof req.body?.body === "string" ? req.body.body : undefined;
        const parsedLang = parseLanguageFromBody(req.body?.lang);
        if (!parsedLang.ok) {
            res.status(400).json({
                errorCode: "INVALID_INPUT",
                message: parsedLang.message,
            });
            return;
        }
        if (municipalityIds.length === 0) {
            res.status(400).json({
                errorCode: "INVALID_INPUT",
                message: "municipalityIds must contain at least one string.",
            });
            return;
        }
        try {
            const result = await (0, hitze_1.sendTestPushNotifications)({
                municipalityIds,
                title,
                body,
                languageCode: parsedLang.value,
            });
            res.status(200).json({
                ok: true,
                lang: parsedLang.value,
                sentCount: result.sent.length,
                failedCount: result.failed.length,
                recipients: result.sent,
                failures: result.failed,
            });
        }
        catch (error) {
            res.status(500).json({
                errorCode: "TEST_PUSH_BULK_FAILED",
                message: error instanceof Error ? error.message : String(error),
            });
        }
    });
    app.post("/test/push/token", async (req, res) => {
        const token = typeof req.body?.token === "string" ? req.body.token : "";
        const title = typeof req.body?.title === "string" ? req.body.title : undefined;
        const body = typeof req.body?.body === "string" ? req.body.body : undefined;
        const parsedLang = parseLanguageFromBody(req.body?.lang);
        if (!parsedLang.ok) {
            res.status(400).json({
                errorCode: "INVALID_INPUT",
                message: parsedLang.message,
            });
            return;
        }
        if (!token.trim()) {
            res.status(400).json({
                errorCode: "INVALID_INPUT",
                message: "token is required in JSON body.",
            });
            return;
        }
        try {
            const result = await (0, hitze_1.sendTestPushToToken)({
                token,
                title,
                body,
                languageCode: parsedLang.value,
            });
            res.status(200).json({
                ok: true,
                lang: parsedLang.value,
                tokenSuffix: result.token.slice(-10),
                messageId: result.messageId,
            });
        }
        catch (error) {
            const err = error;
            res.status(500).json({
                errorCode: "TEST_PUSH_TOKEN_FAILED",
                message: error instanceof Error ? error.message : String(error),
                firebaseCode: err?.code,
                firebaseErrorInfo: err?.errorInfo,
                firebaseStatusCode: err?.statusCode,
                firebaseDetails: err?.details,
            });
        }
    });
}
app.listen(port, "0.0.0.0", () => {
    console.log(`Hitze backend listening on port ${port} (develop mode: ${developMode})`);
    if ((0, pushover_1.isPushoverConfigured)()) {
        console.log("Pushover reports configured");
    }
    else {
        console.log("Pushover reports disabled (set PUSHOVER_APP_TOKEN and PUSHOVER_USER_KEY to enable)");
    }
});
