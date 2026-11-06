-- Phase 1 access control for the native companion tables.
-- NOT APPLIED. Run only after 20261105010000_create_companion_core.sql.
-- Does not alter Expo tables or their policies.
--
-- Grants and RLS are both required. A policy does not help a role that was
-- granted nothing, and a grant does not help when no policy matches.
-- Anonymous and public roles receive no grants and no policies.
-- The service role bypasses RLS. It is not available to the iOS app.

alter table public.companion_pets enable row level security;
alter table public.companion_moments enable row level security;
alter table public.companion_moment_media enable row level security;

revoke all on table public.companion_pets from public, anon, authenticated;
revoke all on table public.companion_moments from public, anon, authenticated;
revoke all on table public.companion_moment_media from public, anon, authenticated;

grant select, insert, update, delete on table public.companion_pets to authenticated;
grant select, insert, update, delete on table public.companion_moments to authenticated;
grant select, insert, update, delete on table public.companion_moment_media to authenticated;

-- Replace any earlier policy of the same name. Postgres ORs permissive
-- policies, so leaving the superseded folder-only policy in place would
-- widen access. These drops do not touch policies for other buckets.
drop policy if exists companion_pets_select on public.companion_pets;
drop policy if exists companion_pets_insert on public.companion_pets;
drop policy if exists companion_pets_update on public.companion_pets;
drop policy if exists companion_pets_delete on public.companion_pets;
drop policy if exists companion_moments_select on public.companion_moments;
drop policy if exists companion_moments_insert on public.companion_moments;
drop policy if exists companion_moments_update on public.companion_moments;
drop policy if exists companion_moments_delete on public.companion_moments;
drop policy if exists companion_moment_media_select on public.companion_moment_media;
drop policy if exists companion_moment_media_insert on public.companion_moment_media;
drop policy if exists companion_moment_media_update on public.companion_moment_media;
drop policy if exists companion_moment_media_delete on public.companion_moment_media;
drop policy if exists companion_pet_media_select on storage.objects;
drop policy if exists companion_pet_media_insert on storage.objects;
drop policy if exists companion_pet_media_update on storage.objects;
drop policy if exists companion_pet_media_delete on storage.objects;

create policy companion_pets_select on public.companion_pets
for select to authenticated
using (owner_id = auth.uid());

create policy companion_pets_insert on public.companion_pets
for insert to authenticated
with check (owner_id = auth.uid());

create policy companion_pets_update on public.companion_pets
for update to authenticated
using (owner_id = auth.uid())
with check (owner_id = auth.uid());

create policy companion_pets_delete on public.companion_pets
for delete to authenticated
using (owner_id = auth.uid());

create policy companion_moments_select on public.companion_moments
for select to authenticated
using (
  owner_id = auth.uid()
  and exists (
    select 1
    from public.companion_pets
    where companion_pets.id = pet_id
      and companion_pets.owner_id = auth.uid()
  )
);

create policy companion_moments_insert on public.companion_moments
for insert to authenticated
with check (
  owner_id = auth.uid()
  and exists (
    select 1
    from public.companion_pets
    where companion_pets.id = pet_id
      and companion_pets.owner_id = auth.uid()
  )
);

create policy companion_moments_update on public.companion_moments
for update to authenticated
using (
  owner_id = auth.uid()
  and exists (
    select 1
    from public.companion_pets
    where companion_pets.id = pet_id
      and companion_pets.owner_id = auth.uid()
  )
)
with check (
  owner_id = auth.uid()
  and exists (
    select 1
    from public.companion_pets
    where companion_pets.id = pet_id
      and companion_pets.owner_id = auth.uid()
  )
);

create policy companion_moments_delete on public.companion_moments
for delete to authenticated
using (
  owner_id = auth.uid()
  and exists (
    select 1
    from public.companion_pets
    where companion_pets.id = pet_id
      and companion_pets.owner_id = auth.uid()
  )
);

create policy companion_moment_media_select on public.companion_moment_media
for select to authenticated
using (
  owner_id = auth.uid()
  and exists (
    select 1
    from public.companion_moments
    join public.companion_pets
      on companion_pets.id = companion_moments.pet_id
     and companion_pets.owner_id = companion_moments.owner_id
    where companion_moments.id = moment_id
      and companion_moments.owner_id = auth.uid()
      and companion_pets.owner_id = auth.uid()
  )
);

