-- Not applied to the hosted project. Apply only after review.
-- Direct deletes by authenticated clients skip Storage, so this migration
-- removes that privilege. Pet and moment removal goes through the Edge
-- Functions, which delete objects before the service role deletes rows.
-- Favorite updates and photo replacement stay on INSERT and UPDATE.
-- The older migration files are unchanged.

alter table public.companion_pets
  add column deletion_pending boolean not null default false;

alter table public.companion_moments
  add column deletion_pending boolean not null default false;

create table public.companion_deletion_jobs (
  owner_id uuid not null references auth.users (id) on delete cascade,
  target_kind text not null,
  target_id uuid not null,
  pet_id uuid,
  status text not null,
  object_paths text[] not null default '{}',
  updated_at timestamptz not null default now(),
  primary key (owner_id, target_kind, target_id),
  constraint companion_deletion_jobs_kind_check
    check (target_kind in ('moment', 'pet')),
  constraint companion_deletion_jobs_status_check
    check (status in ('pending', 'storage', 'records', 'complete'))
);

create table public.companion_storage_cleanup (
  owner_id uuid not null references auth.users (id) on delete cascade,
  object_path text not null,
  source text not null,
  created_at timestamptz not null default now(),
  primary key (owner_id, object_path),
  constraint companion_storage_cleanup_source_check
    check (source in ('replaced', 'upload', 'deletion'))
);

alter table public.companion_deletion_jobs enable row level security;
alter table public.companion_storage_cleanup enable row level security;

revoke all on table public.companion_deletion_jobs from public, anon, authenticated;
revoke all on table public.companion_storage_cleanup from public, anon, authenticated;

comment on table public.companion_deletion_jobs is
  'Service-role record of object paths for a pet or moment delete. The row stays until storage cleanup and the database delete both finish.';

comment on table public.companion_storage_cleanup is
  'Service-role queue of object paths that are no longer referenced or are waiting for a retry. Clients cannot read it.';

create or replace function public.companion_is_service_role()
returns boolean
language sql
stable
set search_path = public
as $$
  select coalesce(auth.role(), '') = 'service_role';
$$;

revoke all on function public.companion_is_service_role() from public, anon, authenticated;

create or replace function public.companion_guard_pet()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'DELETE' then
    if not public.companion_is_service_role() then
      raise exception 'direct pet deletion is not allowed' using errcode = '42501';
    end if;
    if old.profile_photo_path is not null
       and public.companion_media_path_ok(old.profile_photo_path)
       and split_part(old.profile_photo_path, '/', 1) = old.owner_id::text
       and split_part(old.profile_photo_path, '/', 3) = old.id::text then
      insert into public.companion_storage_cleanup (owner_id, object_path, source)
      values (old.owner_id, old.profile_photo_path, 'deletion')
      on conflict (owner_id, object_path) do nothing;
    end if;
    return old;
  end if;

  if tg_op = 'INSERT' then
    if not public.companion_is_service_role() then
      new.deletion_pending := false;
    end if;
    return new;
  end if;

  if not public.companion_is_service_role() then
    if old.deletion_pending then
      raise exception 'pet deletion is in progress' using errcode = '42501';
    end if;
    new.deletion_pending := false;
    if old.profile_photo_path is not null
       and old.profile_photo_path is distinct from new.profile_photo_path
       and public.companion_media_path_ok(old.profile_photo_path)
       and split_part(old.profile_photo_path, '/', 1) = old.owner_id::text then
      insert into public.companion_storage_cleanup (owner_id, object_path, source)
      values (old.owner_id, old.profile_photo_path, 'replaced')
      on conflict (owner_id, object_path) do nothing;
    end if;
  end if;
  return new;
end;
$$;

create or replace function public.companion_guard_moment()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_pet_pending boolean;
begin
  if tg_op = 'DELETE' then
    if public.companion_is_service_role() then
      return old;
    end if;
    if coalesce(current_setting('companion.allow_empty_moment_delete', true), '') = 'on'
       and not exists (
         select 1 from public.companion_moment_media where moment_id = old.id
       ) then
      return old;
    end if;
    raise exception 'direct moment deletion is not allowed' using errcode = '42501';
  end if;

  select deletion_pending into v_pet_pending
  from public.companion_pets
  where id = new.pet_id and owner_id = new.owner_id;

  if tg_op = 'INSERT' then
    if coalesce(v_pet_pending, true) then
      raise exception 'pet deletion is in progress' using errcode = '42501';
    end if;
    if not public.companion_is_service_role() then
      new.deletion_pending := false;
    end if;
    return new;
  end if;

  if not public.companion_is_service_role() then
    if old.deletion_pending or coalesce(v_pet_pending, false) then
      raise exception 'deletion is in progress' using errcode = '42501';
    end if;
    new.deletion_pending := false;
  end if;
  return new;
