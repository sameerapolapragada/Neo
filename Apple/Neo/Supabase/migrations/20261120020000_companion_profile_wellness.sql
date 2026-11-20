-- Additive profile, Paw Check, weight log, and moment tag tables.
-- NOT APPLIED. Do not run this against the hosted project until it is approved.
-- Does not drop data, does not edit earlier migration files, and does not
-- touch the Expo tables. Existing profile weights stay undated.

alter table public.companion_pets
  add column sex text not null default 'unknown',
  add column reproductive_status text not null default 'unknown',
  add column age_status text not null default 'unknown',
  add column approximate_age text,
  add column size_category text not null default 'unknown',
  add column breed_identity text not null default 'unknown';

alter table public.companion_pets
  add constraint companion_pets_sex_check
    check (sex in ('male', 'female', 'unknown')),
  add constraint companion_pets_reproductive_status_check
    check (reproductive_status in ('yes', 'no', 'unknown')),
  add constraint companion_pets_age_status_check
    check (age_status in ('known', 'approximate', 'unknown')),
  add constraint companion_pets_approximate_age_check
    check (approximate_age is null or char_length(btrim(approximate_age)) between 1 and 40),
  add constraint companion_pets_size_category_check
    check (size_category in ('small', 'medium', 'large', 'extra_large', 'unknown')),
  add constraint companion_pets_breed_identity_check
    check (breed_identity in ('known', 'mixed', 'unknown'));

comment on column public.companion_pets.sex is
  'Owner-reported sex. Independent of reproductive_status. Unknown is a valid answer.';
comment on column public.companion_pets.reproductive_status is
  'Owner-reported spayed or neutered status. Yes does not imply a sex, and it is not a clinical record.';
comment on column public.companion_pets.age_status is
  'known uses birthday. approximate uses approximate_age. unknown means the owner does not know.';
comment on column public.companion_pets.weight is
  'Undated profile weight. Dated measurements live in companion_weight_entries and are not copied from this column.';

-- Preserve every existing row. Neutered and Spayed say the status is yes,
-- but they do not prove a sex. A birthday marks age as known. A typed breed
-- marks the breed as known. Mixed is never guessed.
update public.companion_pets
set
  sex = case gender
    when 'Male' then 'male'
    when 'Female' then 'female'
    else 'unknown'
  end,
  reproductive_status = case
    when gender in ('Neutered', 'Spayed') then 'yes'
    else 'unknown'
  end,
  age_status = case
    when birthday is not null then 'known'
    else 'unknown'
  end,
  breed_identity = case
    when char_length(btrim(breed)) > 0 then 'known'
    else 'unknown'
  end;

-- Postgres rejects a subquery written directly inside a CHECK constraint.
-- This function only inspects the array it is given.
create or replace function public.companion_paw_observations_ok(observations text[])
returns boolean
language sql
immutable
set search_path = public
as $$
  select
    cardinality(observations) <= 8
    and observations <@ array[
      'drinking_more', 'drinking_less', 'vomiting', 'loose_stool',
      'scratching', 'limping', 'other', 'nothing_noticed'
    ]::text[]
    and cardinality(observations) = (
      select count(distinct item) from unnest(observations) as item
    )
    and (
      not ('nothing_noticed' = any (observations))
      or cardinality(observations) <= 1
    );
$$;

create table public.companion_paw_checks (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users (id) on delete cascade,
  pet_id uuid not null,
  observation_date date not null,
  appetite text,
  energy text,
  mood text,
  observations text[] not null default '{}',
  note text,
  source text not null default 'owner_reported',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (id, owner_id),
  unique (owner_id, pet_id, observation_date),
  constraint companion_paw_checks_pet_fkey
    foreign key (pet_id, owner_id)
    references public.companion_pets (id, owner_id)
    on delete cascade,
  constraint companion_paw_checks_appetite_check
    check (appetite is null or appetite in ('normal', 'less', 'more', 'unsure')),
  constraint companion_paw_checks_energy_check
    check (energy is null or energy in ('normal', 'lower', 'higher', 'unsure')),
  constraint companion_paw_checks_mood_check
    check (mood is null or mood in ('playful', 'relaxed', 'quiet', 'unsettled', 'unsure')),
  constraint companion_paw_checks_note_check
    check (note is null or char_length(note) between 1 and 280),
  constraint companion_paw_checks_source_check
    check (source in ('owner_reported')),
  constraint companion_paw_checks_observations_check
    check (public.companion_paw_observations_ok(observations))
);

