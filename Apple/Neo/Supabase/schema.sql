-- SUPERSEDED. Do not run this file.
-- The versioned Phase 1 migrations live in Apple/Neo/Supabase/migrations/.
-- This draft is kept for history only. It is not the migration to apply.
-- Its storage policies only check the first folder. Re-applying them would
-- weaken the migration, so the statement below stops the script.

do $$
begin
  raise exception 'schema.sql is superseded. Apply Apple/Neo/Supabase/migrations instead.';
end $$;
--
-- Neo companion schema for the native iOS app.
-- NOT APPLIED. Do not run this against the live project without approval.
-- Table and bucket names are prefixed so this script does not alter the Expo
-- tables (`pets`, `memories`) or their open policies.
--
-- The app uses the signed-in user's id as owner_id and never embeds a
-- service-role key. Service role bypasses these policies.
--
-- companion_memories is kept. The profile milestone count uses
-- companion_moments where category = 'Milestone'. Do not drop
-- companion_memories unless that cleanup is explicitly approved.

create extension if not exists "pgcrypto";

create table if not exists public.companion_pets (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users (id) on delete cascade,
  name text not null check (char_length(btrim(name)) >= 2),
  species text not null,
  breed text not null default '',
  birthday date,
  gender text not null default 'Unknown',
  adoption_date date,
  weight_value numeric check (weight_value is null or weight_value > 0),
  weight_unit text not null default 'lbs',
  microchip_id text,
  photo_path text,
  bio text not null default '' check (char_length(bio) <= 200),
  favorite_toy text,
  is_favorite boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Local proposal only. Breed may be blank, weight must be positive when set,
-- and personality text is stored in bio with a 200 character cap.
alter table public.companion_pets drop constraint if exists companion_pets_breed_check;
alter table public.companion_pets alter column breed set default '';

alter table public.companion_pets drop constraint if exists companion_pets_weight_value_check;
alter table public.companion_pets
  add constraint companion_pets_weight_value_check
  check (weight_value is null or weight_value > 0);

alter table public.companion_pets drop constraint if exists companion_pets_bio_check;
alter table public.companion_pets
  add constraint companion_pets_bio_check
  check (char_length(bio) <= 200);

create table if not exists public.companion_moments (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users (id) on delete cascade,
  pet_id uuid not null references public.companion_pets (id) on delete cascade,
  title text not null check (char_length(btrim(title)) between 1 and 100),
  caption text not null default '' check (char_length(caption) <= 300),
  category text not null check (category in ('Daily', 'Adventure', 'Milestone')),
  moment_date timestamptz not null,
  is_favorite boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.companion_moment_media (
  id uuid primary key default gen_random_uuid(),
  moment_id uuid not null references public.companion_moments (id) on delete cascade,
  owner_id uuid not null references auth.users (id) on delete cascade,
  storage_path text not null check (
    char_length(btrim(storage_path)) > 0
    and storage_path !~ '://'
    and left(storage_path, 1) <> '/'
    and position('..' in storage_path) = 0
  ),
  sort_order integer not null default 0,
  content_type text not null default 'image/jpeg',
  byte_count integer check (byte_count is null or byte_count >= 0),
  width integer check (width is null or width > 0),
  height integer check (height is null or height > 0),
  created_at timestamptz not null default now(),
  unique (moment_id, sort_order)
);

-- Unused by the current Profile, Moments, and Timeline screens.
-- Safe cleanup later: stop writing this table, confirm it is empty or exported,
-- then drop it in a reviewed migration. This file does not drop it.
create table if not exists public.companion_memories (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users (id) on delete cascade,
  pet_id uuid not null references public.companion_pets (id) on delete cascade,
  title text not null check (char_length(btrim(title)) >= 2),
  notes text not null check (char_length(btrim(notes)) >= 5),
  category text not null default 'Memory',
  sentiment text,
  photo_path text,
  occurred_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.companion_pets add column if not exists favorite_toy text;
alter table public.companion_pets add column if not exists is_favorite boolean not null default false;

alter table public.companion_moments add column if not exists title text not null default '';
alter table public.companion_moments add column if not exists category text not null default 'Daily';
alter table public.companion_moments add column if not exists moment_date timestamptz not null default now();
alter table public.companion_moments add column if not exists is_favorite boolean not null default false;

alter table public.companion_moments drop constraint if exists companion_moments_title_check;
alter table public.companion_moments
  add constraint companion_moments_title_check
  check (char_length(btrim(title)) between 1 and 100);

alter table public.companion_moments drop constraint if exists companion_moments_caption_check;
alter table public.companion_moments
  add constraint companion_moments_caption_check
  check (char_length(caption) <= 300);

create index if not exists companion_pets_owner_idx on public.companion_pets (owner_id);
create index if not exists companion_moments_feed_idx
  on public.companion_moments (owner_id, pet_id, moment_date desc, created_at desc, id desc);
create index if not exists companion_moment_media_moment_idx
  on public.companion_moment_media (moment_id, sort_order);
create index if not exists companion_memories_pet_idx on public.companion_memories (pet_id, occurred_at desc);

create or replace function public.companion_set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists companion_pets_updated_at on public.companion_pets;
create trigger companion_pets_updated_at
before update on public.companion_pets
for each row execute function public.companion_set_updated_at();

drop trigger if exists companion_moments_updated_at on public.companion_moments;
create trigger companion_moments_updated_at
before update on public.companion_moments
for each row execute function public.companion_set_updated_at();

drop trigger if exists companion_memories_updated_at on public.companion_memories;
create trigger companion_memories_updated_at
before update on public.companion_memories
for each row execute function public.companion_set_updated_at();

alter table public.companion_pets enable row level security;
alter table public.companion_moments enable row level security;
alter table public.companion_moment_media enable row level security;
alter table public.companion_memories enable row level security;

revoke all on public.companion_pets from anon;
revoke all on public.companion_moments from anon;
revoke all on public.companion_moment_media from anon;
revoke all on public.companion_memories from anon;

grant select, insert, update, delete on public.companion_pets to authenticated;
grant select, insert, update, delete on public.companion_moments to authenticated;
grant select, insert, update, delete on public.companion_moment_media to authenticated;
grant select, insert, update, delete on public.companion_memories to authenticated;

drop policy if exists companion_pets_select on public.companion_pets;
create policy companion_pets_select on public.companion_pets
for select to authenticated
using (owner_id = auth.uid());

drop policy if exists companion_pets_insert on public.companion_pets;
create policy companion_pets_insert on public.companion_pets
for insert to authenticated
with check (owner_id = auth.uid());

drop policy if exists companion_pets_update on public.companion_pets;
create policy companion_pets_update on public.companion_pets
for update to authenticated
using (owner_id = auth.uid())
with check (owner_id = auth.uid());

drop policy if exists companion_pets_delete on public.companion_pets;
create policy companion_pets_delete on public.companion_pets
for delete to authenticated
using (owner_id = auth.uid());

drop policy if exists companion_moments_select on public.companion_moments;
create policy companion_moments_select on public.companion_moments
for select to authenticated
using (
  owner_id = auth.uid()
  and exists (
    select 1 from public.companion_pets
    where companion_pets.id = pet_id
      and companion_pets.owner_id = auth.uid()
  )
);

drop policy if exists companion_moments_insert on public.companion_moments;
create policy companion_moments_insert on public.companion_moments
for insert to authenticated
with check (
  owner_id = auth.uid()
  and exists (
    select 1 from public.companion_pets
    where companion_pets.id = pet_id
      and companion_pets.owner_id = auth.uid()
  )
);

drop policy if exists companion_moments_update on public.companion_moments;
create policy companion_moments_update on public.companion_moments
for update to authenticated
using (
  owner_id = auth.uid()
  and exists (
    select 1 from public.companion_pets
    where companion_pets.id = pet_id
      and companion_pets.owner_id = auth.uid()
  )
)
with check (
  owner_id = auth.uid()
  and exists (
    select 1 from public.companion_pets
    where companion_pets.id = pet_id
      and companion_pets.owner_id = auth.uid()
  )
);

drop policy if exists companion_moments_delete on public.companion_moments;
create policy companion_moments_delete on public.companion_moments
for delete to authenticated
using (
  owner_id = auth.uid()
  and exists (
    select 1 from public.companion_pets
    where companion_pets.id = pet_id
      and companion_pets.owner_id = auth.uid()
  )
);

drop policy if exists companion_moment_media_select on public.companion_moment_media;
create policy companion_moment_media_select on public.companion_moment_media
for select to authenticated
using (
  owner_id = auth.uid()
  and exists (
    select 1
    from public.companion_moments
    join public.companion_pets on companion_pets.id = companion_moments.pet_id
    where companion_moments.id = moment_id
      and companion_moments.owner_id = auth.uid()
      and companion_pets.owner_id = auth.uid()
  )
);

drop policy if exists companion_moment_media_insert on public.companion_moment_media;
create policy companion_moment_media_insert on public.companion_moment_media
for insert to authenticated
with check (
  owner_id = auth.uid()
  and exists (
    select 1
    from public.companion_moments
    join public.companion_pets on companion_pets.id = companion_moments.pet_id
    where companion_moments.id = moment_id
      and companion_moments.owner_id = auth.uid()
      and companion_pets.owner_id = auth.uid()
  )
);

drop policy if exists companion_moment_media_update on public.companion_moment_media;
create policy companion_moment_media_update on public.companion_moment_media
for update to authenticated
using (owner_id = auth.uid())
with check (
  owner_id = auth.uid()
  and exists (
    select 1
    from public.companion_moments
    join public.companion_pets on companion_pets.id = companion_moments.pet_id
    where companion_moments.id = moment_id
      and companion_moments.owner_id = auth.uid()
      and companion_pets.owner_id = auth.uid()
  )
);

drop policy if exists companion_moment_media_delete on public.companion_moment_media;
create policy companion_moment_media_delete on public.companion_moment_media
for delete to authenticated
using (
  owner_id = auth.uid()
  and exists (
    select 1
    from public.companion_moments
    join public.companion_pets on companion_pets.id = companion_moments.pet_id
    where companion_moments.id = moment_id
      and companion_moments.owner_id = auth.uid()
      and companion_pets.owner_id = auth.uid()
  )
);

drop policy if exists companion_memories_select on public.companion_memories;
create policy companion_memories_select on public.companion_memories
for select to authenticated
using (owner_id = auth.uid());

drop policy if exists companion_memories_insert on public.companion_memories;
create policy companion_memories_insert on public.companion_memories
for insert to authenticated
with check (
  owner_id = auth.uid()
  and exists (
    select 1 from public.companion_pets
    where companion_pets.id = pet_id
      and companion_pets.owner_id = auth.uid()
  )
);

drop policy if exists companion_memories_update on public.companion_memories;
create policy companion_memories_update on public.companion_memories
for update to authenticated
using (owner_id = auth.uid())
with check (
  owner_id = auth.uid()
  and exists (
    select 1 from public.companion_pets
    where companion_pets.id = pet_id
      and companion_pets.owner_id = auth.uid()
  )
);

drop policy if exists companion_memories_delete on public.companion_memories;
create policy companion_memories_delete on public.companion_memories
for delete to authenticated
using (owner_id = auth.uid());

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('companion-pet-media', 'companion-pet-media', false, 10485760, array['image/jpeg'])
on conflict (id) do update
set public = false,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists companion_pet_media_select on storage.objects;
create policy companion_pet_media_select on storage.objects
for select to authenticated
using (
  bucket_id = 'companion-pet-media'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists companion_pet_media_insert on storage.objects;
create policy companion_pet_media_insert on storage.objects
for insert to authenticated
with check (
  bucket_id = 'companion-pet-media'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists companion_pet_media_update on storage.objects;
create policy companion_pet_media_update on storage.objects
for update to authenticated
using (
  bucket_id = 'companion-pet-media'
  and (storage.foldername(name))[1] = auth.uid()::text
)
with check (
  bucket_id = 'companion-pet-media'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists companion_pet_media_delete on storage.objects;
create policy companion_pet_media_delete on storage.objects
for delete to authenticated
using (
  bucket_id = 'companion-pet-media'
  and (storage.foldername(name))[1] = auth.uid()::text
);
