import express, { type Request, type Response } from "express";
import { executeHitzeCron, sendTestPushNotification } from "../api/cron/hitze";

const app = express();
app.use(express.json());

const port = Number(process.env.PORT ?? "3000");
const cronSecret = process.env.CRON_SECRET;

function isAuthorized(req: Request): boolean {
  if (!cronSecret) {
    return true;
  }

  const header = req.header("authorization") ?? "";
  return header === `Bearer ${cronSecret}`;
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

app.get("/cron/hitze", async (req: Request, res: Response) => {
  const result = await executeHitzeCron(req.method);
  if (result.headers) {
    for (const [key, value] of Object.entries(result.headers)) {
      res.setHeader(key, value);
    }
  }

  res.status(result.status).json(result.body);
});

app.post("/test/push", async (req: Request, res: Response) => {
  const municipalityId =
    typeof req.body?.municipalityId === "string" ? req.body.municipalityId : "";
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
    const result = await sendTestPushNotification({ municipalityId, title, body });
    res.status(200).json({
      ok: true,
      municipalityId: municipalityId.trim(),
      topic: result.topic,
      messageId: result.messageId,
    });
  } catch (error) {
    res.status(500).json({
      errorCode: "TEST_PUSH_FAILED",
      message: error instanceof Error ? error.message : String(error),
    });
  }
});

app.listen(port, "0.0.0.0", () => {
  console.log(`Hitze backend listening on port ${port}`);
});
