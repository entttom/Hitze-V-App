export class AppError extends Error {
  constructor(
    public readonly status: number,
    public readonly code: string,
    message: string
  ) {
    super(message);
    this.name = "AppError";
  }
}

export class RedisUnavailableError extends AppError {
  constructor(message: string) {
    super(503, "REDIS_UNAVAILABLE", message);
    this.name = "RedisUnavailableError";
  }
}

export function errorMessage(error: unknown): string {
  return error instanceof Error ? error.message : String(error);
}

export function toAppError(error: unknown): AppError {
  if (error instanceof AppError) {
    return error;
  }
  return new AppError(500, "INTERNAL_ERROR", errorMessage(error));
}
