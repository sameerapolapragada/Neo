export class DatabaseError extends Error {
  constructor(
    message: string,
    readonly cause?: unknown,
    readonly usedLocalFallback = false,
  ) {
    super(message);
    this.name = 'DatabaseError';
  }
}

export function getErrorMessage(error: unknown, fallback = 'Something went wrong'): string {
  if (error instanceof DatabaseError) {
    return error.message;
  }

  if (error instanceof Error && error.message) {
    return error.message;
  }

  if (typeof error === 'object' && error !== null && 'message' in error) {
    const message = (error as { message?: string }).message;
    if (message) return message;
  }

  return fallback;
}

export function getSupabaseErrorMessage(error: unknown): string {
  if (typeof error === 'object' && error !== null) {
    const record = error as { message?: string; details?: string; hint?: string };
    if (record.message) return record.message;
  }

  return getErrorMessage(error, 'Could not reach the server');
}