comment on table public.companion_paw_checks is
  'One owner-reported daily observation per pet. source stays owner_reported until a later migration adds a verified source. This is not a diagnosis.';
comment on column public.companion_paw_checks.source is
  'Controlled provenance. owner_reported is the only value in this release. Do not treat it as clinician-verified.';

create table public.companion_weight_entries (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users (id) on delete cascade,
  pet_id uuid not null,
  measured_on date not null,
  weight_value numeric not null,
  weight_unit text not null,
  source text not null default 'owner_reported',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (id, owner_id),
  constraint companion_weight_entries_pet_fkey
    foreign key (pet_id, owner_id)
    references public.companion_pets (id, owner_id)
    on delete cascade,
  constraint companion_weight_entries_value_check
    check (weight_value > 0),
  constraint companion_weight_entries_unit_check
    check (weight_unit in ('lbs', 'kg')),
  constraint companion_weight_entries_source_check
    check (source in ('owner_reported'))
);

comment on table public.companion_weight_entries is
  'Dated owner-reported weights in the unit that was entered. The undated companion_pets.weight value is not migrated here.';
comment on column public.companion_weight_entries.source is
  'Controlled provenance. owner_reported is the only value in this release.';

create table public.companion_moment_tags (
  owner_id uuid not null references auth.users (id) on delete cascade,
  moment_id uuid not null,
  tag_key text not null,
  created_at timestamptz not null default now(),
  primary key (owner_id, moment_id, tag_key),
  constraint companion_moment_tags_moment_fkey
    foreign key (moment_id, owner_id)
    references public.companion_moments (id, owner_id)
    on delete cascade,
  constraint companion_moment_tags_key_check
    check (tag_key in (
      'playing', 'sleeping', 'eating', 'exploring', 'socializing', 'learning',
      'cuddling', 'relaxing', 'outdoor', 'indoor', 'grooming', 'funny_moment'
    ))
);

comment on table public.companion_moment_tags is
  'Owner-selected moment tags. Deleting a moment or account cascades these rows and does not delete storage objects by itself.';

create index companion_paw_checks_pet_date_idx
  on public.companion_paw_checks (owner_id, pet_id, observation_date desc);

create index companion_weight_entries_pet_date_idx
  on public.companion_weight_entries (owner_id, pet_id, measured_on desc, created_at desc);

create index companion_moment_tags_moment_idx
  on public.companion_moment_tags (owner_id, moment_id, created_at);

create index companion_moment_tags_key_idx
  on public.companion_moment_tags (owner_id, tag_key, moment_id);

alter table public.companion_paw_checks enable row level security;
alter table public.companion_weight_entries enable row level security;
alter table public.companion_moment_tags enable row level security;

revoke all on table public.companion_paw_checks from public, anon, authenticated;
revoke all on table public.companion_weight_entries from public, anon, authenticated;
revoke all on table public.companion_moment_tags from public, anon, authenticated;

grant select, insert, update, delete on table public.companion_paw_checks to authenticated;
grant select, insert, update, delete on table public.companion_weight_entries to authenticated;
grant select, insert, update, delete on table public.companion_moment_tags to authenticated;

create policy companion_paw_checks_select on public.companion_paw_checks
for select to authenticated
using (
  owner_id = auth.uid()
  and exists (
    select 1 from public.companion_pets
    where companion_pets.id = pet_id
      and companion_pets.owner_id = auth.uid()
  )
);

create policy companion_paw_checks_insert on public.companion_paw_checks
for insert to authenticated
with check (
  owner_id = auth.uid()
  and exists (
    select 1 from public.companion_pets
    where companion_pets.id = pet_id
      and companion_pets.owner_id = auth.uid()
      and companion_pets.deletion_pending = false
  )
);

