// NOT DEPLOYED. Removes queued photographs that no active record still references.
// A path that is still saved on a pet or moment is left in place.

import {
  adminClient,
  cleanupUnreferenced,
  environment,
  isCanonicalOwned,
  json,
  readJson,
  requireUser,
} from "../_shared/companion_cleanup.ts";

Deno.serve(async (request) => {
  if (request.method !== "POST") return json({ status: "rejected" }, 405);
  const env = environment();
  if (!env) return json({ status: "incomplete", stage: "configuration" }, 500);
  const auth = await requireUser(request, env);
  if (auth.error) return auth.error;

  const body = await readJson(request);
  if (body.ownerId !== undefined) return json({ status: "rejected" }, 400);
  const requested = Array.isArray(body.paths) ? body.paths : [];
  if (requested.some((path) => typeof path !== "string")) {
    return json({ status: "rejected" }, 400);
  }
  const ownerId = auth.userId;
  const paths = requested.filter((path) => isCanonicalOwned(path, ownerId));
  if (paths.length !== requested.length) return json({ status: "rejected" }, 400);

  const admin = adminClient(env);
  const cleaned = await cleanupUnreferenced(admin, ownerId, paths);
  if (!cleaned) return json({ status: "incomplete", stage: "storage" }, 409);
  return json({ status: "deleted" }, 200);
});
