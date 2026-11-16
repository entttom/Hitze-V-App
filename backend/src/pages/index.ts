import { NAV_CSS, renderTopNav, THEME_CSS } from "./common";

export function renderDevelopIndexPage(): string {
  const developCards = `
          <a class="card" href="/test/push/ui">
            <h2>Testversand</h2>
            <p>Test-Pushes an einzelne oder mehrere Gemeinden senden: v2-Topic oder Legacy-Topic je Sprache.</p>
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
          </a>`;

  return `<!doctype html>
<html lang="de">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>HitzeV Backend</title>
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
      }

      * { box-sizing: border-box; }

      body {
        margin: 0;
        font-family: "Avenir Next", "Segoe UI", sans-serif;
        background:
          radial-gradient(circle at top right, rgba(199, 75, 42, 0.15), transparent 30%),
          linear-gradient(180deg, var(--bg-top) 0%, var(--bg) 100%);
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
        background: var(--panel-glass);
        border: 1px solid var(--line);
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
${THEME_CSS}
    </style>
  </head>
  <body>
    <main>
      ${renderTopNav("/test")}
      <h1>HitzeV Backend<span class="mode-pill on">develop</span></h1>
      <p class="subtitle">Develop-Oberflächen. Alle Daten- und Versand-Endpunkte verlangen <code>Authorization: Bearer &lt;CRON_SECRET&gt;</code>; die Seiten fragen einmal pro Browser-Sitzung danach.</p>

      <div class="grid">
${developCards}

          <div class="card card--muted">
            <h2>Health-Check</h2>
            <p>Liveness ohne Abhängigkeiten (<code>GET /health</code>) und Readiness mit Redis-PING und Firebase-Initialisierung (<code>GET /ready</code>).</p>
            <span class="arrow"><a href="/health">GET /health</a> · <a href="/ready">GET /ready</a></span>
          </div>

          <div class="card card--muted">
            <h2>Cron-Trigger</h2>
            <p>Wird vom Scheduler aufgerufen (empfohlen alle 10 Minuten): <code>POST</code> mit <code>Authorization: Bearer &lt;CRON_SECRET&gt;</code>. Pushes zwischen 20:00 und 06:00 (Wien) werden zurückgestellt.</p>
            <span class="arrow">POST /cron/hitze</span>
          </div>
      </div>
    </main>
  </body>
</html>`;
}

/** Public root page: no endpoint list, no develop status. */
export function renderRootPage(): string {
  return `<!doctype html>
<html lang="de">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <meta name="color-scheme" content="light dark" />
    <title>HitzeV Backend</title>
    <style>
      body { margin: 0; font-family: "Avenir Next", "Segoe UI", sans-serif; background: #f4efe7; color: #2b241c; }
      main { max-width: 640px; margin: 0 auto; padding: 48px 20px; }
      @media (prefers-color-scheme: dark) { body { background: #15120f; color: #f2ebe2; } }
    </style>
  </head>
  <body>
    <main>
      <h1>HitzeV Backend</h1>
      <p>Interner Dienst ohne öffentliche Oberfläche.</p>
    </main>
  </body>
</html>`;
}
