// NOT DEPLOYED. Deletes one moment after its photographs are removed.
// The caller JWT supplies the owner. The body cannot choose an owner.

import {
  adminClient,
  environment,
  finishJob,
  isMomentPhoto,
  isUuid,
  json,
  readJson,
  rememberJob,
  removeOwnedPaths,
  requireUser,
  clearQueue,
} from "../_shared/companion_cleanup.ts";

Deno.serve(async (request) => {
  if (request.method !== "POST") return json({ status: "rejected" }, 405);
  const env = environment();
  if (!env) return json({ status: "incomplete", stage: "configuration" }, 500);
  const auth = await requireUser(request, env);
  if (auth.error) return auth.error;

  const body = await readJson(request);
  const momentId = typeof body.momentId === "string" ? body.momentId.toLowerCase() : "";
  const petId = typeof body.petId === "string" ? body.petId.toLowerCase() : "";
  if (!isUuid(momentId) || !isUuid(petId) || body.ownerId !== undefined) {
    return json({ status: "rejected" }, 400);
  }

  const admin = adminClient(env);
  const ownerId = auth.userId;
  const loaded = await admin
    .from("companion_moments")
    .select("id, owner_id, pet_id")
    .eq("id", momentId)
    .maybeSingle();
  if (loaded.error) return json({ status: "incomplete", stage: "records" }, 409);
  if (!loaded.data) return finishJob(admin, ownerId, "moment", momentId);
  if (loaded.data.owner_id !== ownerId || loaded.data.pet_id !== petId) {
    return json({ status: "rejected" }, 404);
  }

  const pending = await admin
    .from("companion_moments")
    .update({ deletion_pending: true })
    .eq("id", momentId)
    .eq("owner_id", ownerId)
    .eq("pet_id", petId);
  if (pending.error) return json({ status: "incomplete", stage: "records" }, 409);

  const media = await admin
    .from("companion_moment_media")
    .select("storage_path")
    .eq("moment_id", momentId)
    .eq("owner_id", ownerId);
  if (media.error) return json({ status: "incomplete", stage: "records" }, 409);
  const paths = (media.data ?? [])
    .map((row) => row.storage_path)
    .filter((path) => isMomentPhoto(path, ownerId, momentId));
  const remembered = await rememberJob(admin, ownerId, "moment", momentId, petId, paths);
  if (!remembered) return json({ status: "incomplete", stage: "records" }, 409);

  const removed = await removeOwnedPaths(
    admin,
    ownerId,
    remembered.filter((path) => isMomentPhoto(path, ownerId, momentId)),
  );
  if (!removed.ok) return json({ status: "incomplete", stage: "storage" }, 409);

  const again = await admin
    .from("companion_moment_media")
    .select("storage_path")
    .eq("moment_id", momentId)
    .eq("owner_id", ownerId);
  if (again.error) return json({ status: "incomplete", stage: "records" }, 409);
  const extra = (again.data ?? [])
    .map((row) => row.storage_path)
    .filter((path) => isMomentPhoto(path, ownerId, momentId));
  const extraRemoved = await removeOwnedPaths(admin, ownerId, extra);
  if (!extraRemoved.ok) return json({ status: "incomplete", stage: "storage" }, 409);

  const deleted = await admin
    .from("companion_moments")
    .delete()
    .eq("id", momentId)
    .eq("owner_id", ownerId)
    .eq("pet_id", petId);
  if (deleted.error) return json({ status: "incomplete", stage: "records" }, 409);

  const finishedPaths = [...remembered, ...extra];
  const cleared = await clearQueue(admin, ownerId, finishedPaths);
  if (!cleared) return json({ status: "incomplete", stage: "storage" }, 409);
  const { error: jobError } = await admin
    .from("companion_deletion_jobs")
    .delete()
    .eq("owner_id", ownerId)
    .eq("target_kind", "moment")
    .eq("target_id", momentId);
  if (jobError) return json({ status: "incomplete", stage: "records" }, 409);
  return json({ status: "deleted" }, 200);
});
