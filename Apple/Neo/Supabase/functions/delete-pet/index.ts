// NOT DEPLOYED. Deletes one pet, its moments, and their photographs.
// Other pets that belong to the same account are left in place.

import {
  adminClient,
  clearQueue,
  environment,
  finishJob,
  isCanonicalOwned,
  isProfilePhoto,
  isUuid,
  json,
  readJson,
  rememberJob,
  removeOwnedPaths,
  requireUser,
} from "../_shared/companion_cleanup.ts";

Deno.serve(async (request) => {
  if (request.method !== "POST") return json({ status: "rejected" }, 405);
  const env = environment();
  if (!env) return json({ status: "incomplete", stage: "configuration" }, 500);
  const auth = await requireUser(request, env);
  if (auth.error) return auth.error;

  const body = await readJson(request);
  const petId = typeof body.petId === "string" ? body.petId.toLowerCase() : "";
  if (!isUuid(petId) || body.ownerId !== undefined) {
    return json({ status: "rejected" }, 400);
  }

  const admin = adminClient(env);
  const ownerId = auth.userId;
  const loaded = await admin
    .from("companion_pets")
    .select("id, owner_id, profile_photo_path")
    .eq("id", petId)
    .maybeSingle();
  if (loaded.error) return json({ status: "incomplete", stage: "records" }, 409);
  if (!loaded.data) return finishJob(admin, ownerId, "pet", petId);
  if (loaded.data.owner_id !== ownerId) return json({ status: "rejected" }, 404);

  const pendingPet = await admin
    .from("companion_pets")
    .update({ deletion_pending: true })
    .eq("id", petId)
    .eq("owner_id", ownerId);
  if (pendingPet.error) return json({ status: "incomplete", stage: "records" }, 409);
  const pendingMoments = await admin
    .from("companion_moments")
    .update({ deletion_pending: true })
    .eq("pet_id", petId)
    .eq("owner_id", ownerId);
  if (pendingMoments.error) return json({ status: "incomplete", stage: "records" }, 409);

  const moments = await admin
    .from("companion_moments")
    .select("id")
    .eq("pet_id", petId)
    .eq("owner_id", ownerId);
  if (moments.error) return json({ status: "incomplete", stage: "records" }, 409);
  const momentIds = (moments.data ?? []).map((row) => row.id);
  let mediaPaths = [];
  if (momentIds.length > 0) {
    const media = await admin
      .from("companion_moment_media")
      .select("storage_path")
      .eq("owner_id", ownerId)
      .in("moment_id", momentIds);
    if (media.error) return json({ status: "incomplete", stage: "records" }, 409);
    mediaPaths = (media.data ?? []).map((row) => row.storage_path);
  }
  const profile = loaded.data.profile_photo_path;
  const paths = [
    ...(profile && isProfilePhoto(profile, ownerId, petId) ? [profile] : []),
    ...mediaPaths.filter((path) => isCanonicalOwned(path, ownerId)),
  ];
  const remembered = await rememberJob(admin, ownerId, "pet", petId, petId, paths);
  if (!remembered) return json({ status: "incomplete", stage: "records" }, 409);

  const removed = await removeOwnedPaths(admin, ownerId, remembered);
  if (!removed.ok) return json({ status: "incomplete", stage: "storage" }, 409);

  const deleted = await admin
    .from("companion_pets")
    .delete()
    .eq("id", petId)
    .eq("owner_id", ownerId);
  if (deleted.error) return json({ status: "incomplete", stage: "records" }, 409);

  const cleared = await clearQueue(admin, ownerId, remembered);
  if (!cleared) return json({ status: "incomplete", stage: "storage" }, 409);
  const { error: jobError } = await admin
    .from("companion_deletion_jobs")
    .delete()
    .eq("owner_id", ownerId)
    .eq("target_kind", "pet")
    .eq("target_id", petId);
  if (jobError) return json({ status: "incomplete", stage: "records" }, 409);
  return json({ status: "deleted" }, 200);
});
