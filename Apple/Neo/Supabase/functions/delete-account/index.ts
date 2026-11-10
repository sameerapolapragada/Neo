// NOT DEPLOYED. Do not deploy this function until it has been reviewed
// against an isolated staging project.
//
// The service-role key is read from the function environment only.
// The iOS app never receives it. The caller must present their own user JWT.
//
// Order:
// 1. Verify the JWT, require { "confirm": true }, and check the password
//    with the Auth server. A client flag is not sufficient.
// 2. Delete canonical storage objects under the owner's prefix. Stop if this fails.
// 3. Delete companion rows owned by that user. Stop if this fails.
// 4. Delete the Auth user only after storage and rows are gone.
// Each step is safe to repeat, so a failed run can be resumed.
// Object removal uses the same path checks as delete-moment and delete-pet.

import {
  adminClient,
  bucket,
  clearQueue,
  environment,
  isCanonicalOwned,
  json,
  listOwnedObjects,
  readJson,
  removeOwnedPaths,
  requireUser,
  selectOwnedRows,
  verifyPassword,
} from "../_shared/companion_cleanup.ts";

Deno.serve(async (request) => {
  if (request.method !== "POST") return json({ status: "rejected" }, 405);
  const env = environment();
  if (!env) return json({ status: "incomplete", stage: "configuration" }, 500);
  const auth = await requireUser(request, env);
  if (auth.error) return auth.error;

  const body = await readJson(request);
  if (body.confirm !== true || body.ownerId !== undefined || typeof body.password !== "string") {
    return json({ status: "rejected" }, 400);
  }
  const passwordMatches = await verifyPassword(env, auth.email, body.password, auth.userId);
  if (!passwordMatches) return json({ status: "rejected" }, 401);

  const ownerId = auth.userId;
  const admin = adminClient(env);
  await admin.from("companion_account_deletions").upsert({
    owner_id: ownerId,
    stage: "storage",
    updated_at: new Date().toISOString(),
  });

  const removed = await removeAccountObjects(admin, ownerId);
  if (!removed) return json({ status: "incomplete", stage: "storage" }, 409);

  await admin.from("companion_account_deletions").upsert({
    owner_id: ownerId,
    stage: "records",
    updated_at: new Date().toISOString(),
  });
  const records = await removeOwnedRecords(admin, ownerId);
  if (!records) return json({ status: "incomplete", stage: "records" }, 409);

  await admin.from("companion_account_deletions").upsert({
    owner_id: ownerId,
    stage: "auth",
    updated_at: new Date().toISOString(),
  });
  const { error: deleteUserError } = await admin.auth.admin.deleteUser(ownerId);
  if (deleteUserError) return json({ status: "incomplete", stage: "auth" }, 409);

  await admin.from("companion_account_deletions").upsert({
    owner_id: ownerId,
    stage: "deleted",
    updated_at: new Date().toISOString(),
  });
  return json({ status: "deleted" }, 200);
});

async function removeAccountObjects(admin, ownerId) {
  let listed = [];
  try {
    listed = await listOwnedObjects(admin, ownerId);
  } catch {
    return false;
  }
  const queued = await selectOwnedRows(admin, "companion_storage_cleanup", ownerId, "object_path");
  if (queued.error) return false;
  const jobs = await selectOwnedRows(admin, "companion_deletion_jobs", ownerId, "object_paths");
  if (jobs.error) return false;
  const jobPaths = (jobs.data ?? []).flatMap((row) => row.object_paths ?? []);
  const paths = [...listed, ...(queued.data ?? []).map((row) => row.object_path), ...jobPaths]
    .filter((path) => isCanonicalOwned(path, ownerId));
  const removed = await removeOwnedPaths(admin, ownerId, paths);
  if (!removed.ok) return false;
  const cleared = await clearQueue(
    admin,
    ownerId,
    (queued.data ?? []).map((row) => row.object_path).filter((path) => isCanonicalOwned(path, ownerId)),
  );
  if (!cleared) return false;
  const { data, error: listError } = await admin.storage.from(bucket).list(ownerId, { limit: 1 });
  if (listError) return false;
  return !data || data.length === 0;
}

async function removeOwnedRecords(admin, ownerId) {
  const jobs = await admin.from("companion_deletion_jobs").delete().eq("owner_id", ownerId);
  if (jobs.error) return false;
  const media = await admin.from("companion_moment_media").delete().eq("owner_id", ownerId);
  if (media.error) return false;
  const moments = await admin.from("companion_moments").delete().eq("owner_id", ownerId);
  if (moments.error) return false;
  const pets = await admin.from("companion_pets").delete().eq("owner_id", ownerId);
  return !pets.error;
}
