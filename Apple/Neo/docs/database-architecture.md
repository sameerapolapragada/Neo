# Companion database architecture

Phase 1 schema for the native iOS app. The first three migrations are on the hosted Neo project. The deletion-guard migration is local until it is reviewed and applied.

The Expo tables `pets`, `memories`, `lifestyle_answers`, `future_snapshots`, and `missing_moments` are not part of this design and are not modified.

`companion_memories` is not created. Profile milestones are `companion_moments` rows whose category is `Milestone`. The older scrapbook Swift types still exist for tests, but no current screen reads that table.

## Tables and relationships

```text
auth.users
  └─ companion_pets (owner_id)
       └─ companion_moments (pet_id, owner_id)
            └─ companion_moment_media (moment_id, owner_id)

auth.users
  └─ companion_account_deletions (owner_id, service role only)
```

A pet belongs to one owner. A moment belongs to one pet and that same owner. A media row belongs to one moment and that same owner. The composite foreign keys are:

- `companion_moments (pet_id, owner_id)` → `companion_pets (id, owner_id)`
- `companion_moment_media (moment_id, owner_id)` → `companion_moments (id, owner_id)`

A client cannot attach its moment to another account's pet by sending that pet's id. Database cascades remove moment and media rows when a pet row is deleted, and they remove an owner's rows when the auth user is deleted. Those cascades do not delete Storage objects.

Authenticated clients no longer have `DELETE` on the companion tables. Favorite changes and photo replacement still use `UPDATE` and `INSERT`. A moment's photo list is replaced by `companion_replace_moment_media`, which keeps `auth.uid()` as the owner and queues paths that the new list dropped. `companion_abandon_empty_moment` deletes a moment only when that caller owns it and it has no photo rows.

`delete-moment` and `delete-pet` are Edge Functions. They verify the caller's JWT, ignore any client-supplied owner id, record the object paths, delete those objects through the Storage API, and only then delete the row with the service role. A failed storage or row delete returns `incomplete` and leaves the job so the same call can be repeated. `cleanup-storage` deletes queued paths that are no longer referenced. `delete-account` uses the same path checks, then removes the owned rows and the auth user. None of these functions are deployed yet.

## Ownership model

`owner_id` is `auth.uid()` for every client read and write. Anonymous roles have no grants and no policies. A client cannot change `owner_id`; `companion_reject_owner_change` rejects that update for every role, including the service role.

Row level security also requires the parent row. A moment is readable or writable only when `companion_pets` has that `pet_id` for `auth.uid()`. Media is readable or writable only when the moment and its pet both belong to `auth.uid()`. The composite foreign keys reject a `pet_id` or `moment_id` that belongs to another owner even if a policy is bypassed.

`companion_account_deletions` has no policies and no grants for `anon` or `authenticated`. Only the Edge Function's service role can write it. The service-role key stays in the function environment. That role bypasses RLS, which is why it is not shipped in the app.

## Columns the current app stores

`companion_pets` uses the names the database contract asked for: `weight`, `personality`, and `profile_photo_path`. The Swift model still calls those fields `weightValue`, `bio`, and `photoPath`. `PetRow` maps them.

The current profile also saves three fields that are not on the edit form but must survive a save:

- `gender`
- `microchip_id`
- `is_favorite`

`companion_moment_media` uses `mime_type` and `file_size`. The Swift model still calls those `contentType` and `byteCount`. `width` and `height` are kept because moment upload records them.

`moment_date` is a `date`. The app sends `YYYY-MM-DD` in the device calendar. `created_at` remains the time used to order moments that share a day.

## Indexes

- `companion_pets (owner_id, created_at desc)` for the owner's pet list
- `companion_moments (owner_id, pet_id, moment_date desc, created_at desc, id desc)` for the timeline and feed
- `companion_moments (owner_id, pet_id, category, moment_date desc)` for Daily, Adventure, and Milestone filters
- `companion_moment_media (moment_id, sort_order)` for photo order
- `companion_moment_media (owner_id)` for account cleanup

