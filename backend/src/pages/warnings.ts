import { NAV_CSS, renderTopNav, THEME_CSS, AUTH_SCRIPT } from "./common";

export function renderWarningsPage(): string {
  return `<!doctype html>
<html lang="de">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>HitzeV · Aktuelle Warnungen</title>
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
        background: var(--panel-glass);
        border: 1px solid var(--line);
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
        background: var(--field);
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
        background: var(--field);
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
          var(--map-bg);
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
        background: var(--field);
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
        stroke: var(--map-stroke);
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
        stroke: var(--map-stroke);
        stroke-width: 1.4;
        pointer-events: none;
        vector-effect: non-scaling-stroke;
      }

      .map-district:hover,
      .map-municipality:hover,
      .map-feature:hover {
        stroke: var(--map-stroke-strong);
        stroke-width: 1.6;
      }

      .map-district.selected,
      .map-municipality.selected {
        stroke: var(--map-stroke-strong);
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
        border: 1px solid var(--map-stroke);
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
        background: var(--field);
        padding: 9px 10px;
        font-size: 0.86rem;
      }

      .map-feature-item {
        border: 1px solid var(--line);
        border-radius: 14px;
        background: var(--field);
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
        background: var(--field);
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
${THEME_CSS}
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

${AUTH_SCRIPT}
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
          const response = await hitzeFetch("/test/warnings/data", { cache: "no-store" });
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