end;
$$;

create or replace function public.companion_guard_moment_media()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_pending boolean;
begin
  if tg_op = 'DELETE' then
    if not public.companion_is_service_role()
       and coalesce(current_setting('companion.media_replace', true), '') <> 'on' then
      raise exception 'direct media deletion is not allowed' using errcode = '42501';
    end if;
    if public.companion_media_path_ok(old.storage_path)
       and split_part(old.storage_path, '/', 1) = old.owner_id::text then
      insert into public.companion_storage_cleanup (owner_id, object_path, source)
      values (old.owner_id, old.storage_path, 'deletion')
      on conflict (owner_id, object_path) do nothing;
    end if;
    return old;
  end if;

  select m.deletion_pending or p.deletion_pending into v_pending
  from public.companion_moments m
  join public.companion_pets p
    on p.id = m.pet_id and p.owner_id = m.owner_id
  where m.id = new.moment_id and m.owner_id = new.owner_id;

  if coalesce(v_pending, true) and not public.companion_is_service_role() then
    raise exception 'deletion is in progress' using errcode = '42501';
  end if;

  if tg_op = 'UPDATE'
     and not public.companion_is_service_role()
     and old.storage_path is distinct from new.storage_path
     and public.companion_media_path_ok(old.storage_path)
     and split_part(old.storage_path, '/', 1) = old.owner_id::text then
    insert into public.companion_storage_cleanup (owner_id, object_path, source)
    values (old.owner_id, old.storage_path, 'replaced')
    on conflict (owner_id, object_path) do nothing;
  end if;
  return new;
end;
$$;

revoke all on function public.companion_guard_pet() from public, anon, authenticated;
revoke all on function public.companion_guard_moment() from public, anon, authenticated;
revoke all on function public.companion_guard_moment_media() from public, anon, authenticated;

drop trigger if exists companion_pets_deletion_guard on public.companion_pets;
create trigger companion_pets_deletion_guard
  before insert or update or delete on public.companion_pets
  for each row execute function public.companion_guard_pet();

drop trigger if exists companion_moments_deletion_guard on public.companion_moments;
create trigger companion_moments_deletion_guard
  before insert or update or delete on public.companion_moments
  for each row execute function public.companion_guard_moment();

drop trigger if exists companion_moment_media_deletion_guard on public.companion_moment_media;
create trigger companion_moment_media_deletion_guard
  before insert or update or delete on public.companion_moment_media
  for each row execute function public.companion_guard_moment_media();

-- Authenticated clients keep SELECT, INSERT, and UPDATE.
-- DELETE is reserved for the service role inside the Edge Functions.
revoke delete on table public.companion_pets from public, anon, authenticated;
revoke delete on table public.companion_moments from public, anon, authenticated;
revoke delete on table public.companion_moment_media from public, anon, authenticated;