create policy companion_paw_checks_update on public.companion_paw_checks
for update to authenticated
using (owner_id = auth.uid())
with check (
  owner_id = auth.uid()
  and exists (
    select 1 from public.companion_pets
    where companion_pets.id = pet_id
      and companion_pets.owner_id = auth.uid()
      and companion_pets.deletion_pending = false
  )
);

create policy companion_paw_checks_delete on public.companion_paw_checks
for delete to authenticated
using (
  owner_id = auth.uid()
  and exists (
    select 1 from public.companion_pets
    where companion_pets.id = pet_id
      and companion_pets.owner_id = auth.uid()
  )
);

create policy companion_weight_entries_select on public.companion_weight_entries
for select to authenticated
using (
  owner_id = auth.uid()
  and exists (
    select 1 from public.companion_pets
    where companion_pets.id = pet_id
      and companion_pets.owner_id = auth.uid()
  )
);

create policy companion_weight_entries_insert on public.companion_weight_entries
for insert to authenticated
with check (
  owner_id = auth.uid()
  and exists (
    select 1 from public.companion_pets
    where companion_pets.id = pet_id
      and companion_pets.owner_id = auth.uid()
      and companion_pets.deletion_pending = false
  )
);

create policy companion_weight_entries_update on public.companion_weight_entries
for update to authenticated
using (owner_id = auth.uid())
with check (
  owner_id = auth.uid()
  and exists (
    select 1 from public.companion_pets
    where companion_pets.id = pet_id
      and companion_pets.owner_id = auth.uid()
      and companion_pets.deletion_pending = false
  )
);

create policy companion_weight_entries_delete on public.companion_weight_entries
for delete to authenticated
using (
  owner_id = auth.uid()
  and exists (
    select 1 from public.companion_pets
    where companion_pets.id = pet_id
      and companion_pets.owner_id = auth.uid()
  )
);

create policy companion_moment_tags_select on public.companion_moment_tags
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

create policy companion_moment_tags_insert on public.companion_moment_tags
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
      and companion_moments.deletion_pending = false
      and companion_pets.deletion_pending = false
  )
);

create policy companion_moment_tags_delete on public.companion_moment_tags
for delete to authenticated
using (
  owner_id = auth.uid()
  and exists (
    select 1
    from public.companion_moments
    where companion_moments.id = moment_id
      and companion_moments.owner_id = auth.uid()
  )
);

create or replace function public.companion_reject_pet_change()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if new.owner_id is distinct from old.owner_id then
    raise exception 'owner_id is permanent' using errcode = '42501';
  end if;
  if new.pet_id is distinct from old.pet_id then
    raise exception 'pet_id is permanent' using errcode = '42501';
  end if;
  return new;
end;
$$;

create or replace function public.companion_guard_pet_record()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_pending boolean;
  v_owner uuid;
  v_pet uuid;
begin
  if tg_op = 'DELETE' then
    v_owner := old.owner_id;
    v_pet := old.pet_id;
  else
    v_owner := new.owner_id;
    v_pet := new.pet_id;
  end if;

  if public.companion_is_service_role() then
    if tg_op = 'DELETE' then
      return old;
    end if;
    return new;
  end if;

  select deletion_pending into v_pending
  from public.companion_pets
  where id = v_pet and owner_id = v_owner;

  if coalesce(v_pending, true) then
    raise exception 'pet deletion is in progress' using errcode = '42501';
  end if;

  if tg_op = 'DELETE' then
    return old;
  end if;
  return new;
end;
$$;

create or replace function public.companion_guard_moment_tag()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_moment_pending boolean;
  v_pet_pending boolean;
  v_owner uuid;
  v_moment uuid;
  v_count integer;
