"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importDefault(require("express"));
const hitze_1 = require("../api/cron/hitze");
const app = (0, express_1.default)();
app.use(express_1.default.json());
const port = Number(process.env.PORT ?? "3000");
const cronSecret = process.env.CRON_SECRET;
const developMode = isEnvFlagEnabled(process.env.develop) || isEnvFlagEnabled(process.env.DEVELOP);
function isEnvFlagEnabled(value) {
    if (!value) {
        return false;
    }
    return ["1", "true", "yes", "on"].includes(value.trim().toLowerCase());
}
function isAuthorized(req) {
    if (!cronSecret) {
        return true;
    }
    const header = req.header("authorization") ?? "";
    return header === `Bearer ${cronSecret}`;
}
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
app.get("/cron/hitze", async (req, res) => {
    const result = await (0, hitze_1.executeHitzeCron)(req.method);
    if (result.headers) {
        for (const [key, value] of Object.entries(result.headers)) {
            res.setHeader(key, value);
        }
    }
    res.status(result.status).json(result.body);
});
function renderTestPushPage(municipalities) {
    const municipalityPayload = JSON.stringify(municipalities).replace(/</g, "\\u003c");
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
      const selectedIds = new Set();

      const titleInput = document.getElementById("title");
      const bodyInput = document.getElementById("body");
      const searchInput = document.getElementById("search");
      const municipalityList = document.getElementById("municipalityList");
      const summary = document.getElementById("summary");
      const meta = document.getElementById("meta");
      const status = document.getElementById("status");
      const sendButton = document.getElementById("sendButton");
      const selectVisibleButton = document.getElementById("selectVisibleButton");
      const clearVisibleButton = document.getElementById("clearVisibleButton");
      const clearSelectionButton = document.getElementById("clearSelectionButton");

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
        summary.textContent = selectedIds.size + " Empfänger ausgewählt";
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
            "<small>Topic warngebiet_" + municipality.municipalityId + "</small>";

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
            }),
          });

          const result = await response.json();
          if (!response.ok) {
            throw new Error(result.message || "Testversand fehlgeschlagen.");
          }

          setStatus(
            "Versand erfolgreich.\\n" +
              "Empfänger: " + result.sentCount + "\\n\\n" +
              JSON.stringify(result.recipients, null, 2),
            "success"
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
if (developMode) {
    app.get("/test", (_req, res) => {
        res.redirect("/test/push/ui");
    });
    app.get("/test/push/ui", (_req, res) => {
        res.setHeader("Cache-Control", "no-store, no-cache, must-revalidate, proxy-revalidate");
        res.setHeader("Pragma", "no-cache");
        res.setHeader("Expires", "0");
        res.setHeader("Surrogate-Control", "no-store");
        res.status(200).type("html").send(renderTestPushPage((0, hitze_1.listTestMunicipalityOptions)()));
    });
    app.post("/test/push", async (req, res) => {
        const municipalityId = typeof req.body?.municipalityId === "string" ? req.body.municipalityId : "";
        const title = typeof req.body?.title === "string" ? req.body.title : undefined;
        const body = typeof req.body?.body === "string" ? req.body.body : undefined;
        if (!municipalityId.trim()) {
            res.status(400).json({
                errorCode: "INVALID_INPUT",
                message: "municipalityId is required in JSON body.",
            });
            return;
        }
        try {
            const result = await (0, hitze_1.sendTestPushNotification)({ municipalityId, title, body });
            res.status(200).json({
                ok: true,
                municipalityId: municipalityId.trim(),
                topic: result.topic,
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
        if (municipalityIds.length === 0) {
            res.status(400).json({
                errorCode: "INVALID_INPUT",
                message: "municipalityIds must contain at least one string.",
            });
            return;
        }
        try {
            const result = await (0, hitze_1.sendTestPushNotifications)({ municipalityIds, title, body });
            res.status(200).json({
                ok: true,
                sentCount: result.sent.length,
                recipients: result.sent,
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
        if (!token.trim()) {
            res.status(400).json({
                errorCode: "INVALID_INPUT",
                message: "token is required in JSON body.",
            });
            return;
        }
        try {
            const result = await (0, hitze_1.sendTestPushToToken)({ token, title, body });
            res.status(200).json({
                ok: true,
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
});