create or replace function public.companion_replace_moment_media(
  p_moment_id uuid,
  p_media jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_owner uuid := auth.uid();
  v_pet uuid;
  v_item jsonb;
  v_id uuid;
  v_path text;
  v_order integer;
  v_mime text;
  v_size integer;
  v_width integer;
  v_height integer;
  v_removed jsonb;
begin
  if v_owner is null then
    raise exception 'not authenticated' using errcode = '42501';
  end if;
  if p_media is null or jsonb_typeof(p_media) <> 'array' or jsonb_array_length(p_media) > 5 then
    raise exception 'invalid media' using errcode = '22023';
  end if;

  select pet_id into v_pet
  from public.companion_moments
  where id = p_moment_id
    and owner_id = v_owner
    and deletion_pending = false
  for update;

  if v_pet is null then
    raise exception 'moment not found' using errcode = '42501';
  end if;

  if exists (
    select 1
    from public.companion_pets
    where id = v_pet and owner_id = v_owner and deletion_pending
  ) then
    raise exception 'pet deletion is in progress' using errcode = '42501';
  end if;

  create temporary table companion_replace_stage (
    id uuid not null,
    storage_path text not null,
    sort_order integer not null,
    mime_type text not null,
    file_size integer,
    width integer,
    height integer
  ) on commit drop;

  for v_item in select value from jsonb_array_elements(p_media)
  loop
    v_path := v_item ->> 'storage_path';
    v_order := (v_item ->> 'sort_order')::integer;
    v_mime := coalesce(v_item ->> 'mime_type', 'image/jpeg');
    v_size := nullif(v_item ->> 'file_size', '')::integer;
    v_width := nullif(v_item ->> 'width', '')::integer;
    v_height := nullif(v_item ->> 'height', '')::integer;
    begin
      v_id := coalesce(nullif(v_item ->> 'id', '')::uuid, gen_random_uuid());
    exception
      when others then
        raise exception 'invalid media' using errcode = '22023';
    end;
    if v_path is null
       or not public.companion_media_path_ok(v_path)
       or split_part(v_path, '/', 1) <> v_owner::text
       or split_part(v_path, '/', 2) <> 'moments'
       or split_part(v_path, '/', 3) <> p_moment_id::text
       or v_mime <> 'image/jpeg'
       or v_order is null
       or v_order < 0
       or (v_size is not null and (v_size < 0 or v_size > 10485760))
       or (v_width is not null and v_width <= 0)
       or (v_height is not null and v_height <= 0) then
      raise exception 'invalid media' using errcode = '22023';
    end if;
    insert into companion_replace_stage (
      id, storage_path, sort_order, mime_type, file_size, width, height
    ) values (
      v_id, v_path, v_order, v_mime, v_size, v_width, v_height
    );
  end loop;

  if exists (
    select 1 from companion_replace_stage group by sort_order having count(*) > 1
  ) or exists (
    select 1 from companion_replace_stage group by storage_path having count(*) > 1
  ) or exists (
    select 1 from companion_replace_stage group by id having count(*) > 1
  ) then
    raise exception 'invalid media' using errcode = '22023';
  end if;

  select coalesce(jsonb_agg(existing.storage_path), '[]'::jsonb)
  into v_removed
  from public.companion_moment_media as existing
  where existing.moment_id = p_moment_id
    and existing.owner_id = v_owner
    and not exists (
      select 1
      from companion_replace_stage as incoming
      where incoming.storage_path = existing.storage_path
    );

  perform set_config('companion.media_replace', 'on', true);
  delete from public.companion_moment_media
  where moment_id = p_moment_id and owner_id = v_owner;

  insert into public.companion_moment_media (
    id, moment_id, owner_id, storage_path, sort_order, mime_type, file_size, width, height
  )
  select id, p_moment_id, v_owner, storage_path, sort_order, mime_type, file_size, width, height
  from companion_replace_stage;

  perform set_config('companion.media_replace', 'off', true);
  return jsonb_build_object('removed', coalesce(v_removed, '[]'::jsonb));
end;
$$;

create or replace function public.companion_abandon_empty_moment(p_moment_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_owner uuid := auth.uid();
begin
  if v_owner is null then
    raise exception 'not authenticated' using errcode = '42501';
  end if;
  if exists (
    select 1
    from public.companion_moment_media
    where moment_id = p_moment_id and owner_id = v_owner
  ) then
    raise exception 'moment still has photos' using errcode = '42501';
  end if;
  if exists (
    select 1
    from public.companion_moments
    where id = p_moment_id and owner_id = v_owner and deletion_pending
  ) then
    raise exception 'deletion is in progress' using errcode = '42501';
  end if;
  perform set_config('companion.allow_empty_moment_delete', 'on', true);
  delete from public.companion_moments
  where id = p_moment_id and owner_id = v_owner and deletion_pending = false;
end;
$$;

revoke all on function public.companion_replace_moment_media(uuid, jsonb) from public, anon;
revoke all on function public.companion_abandon_empty_moment(uuid) from public, anon;
grant execute on function public.companion_replace_moment_media(uuid, jsonb) to authenticated;
grant execute on function public.companion_abandon_empty_moment(uuid) to authenticated;

comment on function public.companion_replace_moment_media(uuid, jsonb) is
  'Replaces the caller''s moment photos. Removed paths are queued. The caller identity is auth.uid().';

comment on function public.companion_abandon_empty_moment(uuid) is
  'Deletes a moment only when the caller owns it and it has no photo rows.';
