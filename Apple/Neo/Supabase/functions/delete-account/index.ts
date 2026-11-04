// NOT DEPLOYED. Do not deploy this function until it has been reviewed
// against an isolated staging project.
//
// The service-role key is read from the function environment only.
// The iOS app never receives it. The caller must present their own user JWT.
//
// Order:
// 1. Verify the JWT and require { "confirm": true }.
// 2. Delete storage objects under the owner's prefix. Stop if this fails.
// 3. Delete companion rows owned by that user. Stop if this fails.
// 4. Delete the Auth user only after storage and rows are gone.
// Each step is safe to repeat, so a failed run can be resumed.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const bucket = "companion-pet-media";

Deno.serve(async (request) => {
  if (request.method !== "POST") {
    return json({ status: "rejected" }, 405);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !anonKey || !serviceRoleKey) {
    return json({ status: "incomplete", stage: "configuration" }, 500);
  }

  const authorization = request.headers.get("Authorization");
  if (!authorization) {
    return json({ status: "rejected" }, 401);
  }

  let body = {};
  try {
    body = await request.json();
  } catch {
    body = {};
  }
  if (body.confirm !== true) {
    return json({ status: "rejected" }, 400);
  }

  const userClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authorization } },
    auth: { persistSession: false },
  });
  const { data: userData, error: userError } = await userClient.auth.getUser();
  if (userError || !userData.user) {
    return json({ status: "rejected" }, 401);
  }

  const ownerId = userData.user.id;
  const admin = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false },
  });

  await admin.from("companion_account_deletions").upsert({
    owner_id: ownerId,
    stage: "storage",
    updated_at: new Date().toISOString(),
  });

  const removed = await removeOwnedObjects(admin, ownerId);
  if (!removed) {
    return json({ status: "incomplete", stage: "storage" }, 409);
  }

  await admin.from("companion_account_deletions").upsert({
    owner_id: ownerId,
    stage: "records",
    updated_at: new Date().toISOString(),
  });

  const records = await removeOwnedRecords(admin, ownerId);
  if (!records) {
    return json({ status: "incomplete", stage: "records" }, 409);
  }

  await admin.from("companion_account_deletions").upsert({
    owner_id: ownerId,
    stage: "auth",
    updated_at: new Date().toISOString(),
  });

  const { error: deleteUserError } = await admin.auth.admin.deleteUser(ownerId);
  if (deleteUserError) {
    return json({ status: "incomplete", stage: "auth" }, 409);
  }

  await admin.from("companion_account_deletions").upsert({
    owner_id: ownerId,
    stage: "deleted",
    updated_at: new Date().toISOString(),
  });

  return json({ status: "deleted" }, 200);
});

async function removeOwnedObjects(admin, ownerId) {
  const prefix = `${ownerId}`;
  let offset = 0;
  const pageSize = 100;
  for (;;) {
    const { data, error } = await admin.storage.from(bucket).list(prefix, {
      limit: pageSize,
      offset,
    });
    if (error) return false;
    if (!data || data.length === 0) return true;

    const files = [];
    for (const entry of data) {
      if (entry.id) {
        files.push(`${prefix}/${entry.name}`);
      } else {
        const nested = await removeFolder(admin, `${prefix}/${entry.name}`);
        if (!nested) return false;
      }
    }
    if (files.length > 0) {
      const { error: removeError } = await admin.storage.from(bucket).remove(files);
      if (removeError) return false;
    }
    if (data.length < pageSize) return true;
    offset += data.length;
  }
}

async function removeFolder(admin, folder) {
  const { data, error } = await admin.storage.from(bucket).list(folder, { limit: 100 });
  if (error) return false;
  if (!data || data.length === 0) return true;
  const files = [];
  for (const entry of data) {
    const path = `${folder}/${entry.name}`;
    if (entry.id) {
      files.push(path);
    } else {
      const nested = await removeFolder(admin, path);
      if (!nested) return false;
    }
  }
  if (files.length === 0) return true;
  const { error: removeError } = await admin.storage.from(bucket).remove(files);
  return !removeError;
}

async function removeOwnedRecords(admin, ownerId) {
  const pets = await admin.from("companion_pets").delete().eq("owner_id", ownerId);
  if (pets.error) return false;
  const moments = await admin.from("companion_moments").delete().eq("owner_id", ownerId);
  if (moments.error) return false;
  const media = await admin.from("companion_moment_media").delete().eq("owner_id", ownerId);
  if (media.error) return false;
  const memories = await admin.from("companion_memories").delete().eq("owner_id", ownerId);
  return !memories.error;
}

function json(body, status) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
