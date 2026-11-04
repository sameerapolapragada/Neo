-- NOT APPLIED. Do not run this against a live or shared project.
-- Additive only. It does not alter Expo tables (`pets`, `memories`) and it does
-- not drop companion data. Account deletion itself runs in the Edge Function,
-- which uses the service-role key from the function environment, never the app.
--
-- The log lets a failed cleanup be resumed. The function writes the stage it
-- reached. A retry continues from storage, then rows, then the Auth user.
-- Authenticated clients cannot read or write this table. Only the service role,
-- which bypasses RLS, uses it.

create table if not exists public.companion_account_deletions (
  owner_id uuid primary key,
  stage text not null check (stage in ('storage', 'records', 'auth', 'deleted')),
  updated_at timestamptz not null default now()
);

alter table public.companion_account_deletions enable row level security;

revoke all on table public.companion_account_deletions from public;
revoke all on table public.companion_account_deletions from anon;
revoke all on table public.companion_account_deletions from authenticated;
