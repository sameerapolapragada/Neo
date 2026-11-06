-- Phase 1 companion schema for the native iOS app.
-- NOT APPLIED. Do not run this against a remote project until it is reviewed.
--
-- This file does not read or change the Expo tables
-- (pets, memories, lifestyle_answers, future_snapshots, missing_moments).
-- It fails if companion_pets already exists, so an older draft cannot be
-- overwritten by accident. Do not add DROP statements to make it pass.

create extension if not exists pgcrypto;

create or replace function public.companion_set_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table public.companion_pets (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users (id) on delete cascade,
  name text not null,
  species text not null,
  breed text not null default '',
  birthday date,
  adoption_date date,
  weight numeric,
  weight_unit text not null default 'lbs',
  favorite_toy text,
  personality text not null default '',
  profile_photo_path text,
  gender text not null default 'Unknown',
  microchip_id text,
  is_favorite boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (id, owner_id),
  constraint companion_pets_name_check
    check (char_length(btrim(name)) >= 2),
  constraint companion_pets_species_check
    check (species in ('Dog', 'Cat', 'Rabbit', 'Bird', 'Guinea Pig', 'Other')),
  constraint companion_pets_weight_check
    check (weight is null or weight > 0),
  constraint companion_pets_weight_unit_check
    check (weight_unit in ('lbs', 'kg')),
  constraint companion_pets_personality_check
    check (char_length(personality) <= 200),
  constraint companion_pets_gender_check
    check (gender in ('Male', 'Female', 'Neutered', 'Spayed', 'Unknown')),
  constraint companion_pets_photo_path_check
    check (
      profile_photo_path is null
      or (
        profile_photo_path !~ '://'
        and left(profile_photo_path, 1) <> '/'
        and position('..' in profile_photo_path) = 0
        and split_part(profile_photo_path, '/', 1) = owner_id::text
        and split_part(profile_photo_path, '/', 2) = 'pets'
        and split_part(profile_photo_path, '/', 3) = id::text
        and split_part(profile_photo_path, '/', 4) = 'profile'
        and split_part(profile_photo_path, '/', 5) ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.jpg$'
        and split_part(profile_photo_path, '/', 6) = ''
      )
    )
);

comment on table public.companion_pets is
  'Phase 1 pet profile. owner_id is the account boundary. A later household or clinic id can be added without replacing owner_id.';

create table public.companion_moments (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users (id) on delete cascade,
  pet_id uuid not null,
  title text not null,
  caption text not null default '',
  category text not null,
  moment_date date not null,
  is_favorite boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (id, owner_id),
  constraint companion_moments_owner_pet_fkey
    foreign key (pet_id, owner_id)
    references public.companion_pets (id, owner_id)
    on delete cascade,
  constraint companion_moments_title_check
    check (char_length(btrim(title)) between 1 and 100),
  constraint companion_moments_caption_check
    check (char_length(caption) <= 300),
  constraint companion_moments_category_check
    check (category in ('Daily', 'Adventure', 'Milestone'))
);

create table public.companion_moment_media (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users (id) on delete cascade,
  moment_id uuid not null,
  storage_path text not null,
  sort_order integer not null default 0,
  mime_type text not null default 'image/jpeg',
  file_size integer,
  width integer,
  height integer,
  created_at timestamptz not null default now(),
  unique (moment_id, sort_order),
  constraint companion_moment_media_owner_moment_fkey
    foreign key (moment_id, owner_id)
    references public.companion_moments (id, owner_id)
    on delete cascade,
  constraint companion_moment_media_sort_check
    check (sort_order >= 0),
  constraint companion_moment_media_mime_check
    check (mime_type = 'image/jpeg'),
  constraint companion_moment_media_size_check
    check (file_size is null or (file_size >= 0 and file_size <= 10485760)),
  constraint companion_moment_media_width_check
    check (width is null or width > 0),
  constraint companion_moment_media_height_check
    check (height is null or height > 0),
  constraint companion_moment_media_path_check
    check (
      storage_path !~ '://'
      and left(storage_path, 1) <> '/'
      and position('..' in storage_path) = 0
      and split_part(storage_path, '/', 1) = owner_id::text
      and split_part(storage_path, '/', 2) = 'moments'
      and split_part(storage_path, '/', 3) = moment_id::text
      and split_part(storage_path, '/', 4) ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.jpg$'
      and split_part(storage_path, '/', 5) = ''
    )
);

create or replace function public.companion_reject_owner_change()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if new.owner_id is distinct from old.owner_id then
    raise exception 'owner_id is permanent'
      using errcode = '42501';
  end if;
  return new;
end;
$$;

revoke all on function public.companion_set_updated_at() from public, anon, authenticated;
revoke all on function public.companion_reject_owner_change() from public, anon, authenticated;

create index companion_pets_owner_created_idx
  on public.companion_pets (owner_id, created_at desc);

create index companion_moments_timeline_idx
  on public.companion_moments (owner_id, pet_id, moment_date desc, created_at desc, id desc);

create index companion_moments_category_idx
  on public.companion_moments (owner_id, pet_id, category, moment_date desc);

create index companion_moment_media_order_idx
  on public.companion_moment_media (moment_id, sort_order);

create index companion_moment_media_owner_idx
  on public.companion_moment_media (owner_id);

create trigger companion_pets_updated_at
before update on public.companion_pets
for each row execute function public.companion_set_updated_at();

create trigger companion_pets_owner_lock
before update on public.companion_pets
for each row execute function public.companion_reject_owner_change();

create trigger companion_moments_updated_at
before update on public.companion_moments
for each row execute function public.companion_set_updated_at();

create trigger companion_moments_owner_lock
before update on public.companion_moments
for each row execute function public.companion_reject_owner_change();

create trigger companion_moment_media_owner_lock
before update on public.companion_moment_media
for each row execute function public.companion_reject_owner_change();