begin
  if tg_op = 'DELETE' then
    v_owner := old.owner_id;
    v_moment := old.moment_id;
  else
    v_owner := new.owner_id;
    v_moment := new.moment_id;
  end if;

  if not public.companion_is_service_role() then
    select m.deletion_pending, p.deletion_pending
      into v_moment_pending, v_pet_pending
    from public.companion_moments m
    join public.companion_pets p
      on p.id = m.pet_id and p.owner_id = m.owner_id
    where m.id = v_moment and m.owner_id = v_owner;

    if v_moment_pending is null or v_moment_pending or coalesce(v_pet_pending, true) then
      raise exception 'deletion is in progress' using errcode = '42501';
    end if;
  end if;

  if tg_op = 'INSERT' then
    select count(*) into v_count
    from public.companion_moment_tags
    where owner_id = new.owner_id and moment_id = new.moment_id;
    if v_count >= 5 then
      raise exception 'a moment can have at most five tags' using errcode = '23514';
    end if;
    return new;
  end if;

  return old;
end;
$$;

revoke all on function public.companion_reject_pet_change() from public, anon, authenticated;
revoke all on function public.companion_guard_pet_record() from public, anon, authenticated;
revoke all on function public.companion_guard_moment_tag() from public, anon, authenticated;

create trigger companion_paw_checks_updated_at
before update on public.companion_paw_checks
for each row execute function public.companion_set_updated_at();

create trigger companion_paw_checks_owner_lock
before update on public.companion_paw_checks
for each row execute function public.companion_reject_pet_change();

create trigger companion_paw_checks_guard
before insert or update or delete on public.companion_paw_checks
for each row execute function public.companion_guard_pet_record();

create trigger companion_weight_entries_updated_at
before update on public.companion_weight_entries
for each row execute function public.companion_set_updated_at();

create trigger companion_weight_entries_owner_lock
before update on public.companion_weight_entries
for each row execute function public.companion_reject_pet_change();

create trigger companion_weight_entries_guard
before insert or update or delete on public.companion_weight_entries
for each row execute function public.companion_guard_pet_record();

create trigger companion_moment_tags_guard
before insert or delete on public.companion_moment_tags
for each row execute function public.companion_guard_moment_tag();

-- Replaces the tags on one owned moment. The caller is the signed-in user,
-- so RLS still applies. An empty list clears the tags.
create or replace function public.companion_replace_moment_tags(
  p_moment_id uuid,
  p_tags text[]
)
returns text[]
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_owner uuid := auth.uid();
  v_tag text;
  v_clean text[] := '{}';
begin
  if v_owner is null then
    raise exception 'not authenticated' using errcode = '42501';
  end if;
  if p_tags is null then
    p_tags := '{}';
  end if;
  if cardinality(p_tags) > 5 then
    raise exception 'a moment can have at most five tags' using errcode = '23514';
  end if;
  if exists (
    select 1
    from unnest(p_tags) as item
    where item not in (
      'playing', 'sleeping', 'eating', 'exploring', 'socializing', 'learning',
      'cuddling', 'relaxing', 'outdoor', 'indoor', 'grooming', 'funny_moment'
    )
  ) then
    raise exception 'unknown moment tag' using errcode = '23514';
  end if;
  if cardinality(p_tags) <> (select count(distinct item) from unnest(p_tags) as item) then
    raise exception 'duplicate moment tag' using errcode = '23514';
  end if;

  if not exists (
    select 1
    from public.companion_moments m
    join public.companion_pets p
      on p.id = m.pet_id and p.owner_id = m.owner_id
    where m.id = p_moment_id
      and m.owner_id = v_owner
      and m.deletion_pending = false
      and p.deletion_pending = false
  ) then
    raise exception 'moment not found' using errcode = '42501';
  end if;

  delete from public.companion_moment_tags
  where moment_id = p_moment_id and owner_id = v_owner;

  foreach v_tag in array p_tags loop
    insert into public.companion_moment_tags (owner_id, moment_id, tag_key)
    values (v_owner, p_moment_id, v_tag);
    v_clean := array_append(v_clean, v_tag);
  end loop;

  return v_clean;
end;
$$;

revoke all on function public.companion_replace_moment_tags(uuid, text[]) from public, anon;
grant execute on function public.companion_replace_moment_tags(uuid, text[]) to authenticated;
