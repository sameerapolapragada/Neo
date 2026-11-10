// Shared by the local deletion functions. Not deployed.
// The service-role key is read from the function environment only.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

export const bucket = "companion-pet-media";

const uuidPattern =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/;

export function json(body, status) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

export function isUuid(value) {
  return typeof value === "string" && uuidPattern.test(value);
}

export function isCanonicalOwned(path, ownerId) {
  if (!isSafePath(path) || !isUuid(ownerId)) return false;
  const parts = path.split("/");
  if (parts[0] !== ownerId) return false;
  if (parts.length === 5) {
    return parts[1] === "pets"
      && isUuid(parts[2])
      && parts[3] === "profile"
      && isJpegFile(parts[4]);
  }
  if (parts.length === 4) {
    return parts[1] === "moments" && isUuid(parts[2]) && isJpegFile(parts[3]);
  }
  return false;
}

export function isProfilePhoto(path, ownerId, petId) {
  if (!isCanonicalOwned(path, ownerId)) return false;
  const parts = path.split("/");
  return parts.length === 5 && parts[2] === petId;
}

export function isMomentPhoto(path, ownerId, momentId) {
  if (!isCanonicalOwned(path, ownerId)) return false;
  const parts = path.split("/");
  return parts.length === 4 && parts[2] === momentId;
}

export function isOwnedPrefix(path, ownerId) {
  return isSafePath(path) && isUuid(ownerId) && path.split("/")[0] === ownerId;
}

function isSafePath(path) {
  return typeof path === "string"
    && path.length > 0
    && path.length < 512
    && !path.includes("..")
    && !path.includes("://")
    && !path.startsWith("/")
    && !path.includes("//");
}

function isJpegFile(value) {
  return typeof value === "string"
    && value.endsWith(".jpg")
    && isUuid(value.slice(0, -4));
}

export async function readJson(request) {
  try {
    return await request.json();
  } catch {
    return {};
  }
}

export function environment() {
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !anonKey || !serviceRoleKey) return null;
  return { supabaseUrl, anonKey, serviceRoleKey };
}

export function adminClient(env) {
  return createClient(env.supabaseUrl, env.serviceRoleKey, {
    auth: { persistSession: false },
  });
}

export async function requireUser(request, env) {
  const authorization = request.headers.get("Authorization");
  if (!authorization) return { error: json({ status: "rejected" }, 401) };
  const userClient = createClient(env.supabaseUrl, env.anonKey, {
    global: { headers: { Authorization: authorization } },
    auth: { persistSession: false },
  });
  const { data, error } = await userClient.auth.getUser();
  if (error || !data.user) return { error: json({ status: "rejected" }, 401) };
  return { userId: data.user.id, email: data.user.email ?? "" };
}

/// Checks the password with the Auth server. The caller email comes from the
/// verified user, not from the request body. The password is not stored.
export async function verifyPassword(env, email, password, userId) {
  if (typeof password !== "string" || password.length < 1 || password.length > 1024) return false;
  if (!email || !isUuid(userId)) return false;
  const anon = createClient(env.supabaseUrl, env.anonKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data, error } = await anon.auth.signInWithPassword({ email, password });
  return !error && data.user?.id === userId;
}

export async function selectOwnedRows(admin, table, ownerId, columns) {
  const pageSize = 1000;
  const rows = [];
  let from = 0;
  for (;;) {
    const { data, error } = await admin
      .from(table)
      .select(columns)
      .eq("owner_id", ownerId)
      .range(from, from + pageSize - 1);
    if (error) return { data: null, error };
    const page = data ?? [];
    rows.push(...page);
    if (page.length < pageSize) return { data: rows, error: null };
    from += pageSize;
  }
}

export async function rememberJob(admin, ownerId, kind, targetId, petId, paths) {
  const { data: existing, error: readError } = await admin
    .from("companion_deletion_jobs")
    .select("object_paths")
    .eq("owner_id", ownerId)
    .eq("target_kind", kind)
    .eq("target_id", targetId)
    .maybeSingle();
  if (readError) return null;
  const combined = unique([...(existing?.object_paths ?? []), ...paths]);
  const { error } = await admin.from("companion_deletion_jobs").upsert({
    owner_id: ownerId,
    target_kind: kind,
    target_id: targetId,
    pet_id: petId,
    status: "storage",
    object_paths: combined,
    updated_at: new Date().toISOString(),
  }, { onConflict: "owner_id,target_kind,target_id" });
  if (error) return null;
  return combined;
}

