-- Neo Supabase schema
-- Run in Supabase SQL editor

create extension if not exists "uuid-ossp";

create table if not exists pets (
  id uuid primary key default uuid_generate_v4(),
  name text not null,
  species text not null,
  breed text not null,
  age text not null,
  weight text,
  photo_uri text,
  created_at timestamptz not null default now()
);

create table if not exists lifestyle_answers (
  id uuid primary key default uuid_generate_v4(),
  pet_id uuid not null references pets(id) on delete cascade,
  play_frequency text not null,
  new_environments text not null,
  enrichment text not null,
  socialization text not null,
  favorite_activities text not null,
  created_at timestamptz not null default now()
);

create table if not exists future_snapshots (
  id uuid primary key default uuid_generate_v4(),
  pet_id uuid not null references pets(id) on delete cascade,
  lifestyle_answers_id uuid not null references lifestyle_answers(id) on delete cascade,
  today text not null,
  six_months text not null,
  two_years text not null,
  five_years text not null,
  created_at timestamptz not null default now()
);

create table if not exists missing_moments (
  id uuid primary key default uuid_generate_v4(),
  pet_id uuid not null references pets(id) on delete cascade,
  moments_being_created text[] not null,
  moments_potentially_missing text[] not null,
  suggestions text[] not null,
  created_at timestamptz not null default now()
);

create table if not exists memories (
  id uuid primary key default uuid_generate_v4(),
  pet_id uuid not null references pets(id) on delete cascade,
  title text not null,
  description text not null,
  photo_uri text,
  created_at timestamptz not null default now()
);

create index if not exists idx_lifestyle_answers_pet_id on lifestyle_answers(pet_id);
create index if not exists idx_future_snapshots_pet_id on future_snapshots(pet_id);
create index if not exists idx_missing_moments_pet_id on missing_moments(pet_id);
create index if not exists idx_memories_pet_id on memories(pet_id);

alter table pets enable row level security;
alter table lifestyle_answers enable row level security;
alter table future_snapshots enable row level security;
alter table missing_moments enable row level security;
alter table memories enable row level security;

-- MVP: open policies for anon key usage. Tighten before production.
create policy "Allow all pets" on pets for all using (true) with check (true);
create policy "Allow all lifestyle_answers" on lifestyle_answers for all using (true) with check (true);
create policy "Allow all future_snapshots" on future_snapshots for all using (true) with check (true);
create policy "Allow all missing_moments" on missing_moments for all using (true) with check (true);
create policy "Allow all memories" on memories for all using (true) with check (true);
