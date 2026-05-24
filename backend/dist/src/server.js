"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importDefault(require("express"));
const env_1 = require("../api/cron/env");
const pushover_1 = require("../api/cron/pushover");
const hitze_1 = require("../api/cron/hitze");
const app = (0, express_1.default)();
app.use(express_1.default.json());
const port = Number(process.env.PORT ?? "3000");
const cronSecret = process.env.CRON_SECRET?.trim();
const developMode = (0, env_1.isEnvFlagEnabled)(process.env.develop) || (0, env_1.isEnvFlagEnabled)(process.env.DEVELOP);
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
        display: grid;
        grid-template-columns: minmax(0, 1fr) 300px;
        gap: 16px;
        align-items: start;
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

      .map-frame {
        min-height: 430px;
        border-radius: 18px;
        border: 1px solid var(--line);
        background:
          radial-gradient(circle at 50% 48%, rgba(138, 191, 120, 0.28), transparent 58%),
          linear-gradient(180deg, rgba(232, 247, 224, 0.94), rgba(250, 255, 247, 0.98));
        overflow: hidden;
        position: relative;
      }

      .map-frame svg {
        display: block;
        width: 100%;
        height: auto;
        min-height: 430px;
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

      .map-base {
        fill: rgba(138, 191, 120, 0.2);
        stroke: rgba(72, 118, 69, 0.48);
        stroke-width: 1;
        vector-effect: non-scaling-stroke;
      }

      .map-feature.level-2 {
        fill: rgba(229, 147, 59, 0.76);
      }

      .map-feature.level-3 {
        fill: rgba(199, 75, 42, 0.8);
      }

      .map-feature.level-4 {
        fill: rgba(126, 32, 18, 0.86);
      }

      .map-feature:hover {
        stroke: rgba(43, 36, 28, 0.9);
        stroke-width: 2;
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
          <div id="map" class="map-frame"></div>
          <aside class="map-side">
            <div class="legend">
              <div class="legend-row"><span class="legend-swatch level-0"></span><span>Keine Hitzewarnung</span></div>
              <div class="legend-row"><span class="legend-swatch level-2"></span><span>Stufe 2</span></div>
              <div class="legend-row"><span class="legend-swatch level-3"></span><span>Stufe 3</span></div>
              <div class="legend-row"><span class="legend-swatch level-4"></span><span>Stufe 4</span></div>
            </div>
            <div class="map-note">Grün ist die Kartenbasis ohne Hitzewarnung. Farbige Flächen sind die ausgewählten GeoSphere-Warnpolygone.</div>
            <div id="districtSummary" class="district-list"></div>
            <div id="mapFeatures" class="map-feature-list"></div>
          </aside>
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
      const districtSummaryEl = document.getElementById("districtSummary");
      const mapFeaturesEl = document.getElementById("mapFeatures");
      let currentSnapshot = null;
      let selectedDayKeys = new Set();

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

      function renderDistrictSummary(snapshot) {
        const districts = new Map();
        for (const feature of selectedFeatures(snapshot)) {
          const warningIds = new Set([feature.id]);
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
            for (const warningId of warningIds) {
              existing.warningIds.add(warningId);
            }
            existing.maxLevel = Math.max(existing.maxLevel, Number(feature.level) || 0);
            districts.set(code, existing);
          }
        }

        districtSummaryEl.innerHTML = "";

        if (districts.size === 0) {
          const empty = document.createElement("div");
          empty.className = "map-feature-item";
          empty.textContent = "Keine betroffenen Bezirke in der Tagesauswahl.";
          districtSummaryEl.appendChild(empty);
          return;
        }

        const rows = Array.from(districts.values()).sort((left, right) => {
          if (right.maxLevel !== left.maxLevel) return right.maxLevel - left.maxLevel;
          return left.code.localeCompare(right.code);
        });

        for (const district of rows) {
          const item = document.createElement("div");
          item.className = "district-item";
          const badge = document.createElement("span");
          badge.className = "badge level-" + district.maxLevel;
          badge.textContent = "Stufe " + district.maxLevel;
          const text = document.createElement("div");
          const title = document.createElement("strong");
          title.textContent = "Bezirk " + district.code;
          const details = document.createElement("span");
          details.textContent =
            district.municipalityIds.size + " Gemeinde(n) · " +
            district.warningIds.size + " Warnung(en)";
          text.appendChild(title);
          text.appendChild(details);
          item.appendChild(badge);
          item.appendChild(text);
          districtSummaryEl.appendChild(item);
        }
      }

      function renderMap(snapshot) {
        const allFeatures = Array.isArray(snapshot.mapFeatures) ? snapshot.mapFeatures : [];
        const features = selectedFeatures(snapshot);
        const baseRings = collectMapRings(allFeatures);
        const rings = collectMapRings(features);

        mapEl.innerHTML = "";
        mapFeaturesEl.innerHTML = "";

        if (baseRings.length === 0) {
          const empty = document.createElement("div");
          empty.className = "map-empty";
          empty.textContent = "Keine Warnpolygone im aktuellen Snapshot.";
          mapEl.appendChild(empty);
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

        const basePath = document.createElementNS("http://www.w3.org/2000/svg", "path");
        basePath.setAttribute("class", "map-base");
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
          path.setAttribute("class", "map-feature level-" + entry.feature.level);
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

        mapEl.appendChild(svg);

        if (features.length === 0) {
          const empty = document.createElement("div");
          empty.className = "map-feature-item";
          empty.textContent = "Keine Warnungen in der aktuellen Tagesauswahl.";
          mapFeaturesEl.appendChild(empty);
          return;
        }

        for (const feature of features) {
          const item = document.createElement("div");
          item.className = "map-feature-item";
          const title = document.createElement("strong");
          title.textContent = feature.id + " · Stufe " + feature.level;
          const meta = document.createElement("span");
          meta.textContent =
            feature.municipalityCount + " Gemeinde(n) · " +
            formatTime(feature.start) + " → " + formatTime(feature.end);
          item.appendChild(title);
          item.appendChild(meta);
          mapFeaturesEl.appendChild(item);
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
          renderMapSummary(result);
          renderDistrictSummary(result);
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
        renderDistrictSummary(currentSnapshot);
        renderMap(currentSnapshot);
        renderMunicipalities(currentSnapshot);
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
    app.get("/test/warnings/data", async (_req, res) => {
        res.setHeader("Cache-Control", "no-store, no-cache, must-revalidate, proxy-revalidate");
        res.setHeader("Pragma", "no-cache");
        res.setHeader("Expires", "0");
        res.setHeader("Surrogate-Control", "no-store");
        try {
            const snapshot = await (0, hitze_1.loadCurrentWarningsSnapshot)();
            res.status(200).json(snapshot);
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
        console.log("Pushover reports enabled");
    }
    else {
        console.log("Pushover reports disabled (set PUSHOVER_APP_TOKEN and PUSHOVER_USER_KEY to enable)");
    }
});