export async function finishJob(admin, ownerId, kind, targetId) {
  const { data: job, error } = await admin
    .from("companion_deletion_jobs")
    .select("object_paths")
    .eq("owner_id", ownerId)
    .eq("target_kind", kind)
    .eq("target_id", targetId)
    .maybeSingle();
  if (error) return json({ status: "incomplete", stage: "records" }, 409);
  const paths = (job?.object_paths ?? []).filter((path) => isCanonicalOwned(path, ownerId));
  const removed = await removeOwnedPaths(admin, ownerId, paths);
  if (!removed.ok) return json({ status: "incomplete", stage: "storage" }, 409);
  const cleared = await clearQueue(admin, ownerId, paths);
  if (!cleared) return json({ status: "incomplete", stage: "storage" }, 409);
  if (job) {
    const { error: deleteError } = await admin
      .from("companion_deletion_jobs")
      .delete()
      .eq("owner_id", ownerId)
      .eq("target_kind", kind)
      .eq("target_id", targetId);
    if (deleteError) return json({ status: "incomplete", stage: "records" }, 409);
  }
  return json({ status: "deleted" }, 200);
}

export async function removeOwnedPaths(admin, ownerId, paths) {
  const uniquePaths = unique(paths.filter((path) => isCanonicalOwned(path, ownerId)));
  if (uniquePaths.some((path) => !isOwnedPrefix(path, ownerId))) {
    return { ok: false, remaining: uniquePaths };
  }
  const failed = [];
  for (let index = 0; index < uniquePaths.length; index += 100) {
    const batch = uniquePaths.slice(index, index + 100);
    const { error } = await admin.storage.from(bucket).remove(batch);
    if (!error) continue;
    for (const path of batch) {
      const one = await admin.storage.from(bucket).remove([path]);
      if (one.error && !isMissing(one.error)) failed.push(path);
    }
  }
  return { ok: failed.length === 0, remaining: failed };
}

export async function listOwnedObjects(admin, ownerId) {
  const files = await listFolder(admin, ownerId);
  return files.filter((path) => isCanonicalOwned(path, ownerId));
}

async function listFolder(admin, prefix) {
  const files = [];
  let offset = 0;
  const pageSize = 100;
  for (;;) {
    const { data, error } = await admin.storage.from(bucket).list(prefix, {
      limit: pageSize,
      offset,
      sortBy: { column: "name", order: "asc" },
    });
    if (error) throw error;
    if (!data || data.length === 0) return files;
    for (const entry of data) {
      const path = `${prefix}/${entry.name}`;
      if (!isOwnedPrefix(path, prefix.split("/")[0])) continue;
      if (entry.id) files.push(path);
      else files.push(...await listFolder(admin, path));
    }
    if (data.length < pageSize) return files;
    offset += data.length;
  }
}

export async function clearQueue(admin, ownerId, paths) {
  const uniquePaths = unique(paths.filter((path) => isCanonicalOwned(path, ownerId)));
  for (let index = 0; index < uniquePaths.length; index += 100) {
    const batch = uniquePaths.slice(index, index + 100);
    const { error } = await admin
      .from("companion_storage_cleanup")
      .delete()
      .eq("owner_id", ownerId)
      .in("object_path", batch);
    if (error) return false;
  }
  return true;
}

export async function cleanupUnreferenced(admin, ownerId, requestedPaths) {
  const queued = await selectOwnedRows(admin, "companion_storage_cleanup", ownerId, "object_path");
  if (queued.error) return false;
  const candidates = unique([
    ...(queued.data ?? []).map((row) => row.object_path),
    ...requestedPaths,
  ]).filter((path) => isCanonicalOwned(path, ownerId));
  const removable = [];
  for (const path of candidates) {
    const referenced = await isReferenced(admin, ownerId, path);
    if (referenced === null) return false;
    if (referenced) {
      const cleared = await clearQueue(admin, ownerId, [path]);
      if (!cleared) return false;
    } else {
      removable.push(path);
    }
  }
  const removed = await removeOwnedPaths(admin, ownerId, removable);
  if (!removed.ok) return false;
  return clearQueue(admin, ownerId, removable);
}

async function isReferenced(admin, ownerId, path) {
  const pets = await admin
    .from("companion_pets")
    .select("id")
    .eq("owner_id", ownerId)
    .eq("profile_photo_path", path)
    .limit(1);
  if (pets.error) return null;
  if (pets.data && pets.data.length > 0) return true;
  const media = await admin
    .from("companion_moment_media")
    .select("id")
    .eq("owner_id", ownerId)
    .eq("storage_path", path)
    .limit(1);
  if (media.error) return null;
  return Boolean(media.data && media.data.length > 0);
}

function unique(values) {
  return [...new Set(values)];
}

function isMissing(error) {
  const text = `${error.status ?? ""} ${error.message ?? ""} ${error.error ?? ""}`.toLowerCase();
  return text.includes("not found") || text.includes("404");
}
