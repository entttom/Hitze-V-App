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
app.post("/test/push-token", async (req, res) => {
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
app.listen(port, "0.0.0.0", () => {
    console.log(`Hitze backend listening on port ${port}`);
});
