import { getSupabaseClient } from '@/lib/supabase';
import { getSupabaseErrorMessage } from '@/lib/errors';

export type DataSource = 'remote' | 'local';

export interface DatabaseWriteResult<T> {
  data: T;
  source: DataSource;
  remoteFailed: boolean;
}

export async function tryRemote<T>(
  operation: () => Promise<T>,
  fallbackLabel: string,
): Promise<{ data: T | null; failed: boolean }> {
  const supabase = getSupabaseClient();
  if (!supabase) {
    return { data: null, failed: false };
  }

  try {
    const data = await operation();
    return { data, failed: false };
  } catch (error) {
    console.warn(`[Neo] ${fallbackLabel} failed, using local fallback:`, getSupabaseErrorMessage(error));
    return { data: null, failed: true };
  }
}

export async function writeWithFallback<T>(
  remote: (() => Promise<T>) | null,
  local: () => Promise<T>,
  fallbackLabel: string,
): Promise<DatabaseWriteResult<T>> {
  let remoteFailed = false;

  if (remote) {
    const attempt = await tryRemote(remote, fallbackLabel);
    remoteFailed = attempt.failed;

    if (attempt.data) {
      return { data: attempt.data, source: 'remote', remoteFailed: false };
    }
  }

  const data = await local();
  return { data, source: 'local', remoteFailed };
}

export async function readWithFallback<T>(
  remote: (() => Promise<T | null>) | null,
  local: () => Promise<T | null>,
  fallbackLabel: string,
): Promise<{ data: T | null; source: DataSource; remoteFailed: boolean }> {
  let remoteFailed = false;

  if (remote) {
    const attempt = await tryRemote(remote, fallbackLabel);
    remoteFailed = attempt.failed;

    if (attempt.data !== null && attempt.data !== undefined) {
      return { data: attempt.data, source: 'remote', remoteFailed: false };
    }

    if (!attempt.failed) {
      return { data: null, source: 'remote', remoteFailed: false };
    }
  }

  return {
    data: await local(),
    source: 'local',
    remoteFailed,
  };
}
