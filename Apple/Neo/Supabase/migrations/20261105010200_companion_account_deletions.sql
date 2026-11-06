-- Resumable account-deletion log for the native app.
-- NOT APPLIED. Run only after the Phase 1 companion tables exist.
-- The iOS client cannot read or write this table.
-- The delete-account Edge Function uses the service role, which bypasses RLS.
-- Does not alter Expo tables and does not delete pets, moments, or files.

create table public.companion_account_deletions (
  owner_id uuid primary key references auth.users (id) on delete cascade,
  stage text not null,
  updated_at timestamptz not null default now(),
  constraint companion_account_deletions_stage_check
    check (stage in ('storage', 'records', 'auth', 'deleted'))
);

alter table public.companion_account_deletions enable row level security;

revoke all on table public.companion_account_deletions from public, anon, authenticated;

comment on table public.companion_account_deletions is
  'Server-only progress for delete-account. A failed run is resumed by calling the function again.';
