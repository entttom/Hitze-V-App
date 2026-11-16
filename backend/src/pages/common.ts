export function escapeHtml(value: string): string {
  return value
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}

export const NAV_CSS = `
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
        background: var(--hover);
      }

      .topnav a[aria-current="page"] {
        background: linear-gradient(135deg, var(--accent), var(--accent-dark));
        border-color: transparent;
        color: white;
      }

      .topnav button.logout {
        margin-left: auto;
        border: 1px solid var(--line);
        border-radius: 999px;
        padding: 8px 16px;
        background: transparent;
        color: var(--muted);
        font: inherit;
        font-size: 0.92rem;
        cursor: pointer;
      }
`;

/**
 * Light defaults for variables the pages share, and a complete dark palette.
 * Appended after each page's own :root so the dark block wins.
 */
export const THEME_CSS = `
      :root {
        --bg-top: #f9f4ec;
        --panel-glass: rgba(255, 250, 243, 0.94);
        --field: #fffdf9;
        --hover: #fff7e6;
        --success-bg: #edf8ee;
        --success-line: #8ac49a;
        --error-bg: #fff0ec;
        --error-line: #e0a090;
        --map-bg: linear-gradient(180deg, rgba(232, 247, 224, 0.94), rgba(250, 255, 247, 0.98));
        --map-stroke: rgba(61, 43, 25, 0.45);
        --map-stroke-strong: rgba(43, 36, 28, 0.9);
      }

      @media (prefers-color-scheme: dark) {
        :root {
          --bg: #15120f;
          --bg-top: #1d1914;
          --panel: #221c17;
          --panel-strong: #2b241d;
          --panel-glass: rgba(34, 28, 23, 0.94);
          --field: #1a1612;
          --line: #4a3f34;
          --text: #f2ebe2;
          --muted: #b7aa9a;
          --accent: #e0683f;
          --accent-dark: #f08b6b;
          --hover: #3a3026;
          --ok: #74c486;
          --danger: #f08b6b;
          --success-bg: #1c2d20;
          --success-line: #4f8a5c;
          --error-bg: #3a201a;
          --error-line: #a35a45;
          --map-bg: linear-gradient(180deg, #1c2419, #151b13);
          --map-stroke: rgba(242, 235, 226, 0.35);
          --map-stroke-strong: rgba(242, 235, 226, 0.85);
        }

        .mode-pill.on,
        .badge.on {
          background: var(--success-bg);
          color: var(--ok);
          border-color: var(--success-line);
        }

        code {
          background: rgba(224, 104, 63, 0.16);
        }
      }
`;

type NavLink = { href: string; label: string };

const NAV_LINKS: NavLink[] = [
  { href: "/test", label: "← Übersicht" },
  { href: "/test/push/ui", label: "Testversand" },
  { href: "/test/warnings/ui", label: "Aktuelle Warnungen" },
  { href: "/test/pushover/ui", label: "Pushover" },
];

export function renderTopNav(activeHref: string): string {
  const links = NAV_LINKS.map((link) => {
    const aria = link.href === activeHref ? ' aria-current="page"' : "";
    return `<a href="${link.href}"${aria}>${link.label}</a>`;
  }).join("");
  return `<nav class="topnav">${links}<button type="button" class="logout" onclick="hitzeForgetSecret()">Secret vergessen</button></nav>`;
}

/**
 * Asks once per browser session for CRON_SECRET (sessionStorage) and sends it as Bearer
 * token with every API call of the develop pages. A 401 clears it and asks again once.
 */
export const AUTH_SCRIPT = `
    <script>
      const HITZE_SECRET_KEY = "hitze.cronSecret";

      function hitzeReadSecret() {
        try { return sessionStorage.getItem(HITZE_SECRET_KEY) || ""; } catch (error) { return window.__hitzeSecret || ""; }
      }

      function hitzeStoreSecret(value) {
        try { sessionStorage.setItem(HITZE_SECRET_KEY, value); } catch (error) { window.__hitzeSecret = value; }
      }

      function hitzeForgetSecret() {
        try { sessionStorage.removeItem(HITZE_SECRET_KEY); } catch (error) { window.__hitzeSecret = ""; }
      }

      function hitzeAskSecret() {
        const value = (window.prompt("CRON_SECRET eingeben (bleibt nur in dieser Browser-Sitzung gespeichert):") || "").trim();
        if (value) hitzeStoreSecret(value);
        return value;
      }

      async function hitzeFetch(url, options = {}) {
        let secret = hitzeReadSecret() || hitzeAskSecret();
        const attempt = (token) => fetch(url, {
          cache: "no-store",
          ...options,
          headers: { ...(options.headers || {}), Authorization: "Bearer " + token },
        });
        let response = await attempt(secret);
        if (response.status === 401) {
          hitzeForgetSecret();
          secret = hitzeAskSecret();
          if (secret) response = await attempt(secret);
        }
        return response;
      }
    </script>`;
