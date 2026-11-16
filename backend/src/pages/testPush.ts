import { NAV_CSS, renderTopNav, THEME_CSS, AUTH_SCRIPT } from "./common";

export function renderTestPushPage(maxBulkIds: number): string {

  return `<!doctype html>
<html lang="de">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>HitzeV Testversand</title>
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
          linear-gradient(180deg, var(--bg-top) 0%, var(--bg) 100%);
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
        background: var(--panel-glass);
        border: 1px solid var(--line);
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
        background: var(--field);
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
        background: var(--field);
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
${THEME_CSS}
    </style>
  </head>
  <body>
    <main>
      ${renderTopNav("/test/push/ui")}
      <h1>HitzeV Testversand</h1>

      <div class="layout">
        <section class="panel stack">
          <div>
            <h2>Nachricht</h2>
            <p>Format <strong>v2</strong> sendet eine Datennachricht (<code>type=test</code>) an <code>warngebiet_v2_&lt;GKZ&gt;</code>; die App rendert den Text selbst, Titel/Text unten ersetzen nur den deutschen iOS-Fallback. <strong>Legacy</strong> sendet an <code>warngebiet_&lt;GKZ&gt;_&lt;Sprache&gt;</code> mit sichtbarem Titel/Text (leer = Testtext aus push-copy.json). Höchstens ${maxBulkIds} Gemeinden pro Versand.</p>
          </div>

          <label>
            Format
            <select id="format">
              <option value="v2" selected>v2 (warngebiet_v2_&lt;GKZ&gt;)</option>
              <option value="legacy">Legacy (warngebiet_&lt;GKZ&gt;_&lt;Sprache&gt;)</option>
            </select>
          </label>

          <label>
            Sprache (nur Legacy)
            <select id="lang"></select>
          </label>

          <label>
            Titel (optional)
            <input id="title" type="text" value="" placeholder="leer = Testtitel aus push-copy.json" />
          </label>

          <label>
            Nachricht (optional)
            <textarea id="body" placeholder="leer = Testtext aus push-copy.json"></textarea>
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

${AUTH_SCRIPT}
    <script>
      const maxBulkIds = ${maxBulkIds};
      let municipalities = [];
      let supportedLanguages = ["de"];
      let defaultLanguage = "de";
      const selectedIds = new Set();
      const formatSelect = document.getElementById("format");

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

      function selectedFormat() {
        return formatSelect.value === "legacy" ? "legacy" : "v2";
      }

      function topicFor(municipalityId) {
        return selectedFormat() === "v2"
          ? "warngebiet_v2_" + municipalityId
          : "warngebiet_" + municipalityId + "_" + selectedLanguage();
      }

      function fillLanguages() {
        languageSelect.innerHTML = "";
        for (const languageCode of supportedLanguages) {
          const option = document.createElement("option");
          option.value = languageCode;
          option.textContent = languageCode;
          option.selected = languageCode === defaultLanguage;
          languageSelect.appendChild(option);
        }
        languageSelect.disabled = selectedFormat() === "v2";
      }

      async function loadOptions() {
        meta.textContent = "Gemeinden werden geladen…";
        try {
          const response = await hitzeFetch("/test/push/options");
          const result = await response.json();
          if (!response.ok) {
            throw new Error(result.message || "Optionen konnten nicht geladen werden.");
          }
          municipalities = result.municipalities;
          supportedLanguages = result.languages;
          defaultLanguage = result.defaultLegacyLanguage;
          fillLanguages();
          render();
        } catch (error) {
          setStatus(error instanceof Error ? error.message : String(error), "error");
        }
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
          selectedIds.size + " Empfänger ausgewählt (max. " + maxBulkIds + ") · Format: " + selectedFormat() +
          (selectedFormat() === "legacy" ? " · Sprache: " + selectedLanguage() : "");
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
          const heading = document.createElement("strong");
          heading.textContent = municipality.municipalityId + " · " + municipality.name;
          const topic = document.createElement("small");
          topic.textContent = "Topic " + topicFor(municipality.municipalityId);
          text.appendChild(heading);
          text.appendChild(topic);

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
      formatSelect.addEventListener("change", () => {
        languageSelect.disabled = selectedFormat() === "v2";
        render();
      });

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
        if (municipalityIds.length > maxBulkIds) {
          setStatus("Höchstens " + maxBulkIds + " Empfänger pro Versand.", "error");
          return;
        }

        sendButton.disabled = true;

        try {
          const response = await hitzeFetch("/test/push/bulk", {
            method: "POST",
            headers: {
              "Content-Type": "application/json",
            },
            body: JSON.stringify({
              municipalityIds,
              format: selectedFormat(),
              title: titleInput.value,
              body: bodyInput.value,
              lang: selectedFormat() === "legacy" ? selectedLanguage() : undefined,
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

      void loadOptions();
    </script>
  </body>
</html>`;
}