create policy companion_moment_media_insert on public.companion_moment_media
for insert to authenticated
with check (
  owner_id = auth.uid()
  and exists (
    select 1
    from public.companion_moments
    join public.companion_pets
      on companion_pets.id = companion_moments.pet_id
     and companion_pets.owner_id = companion_moments.owner_id
    where companion_moments.id = moment_id
      and companion_moments.owner_id = auth.uid()
      and companion_pets.owner_id = auth.uid()
  )
);

create policy companion_moment_media_update on public.companion_moment_media
for update to authenticated
using (
  owner_id = auth.uid()
  and exists (
    select 1
    from public.companion_moments
    join public.companion_pets
      on companion_pets.id = companion_moments.pet_id
     and companion_pets.owner_id = companion_moments.owner_id
    where companion_moments.id = moment_id
      and companion_moments.owner_id = auth.uid()
      and companion_pets.owner_id = auth.uid()
  )
)
with check (
  owner_id = auth.uid()
  and exists (
    select 1
    from public.companion_moments
    join public.companion_pets
      on companion_pets.id = companion_moments.pet_id
     and companion_pets.owner_id = companion_moments.owner_id
    where companion_moments.id = moment_id
      and companion_moments.owner_id = auth.uid()
      and companion_pets.owner_id = auth.uid()
  )
);

create policy companion_moment_media_delete on public.companion_moment_media
for delete to authenticated
using (
  owner_id = auth.uid()
  and exists (
    select 1
    from public.companion_moments
    join public.companion_pets
      on companion_pets.id = companion_moments.pet_id
     and companion_pets.owner_id = companion_moments.owner_id
    where companion_moments.id = moment_id
      and companion_moments.owner_id = auth.uid()
      and companion_pets.owner_id = auth.uid()
  )
);

-- Private JPEG bucket. This updates only the companion bucket's privacy
-- settings. It does not delete objects and does not touch other buckets.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('companion-pet-media', 'companion-pet-media', false, 10485760, array['image/jpeg'])
on conflict (id) do update
set public = false,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

-- storage.foldername omits the filename. A profile object has four folders
-- and a moment object has three. The filename is checked separately.
create or replace function public.companion_media_path_ok(object_name text)
returns boolean
language sql
stable
set search_path = public, storage
as $$
  select
    object_name is not null
    and position('..' in object_name) = 0
    and left(object_name, 1) <> '/'
    and object_name !~ '://'
    and (storage.foldername(object_name))[1] ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
    and (
      (
        array_length(storage.foldername(object_name), 1) = 4
        and (storage.foldername(object_name))[2] = 'pets'
        and (storage.foldername(object_name))[3] ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
        and (storage.foldername(object_name))[4] = 'profile'
        and split_part(object_name, '/', 5) ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.jpg$'
        and split_part(object_name, '/', 6) = ''
      )
      or (
        array_length(storage.foldername(object_name), 1) = 3
        and (storage.foldername(object_name))[2] = 'moments'
        and (storage.foldername(object_name))[3] ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
        and split_part(object_name, '/', 4) ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.jpg$'
        and split_part(object_name, '/', 5) = ''
      )
    );
$$;

-- createSignedURL checks SELECT. Upload checks INSERT.
-- UPDATE is limited to the same owner so an overwrite cannot move the object
-- into another account's folder. There is no policy for anon or public.
create policy companion_pet_media_select on storage.objects
for select to authenticated
using (
  bucket_id = 'companion-pet-media'
  and owner = auth.uid()
  and (storage.foldername(name))[1] = auth.uid()::text
  and public.companion_media_path_ok(name)
);

create policy companion_pet_media_insert on storage.objects
for insert to authenticated
with check (
  bucket_id = 'companion-pet-media'
  and owner = auth.uid()
  and (storage.foldername(name))[1] = auth.uid()::text
  and public.companion_media_path_ok(name)
);

create policy companion_pet_media_update on storage.objects
for update to authenticated
using (
  bucket_id = 'companion-pet-media'
  and owner = auth.uid()
  and (storage.foldername(name))[1] = auth.uid()::text
  and public.companion_media_path_ok(name)
)
with check (
  bucket_id = 'companion-pet-media'
  and owner = auth.uid()
  and (storage.foldername(name))[1] = auth.uid()::text
  and public.companion_media_path_ok(name)
);

create policy companion_pet_media_delete on storage.objects
for delete to authenticated
using (
  bucket_id = 'companion-pet-media'
  and owner = auth.uid()
  and (storage.foldername(name))[1] = auth.uid()::text
  and public.companion_media_path_ok(name)
);

revoke all on function public.companion_media_path_ok(text) from public, anon;
grant execute on function public.companion_media_path_ok(text) to authenticated;
