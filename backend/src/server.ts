import express, { type Request, type Response } from "express";
import { isEnvFlagEnabled } from "../api/cron/env";
import { isPushoverConfigured } from "../api/cron/pushover";
import {
  DEFAULT_PUSH_LANGUAGE,
  executeHitzeCron,
  listTestMunicipalityOptions,
  listSupportedPushLanguages,
  loadCurrentWarningsSnapshot,
  parseSupportedPushLanguage,
  sendTestPushNotification,
  sendTestPushNotifications,
  sendTestPushToToken,
  type SupportedPushLanguage,
  type TestMunicipalityOption,
} from "../api/cron/hitze";

const app = express();
app.use(express.json());

const port = Number(process.env.PORT ?? "3000");
const cronSecret = process.env.CRON_SECRET?.trim();
const developMode = isEnvFlagEnabled(process.env.develop) || isEnvFlagEnabled(process.env.DEVELOP);

if (!cronSecret) {
  console.error(
    [
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
    ].join("\n")
  );
  process.exit(1);
}

function isAuthorized(req: Request): boolean {
  const header = req.header("authorization") ?? "";
  return header === `Bearer ${cronSecret}`;
}

function parseLanguageFromBody(rawValue: unknown): {
  ok: true;
  value: SupportedPushLanguage | undefined;
} | {
  ok: false;
  message: string;
} {
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

  const parsed = parseSupportedPushLanguage(trimmed);
  if (!parsed) {
    return { ok: false, message: `Unsupported lang '${trimmed}'.` };
  }

  return { ok: true, value: parsed };
}

app.get("/health", (_req: Request, res: Response) => {
  res.status(200).json({ ok: true });
});

app.post("/cron/hitze", async (req: Request, res: Response) => {
  if (!isAuthorized(req)) {
    res.status(401).json({
      errorCode: "UNAUTHORIZED",
      message: "Missing or invalid Authorization header.",
    });
    return;
  }

  const result = await executeHitzeCron(req.method);
  if (result.headers) {
    for (const [key, value] of Object.entries(result.headers)) {
      res.setHeader(key, value);
    }
  }

  res.status(result.status).json(result.body);
});

function renderTestPushPage(
  municipalities: TestMunicipalityOption[],
  supportedLanguages: SupportedPushLanguage[],
  defaultLanguage: SupportedPushLanguage
): string {
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
    </style>
  </head>
  <body>
    <main>
      <h1>Hitze-V Testversand</h1>
      <p><a href="/test/warnings/ui">→ Aktuelle Warnungen ansehen</a></p>

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

function renderWarningsPage(): string {
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
        --level-1: #f0d28a;
        --level-2: #e5933b;
        --level-3: #c74b2a;
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
        .municipality {
          grid-template-columns: 50px 1fr;
        }
        .municipality .right {
          grid-column: 1 / -1;
          text-align: left;
        }
      }
    </style>
  </head>
  <body>
    <main>
      <h1>Aktuelle Hitzewarnungen</h1>
      <p>Live-Snapshot direkt aus der GeoSphere-API · keine Pushes, kein Redis-Write. <a href="/test/push/ui">→ Zum Testversand</a></p>

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

      const timeFmt = new Intl.DateTimeFormat("de-AT", {
        timeZone: "Europe/Vienna",
        dateStyle: "short",
        timeStyle: "short",
      });

      function formatTime(iso) {
        if (!iso) return "—";
        const date = new Date(iso);
        if (Number.isNaN(date.getTime())) return iso;
        return timeFmt.format(date);
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

      function renderMunicipalities(snapshot) {
        municipalitiesEl.innerHTML = "";

        if (snapshot.affectedMunicipalities.length === 0) {
          const empty = document.createElement("div");
          empty.className = "empty";
          empty.textContent = "Aktuell keine Hitzewarnungen über Stufe " + snapshot.minWarningLevel + ".";
          municipalitiesEl.appendChild(empty);
          return;
        }

        for (const m of snapshot.affectedMunicipalities) {
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
          renderMeta(result);
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

      void loadSnapshot();
    </script>
  </body>
</html>`;
}

if (developMode) {
  app.get("/test", (_req: Request, res: Response) => {
    res.redirect("/test/push/ui");
  });

  app.get("/test/push/ui", (_req: Request, res: Response) => {
    res.setHeader("Cache-Control", "no-store, no-cache, must-revalidate, proxy-revalidate");
    res.setHeader("Pragma", "no-cache");
    res.setHeader("Expires", "0");
    res.setHeader("Surrogate-Control", "no-store");
    res
      .status(200)
      .type("html")
      .send(
        renderTestPushPage(
          listTestMunicipalityOptions(),
          listSupportedPushLanguages(),
          DEFAULT_PUSH_LANGUAGE
        )
      );
  });

  app.get("/test/warnings/ui", (_req: Request, res: Response) => {
    res.setHeader("Cache-Control", "no-store, no-cache, must-revalidate, proxy-revalidate");
    res.setHeader("Pragma", "no-cache");
    res.setHeader("Expires", "0");
    res.setHeader("Surrogate-Control", "no-store");
    res.status(200).type("html").send(renderWarningsPage());
  });

  app.get("/test/warnings/data", async (_req: Request, res: Response) => {
    res.setHeader("Cache-Control", "no-store, no-cache, must-revalidate, proxy-revalidate");
    res.setHeader("Pragma", "no-cache");
    res.setHeader("Expires", "0");
    res.setHeader("Surrogate-Control", "no-store");

    try {
      const snapshot = await loadCurrentWarningsSnapshot();
      res.status(200).json(snapshot);
    } catch (error) {
      const err = error as { status?: number; code?: string } | undefined;
      const status = typeof err?.status === "number" ? err.status : 500;
      res.status(status).json({
        errorCode: err?.code ?? "WARNINGS_SNAPSHOT_FAILED",
        message: error instanceof Error ? error.message : String(error),
      });
    }
  });

  app.post("/test/push", async (req: Request, res: Response) => {
    const municipalityId =
      typeof req.body?.municipalityId === "string" ? req.body.municipalityId : "";
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
      const result = await sendTestPushNotification({
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
    } catch (error) {
      res.status(500).json({
        errorCode: "TEST_PUSH_FAILED",
        message: error instanceof Error ? error.message : String(error),
      });
    }
  });

  app.post("/test/push/bulk", async (req: Request, res: Response) => {
    const municipalityIdsRaw: unknown[] = Array.isArray(req.body?.municipalityIds)
      ? req.body.municipalityIds
      : [];
    const municipalityIds = municipalityIdsRaw.filter(
      (entry: unknown): entry is string => typeof entry === "string"
    );
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
      const result = await sendTestPushNotifications({
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
    } catch (error) {
      res.status(500).json({
        errorCode: "TEST_PUSH_BULK_FAILED",
        message: error instanceof Error ? error.message : String(error),
      });
    }
  });

  app.post("/test/push/token", async (req: Request, res: Response) => {
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
      const result = await sendTestPushToToken({
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
    } catch (error) {
      const err = error as
        | (Error & {
            code?: string;
            errorInfo?: { code?: string; message?: string };
            details?: unknown;
            statusCode?: number;
          })
        | undefined;

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
  if (isPushoverConfigured()) {
    console.log("Pushover reports enabled");
  } else {
    console.log(
      "Pushover reports disabled (set PUSHOVER_APP_TOKEN and PUSHOVER_USER_KEY to enable)"
    );
  }
});
