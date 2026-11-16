import { cert, getApps, initializeApp } from "firebase-admin/app";
import { getMessaging, type Message } from "firebase-admin/messaging";
import { envString } from "./env";
import { AppError } from "./errors";

export interface MessagingLike {
  send(message: Message): Promise<string>;
}

let messaging: MessagingLike | null = null;

function serviceAccountFromEnv(): { projectId: string; clientEmail: string; privateKey: string } {
  const raw = envString("FIREBASE_SERVICE_ACCOUNT");
  if (!raw) {
    throw new AppError(500, "CONFIG_ERROR", "Missing FIREBASE_SERVICE_ACCOUNT environment variable.");
  }

  let parsed: unknown;
  try {
    parsed = JSON.parse(raw);
  } catch {
    throw new AppError(500, "CONFIG_ERROR", "FIREBASE_SERVICE_ACCOUNT is not valid JSON.");
  }
  if (typeof parsed !== "object" || parsed === null) {
    throw new AppError(500, "CONFIG_ERROR", "FIREBASE_SERVICE_ACCOUNT must decode into an object.");
  }

  const record = parsed as Record<string, unknown>;
  const text = (key: string): string | null =>
    typeof record[key] === "string" && (record[key] as string).trim() ? (record[key] as string).trim() : null;
  const projectId = text("project_id");
  const clientEmail = text("client_email");
  const privateKey = text("private_key")?.replace(/\\n/g, "\n");
  if (!projectId || !clientEmail || !privateKey) {
    throw new AppError(
      500,
      "CONFIG_ERROR",
      "FIREBASE_SERVICE_ACCOUNT is missing required fields project_id/client_email/private_key."
    );
  }
  return { projectId, clientEmail, privateKey };
}

export function getFirebaseMessaging(): MessagingLike {
  if (messaging) {
    return messaging;
  }
  if (!getApps().length) {
    initializeApp({ credential: cert(serviceAccountFromEnv()) });
  }
  messaging = getMessaging();
  return messaging;
}

/** Initialises Firebase without network access; throws if the credentials are unusable. */
export function checkFirebaseReady(): void {
  getFirebaseMessaging();
}

/** Firebase error code (e.g. `messaging/registration-token-not-registered`) without internals. */
export function firebaseErrorCode(error: unknown): string {
  if (typeof error === "object" && error !== null) {
    const record = error as { code?: unknown; errorInfo?: { code?: unknown } };
    if (typeof record.errorInfo?.code === "string") {
      return record.errorInfo.code;
    }
    if (typeof record.code === "string") {
      return record.code;
    }
  }
  return "unknown";
}
