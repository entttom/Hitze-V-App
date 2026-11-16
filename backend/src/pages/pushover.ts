import { NAV_CSS, renderTopNav, THEME_CSS, AUTH_SCRIPT } from "./common";

export function renderPushoverSettingsPage(): string {
  return `<!doctype html>
<html lang="de">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>HitzeV · Pushover</title>
    <style>
      :root {
        color-scheme: light dark;
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
        background: linear-gradient(180deg, var(--bg-top) 0%, var(--bg) 100%);
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
        background: var(--panel-glass);
        border: 1px solid var(--line);
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
        background: var(--field);
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
        background: var(--line);
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
        background: var(--success-bg);
        border-color: var(--success-line);
        color: var(--ok);
      }

      .badge.off {
        background: var(--error-bg);
        border-color: var(--error-line);
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
        background: var(--hover);
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
${THEME_CSS}
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

${AUTH_SCRIPT}
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
          const response = await hitzeFetch("/test/pushover/status", { cache: "no-store" });
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
          const response = await hitzeFetch("/test/pushover/status", {
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