## Constraints

- Pet name has at least 2 characters after trim.
- Species is `Dog`, `Cat`, `Rabbit`, `Bird`, `Guinea Pig`, or `Other`. The edit screen offers Dog, Cat, and Other, and still preserves a stored Rabbit, Bird, or Guinea Pig.
- Weight is null or greater than zero. Unit is `lbs` or `kg`.
- Personality is at most 200 characters. Blank is allowed.
- Moment title is 1 to 100 characters after trim. Caption is at most 300 characters. Blank captions are allowed.
- Category is `Daily`, `Adventure`, or `Milestone`.
- Media type is `image/jpeg`, size is at most 10 MB, and `sort_order` is zero or greater.
- Photo paths cannot be URLs, absolute paths, or `..` paths. A profile photo is `{owner_id}/pets/{pet_id}/profile/{file_id}.jpg`. A moment photo is `{owner_id}/moments/{moment_id}/{file_id}.jpg`. Both ids and the file id are lowercase UUIDs.

`updated_at` is set by `companion_set_updated_at` before each pet or moment update. `companion_reject_owner_change` runs before updates of pets, moments, and media. Inserts use `now()` when the client does not send a time. Primary keys default to `gen_random_uuid()`.

## Storage

Bucket: `companion-pet-media`.

- Private
- `image/jpeg` only
- 10 MB maximum

Object keys use the account and record ids, never a name or email address:

- Profile photo: `{owner_id}/pets/{pet_id}/profile/{file_id}.jpg`
- Moment photo: `{owner_id}/moments/{moment_id}/{file_id}.jpg`

Storage policies are limited to `authenticated` and to this bucket. Each of SELECT, INSERT, UPDATE, and DELETE requires all of the following:

- `bucket_id` is `companion-pet-media`
- `storage.objects.owner` is `auth.uid()`
- the first folder is `auth.uid()`
- `companion_media_path_ok` accepts the key

`storage.foldername` does not include the filename. A profile key has four folders and a moment key has three. `createSignedURL` is allowed only by the SELECT policy. There is no policy for `anon` or `public`, and no policy that grants the whole bucket.

The app requests signed URLs that last 600 seconds, and only after the key belongs to the signed-in account. It refreshes a URL inside the last 60 seconds. The cache is cleared when the account changes or the device signs out. Clearing that cache does not revoke a URL that was already issued. The app does not create public object URLs.

## Migration order

Apply these files in order, and only after review. Do not run `schema.sql` or `delete-account.sql`. Those drafts are superseded.

1. `Supabase/migrations/20261105010000_create_companion_core.sql`
2. `Supabase/migrations/20261105010100_companion_rls_and_storage.sql`
3. `Supabase/migrations/20261105010200_companion_account_deletions.sql`
4. `Supabase/migrations/20261106010000_companion_deletion_guards.sql`

The first migration stops if `companion_pets` already exists. That is intentional. An existing draft table needs a separate reviewed change, not a replay of this file.

The second migration's bucket statement sets `companion-pet-media` private if a bucket with that id already exists. It does not change any other bucket and does not delete files.

## Local validation

The local project is `Apple/Neo/Supabase`. It is not linked to the hosted project. Its API port is 55421 and its database port is 55422, so it does not use another local stack's ports.

`python3 Apple/Neo/Supabase/tests/local_integration.py` checks this local database, storage API, and local deletion functions. The script stops if the URL is not `127.0.0.1`. `supabase migration up --local` applies pending files on that same local database. Do not add `--linked` or a hosted database URL.

## Future extension

Phase 1 does not add family accounts, care schedules, or clinic tables.

`owner_id` stays the account boundary. A later `household_id` can sit beside it. Clinic access should be a separate membership table with its own policies, not a change that lets a clinic read every pet. Care records can reference `companion_pets (id, owner_id)` the same way moments do, so a care row cannot point at another account's pet.
