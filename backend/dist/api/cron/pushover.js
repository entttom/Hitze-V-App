"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.isPushoverConfigured = isPushoverConfigured;
exports.sendPushoverReport = sendPushoverReport;
const PUSHOVER_API_URL = "https://api.pushover.net/1/messages.json";
const PUSHOVER_TIMEOUT_MS = 5_000;
const PUSHOVER_MAX_FAILED_TARGETS_IN_MESSAGE = 5;
function getPushoverConfig() {
    const appToken = process.env.PUSHOVER_APP_TOKEN?.trim();
    const userKey = process.env.PUSHOVER_USER_KEY?.trim();
    if (!appToken || !userKey) {
        return null;
    }
    return {
        appToken,
        userKey,
        device: process.env.PUSHOVER_DEVICE?.trim() || undefined,
    };
}
function isPushoverConfigured() {
    return getPushoverConfig() !== null;
}
function formatDuration(ms) {
    if (ms < 1000) {
        return `${ms}ms`;
    }
    return `${(ms / 1000).toFixed(1)}s`;
}
function buildPushoverMessage(input) {
    const allOK = input.failed === 0;
    const title = allOK ? "Hitze-Warnung versendet" : "Hitze-Warnung: Fehler";
    const lines = [];
    lines.push(`Warnungen: ${input.processedWarnings}`);
    lines.push(`Gemeinden: ${input.affectedMunicipalities}`);
    if (allOK) {
        lines.push(`Pushes: ${input.sent} (alle Sprachen OK)`);
    }
    else {
        lines.push(`Pushes: ${input.sent} / ${input.attempted} — ${input.failed} Fehler in ${input.failedMunicipalities.length} Gemeinden`);
        if (input.failedTargets.length > 0) {
            lines.push("");
            lines.push("Fehler (Auszug):");
            const shown = input.failedTargets.slice(0, PUSHOVER_MAX_FAILED_TARGETS_IN_MESSAGE);
            for (const target of shown) {
                lines.push(`  ${target}`);
            }
            const remaining = input.failedTargets.length - shown.length;
            if (remaining > 0) {
                lines.push(`  +${remaining} mehr`);
            }
        }
    }
    if (input.skippedRateLimited > 0 || input.skippedQuietHours > 0) {
        lines.push("");
        lines.push(`Skipped: ${input.skippedRateLimited} rate-limited, ${input.skippedQuietHours} quiet-hours`);
    }
    lines.push(`Dauer: ${formatDuration(input.durationMs)}`);
    return {
        title,
        message: lines.join("\n"),
        priority: allOK ? "0" : "1",
    };
}
async function sendPushoverReport(input) {
    const config = getPushoverConfig();
    if (!config) {
        return;
    }
    const { title, message, priority } = buildPushoverMessage(input);
    const params = new URLSearchParams({
        token: config.appToken,
        user: config.userKey,
        title,
        message,
        priority,
    });
    if (config.device) {
        params.set("device", config.device);
    }
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), PUSHOVER_TIMEOUT_MS);
    try {
        const response = await fetch(PUSHOVER_API_URL, {
            method: "POST",
            headers: { "Content-Type": "application/x-www-form-urlencoded" },
            body: params,
            signal: controller.signal,
        });
        if (!response.ok) {
            const text = await response.text();
            console.warn(`[${input.requestId}] pushover_send_failed`, {
                status: response.status,
                body: text.slice(0, 200),
            });
        }
    }
    catch (error) {
        console.warn(`[${input.requestId}] pushover_send_error`, {
            error: error instanceof Error ? error.message : String(error),
        });
    }
    finally {
        clearTimeout(timeout);
    }
}
