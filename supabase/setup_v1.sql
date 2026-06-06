-- MAST ETA Supabase setup v1
-- Run this in the Supabase SQL editor after creating the new project.
-- Project options recommended:
--   Enable Data API: ON
--   Automatically expose new tables: OFF
--   Enable automatic RLS: ON

create extension if not exists pgcrypto;

-- Drop views first when re-running during setup.
drop view if exists public.promotion_member_progress_view;
drop view if exists public.promotion_mission_progress_view;
drop view if exists public.promotion_assignment_status_view;

-- Common helpers
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- Core member table. auth_user_id is nullable for the current no-password flow.
create table if not exists public.members (
  id uuid primary key default gen_random_uuid(),
  auth_user_id uuid unique,
  name text not null,
  gi text not null,
  school text not null,
  major text,
  email text,
  role text not null default 'member'
    check (role in ('member', 'admin')),
  status text not null default 'active'
    check (status in ('active', 'inactive', 'archived')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (name, gi, school)
);

drop trigger if exists members_set_updated_at on public.members;
create trigger members_set_updated_at
before update on public.members
for each row execute function public.set_updated_at();

create index if not exists idx_members_name on public.members (name);
create index if not exists idx_members_status on public.members (status);
create unique index if not exists members_unique_identity_normalized
on public.members (
  lower(regexp_replace(trim(name), '\s+', '', 'g')),
  lower(regexp_replace(trim(gi), '\s+', '', 'g')),
  lower(regexp_replace(trim(school), '\s+', '', 'g'))
);

-- App settings. late_weight is used by progress views.
create table if not exists public.settings (
  key text primary key,
  value jsonb not null,
  description text,
  updated_at timestamptz not null default now()
);

insert into public.settings (key, value, description)
values
  ('promotion_late_weight', '0.5'::jsonb, 'Score given for a late completion.'),
  ('promotion_late_hours', '24'::jsonb, 'Late submission window after due_at, in hours.')
on conflict (key) do update
set value = excluded.value,
    description = excluded.description,
    updated_at = now();

-- Promotion domain
create table if not exists public.promotion_missions (
  id uuid primary key default gen_random_uuid(),
  mission_date date not null,
  title text not null,
  body text,
  post_title text,
  post_body text,
  due_at timestamptz not null,
  late_until_at timestamptz not null,
  status text not null default 'active'
    check (status in ('draft', 'active', 'closed', 'archived')),
  mission_image_url text,
  mission_image_path text,
  created_by text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (mission_date)
);

drop trigger if exists promotion_missions_set_updated_at on public.promotion_missions;
create trigger promotion_missions_set_updated_at
before update on public.promotion_missions
for each row execute function public.set_updated_at();

create index if not exists idx_promotion_missions_date on public.promotion_missions (mission_date desc);
create index if not exists idx_promotion_missions_status on public.promotion_missions (status);

create table if not exists public.promotion_mission_assignments (
  id uuid primary key default gen_random_uuid(),
  mission_id uuid not null references public.promotion_missions(id) on delete cascade,
  member_id uuid not null references public.members(id) on delete cascade,
  status text not null default 'pending'
    check (status in ('pending', 'submitted', 'approved', 'late', 'missed', 'rejected', 'exempted')),
  assigned_at timestamptz not null default now(),
  due_at timestamptz not null,
  late_until_at timestamptz not null,
  submitted_at timestamptz,
  reviewed_at timestamptz,
  reviewed_by_member_id uuid references public.members(id),
  status_reason text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (mission_id, member_id)
);

drop trigger if exists promotion_mission_assignments_set_updated_at on public.promotion_mission_assignments;
create trigger promotion_mission_assignments_set_updated_at
before update on public.promotion_mission_assignments
for each row execute function public.set_updated_at();

create index if not exists idx_assignments_mission on public.promotion_mission_assignments (mission_id);
create index if not exists idx_assignments_member on public.promotion_mission_assignments (member_id);
create index if not exists idx_assignments_status on public.promotion_mission_assignments (status);
create index if not exists idx_assignments_due_at on public.promotion_mission_assignments (due_at);

create table if not exists public.promotion_proofs (
  id uuid primary key default gen_random_uuid(),
  assignment_id uuid not null references public.promotion_mission_assignments(id) on delete cascade,
  mission_id uuid not null references public.promotion_missions(id) on delete cascade,
  member_id uuid not null references public.members(id) on delete cascade,
  proof_image_url text,
  proof_file_path text,
  post_url text,
  submitted_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (assignment_id)
);

drop trigger if exists promotion_proofs_set_updated_at on public.promotion_proofs;
create trigger promotion_proofs_set_updated_at
before update on public.promotion_proofs
for each row execute function public.set_updated_at();

create index if not exists idx_promotion_proofs_assignment on public.promotion_proofs (assignment_id);
create index if not exists idx_promotion_proofs_mission on public.promotion_proofs (mission_id);
create index if not exists idx_promotion_proofs_member on public.promotion_proofs (member_id);

create table if not exists public.promotion_assignment_status_logs (
  id uuid primary key default gen_random_uuid(),
  assignment_id uuid not null references public.promotion_mission_assignments(id) on delete cascade,
  changed_by text,
  changed_by_member_id uuid references public.members(id),
  from_status text,
  to_status text not null,
  reason text not null,
  created_at timestamptz not null default now()
);

create index if not exists idx_status_logs_assignment on public.promotion_assignment_status_logs (assignment_id);

create or replace function public.log_assignment_status_change()
returns trigger
language plpgsql
as $$
begin
  if tg_op = 'UPDATE' and old.status is distinct from new.status then
    if new.status <> 'submitted' and coalesce(trim(new.status_reason), '') = '' then
      raise exception 'status_reason is required when changing assignment status';
    end if;

    insert into public.promotion_assignment_status_logs (
      assignment_id,
      changed_by,
      changed_by_member_id,
      from_status,
      to_status,
      reason
    )
    values (
      new.id,
      current_setting('request.jwt.claim.sub', true),
      new.reviewed_by_member_id,
      old.status,
      new.status,
      coalesce(new.status_reason, 'proof submitted')
    );
  end if;

  return new;
end;
$$;

drop trigger if exists promotion_assignment_status_log on public.promotion_mission_assignments;
create trigger promotion_assignment_status_log
after update on public.promotion_mission_assignments
for each row execute function public.log_assignment_status_change();

-- Competition domain. App integration is phase 2.
create table if not exists public.competitions (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text,
  starts_at timestamptz,
  ends_at timestamptz,
  status text not null default 'draft'
    check (status in ('draft', 'open', 'closed', 'archived')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists competitions_set_updated_at on public.competitions;
create trigger competitions_set_updated_at
before update on public.competitions
for each row execute function public.set_updated_at();

create table if not exists public.competition_teams (
  id uuid primary key default gen_random_uuid(),
  competition_id uuid not null references public.competitions(id) on delete cascade,
  name text not null,
  description text,
  leader_member_id uuid references public.members(id),
  max_members integer check (max_members is null or max_members > 0),
  status text not null default 'recruiting'
    check (status in ('recruiting', 'full', 'closed', 'archived')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists competition_teams_set_updated_at on public.competition_teams;
create trigger competition_teams_set_updated_at
before update on public.competition_teams
for each row execute function public.set_updated_at();

create index if not exists idx_competition_teams_competition on public.competition_teams (competition_id);

create table if not exists public.competition_team_members (
  id uuid primary key default gen_random_uuid(),
  team_id uuid not null references public.competition_teams(id) on delete cascade,
  member_id uuid not null references public.members(id) on delete cascade,
  role text not null default 'member'
    check (role in ('leader', 'member')),
  joined_at timestamptz not null default now(),
  unique (team_id, member_id)
);

create index if not exists idx_competition_team_members_team on public.competition_team_members (team_id);
create index if not exists idx_competition_team_members_member on public.competition_team_members (member_id);

create table if not exists public.competition_applications (
  id uuid primary key default gen_random_uuid(),
  team_id uuid not null references public.competition_teams(id) on delete cascade,
  member_id uuid not null references public.members(id) on delete cascade,
  message text,
  status text not null default 'pending'
    check (status in ('pending', 'accepted', 'rejected', 'cancelled')),
  created_at timestamptz not null default now(),
  decided_at timestamptz,
  decided_by_member_id uuid references public.members(id),
  unique (team_id, member_id)
);

create index if not exists idx_competition_applications_team on public.competition_applications (team_id);
create index if not exists idx_competition_applications_member on public.competition_applications (member_id);
create index if not exists idx_competition_applications_status on public.competition_applications (status);

-- Progress views. submitted is excluded from completion-rate denominator until reviewed.
create or replace view public.promotion_assignment_status_view
with (security_invoker = true)
as
select
  a.*,
  m.mission_date,
  m.title as mission_title,
  mem.name as member_name,
  mem.gi,
  mem.school,
  mem.major,
  case
    when a.status = 'exempted' then false
    when a.status = 'submitted' then false
    else true
  end as counts_in_rate,
  case
    when a.status = 'approved' then 1.0::numeric
    when a.status = 'late' then coalesce((select (value #>> '{}')::numeric from public.settings where key = 'promotion_late_weight'), 0.5)
    when a.status in ('missed', 'rejected') then 0.0::numeric
    else null::numeric
  end as completion_score,
  case when a.status = 'late' then true else false end as is_late,
  case when a.status = 'exempted' then true else false end as is_exempted,
  case when a.status in ('missed', 'rejected') then true else false end as is_incomplete
from public.promotion_mission_assignments a
join public.promotion_missions m on m.id = a.mission_id
join public.members mem on mem.id = a.member_id;

create or replace view public.promotion_member_progress_view
with (security_invoker = true)
as
select
  member_id,
  member_name,
  gi,
  school,
  major,
  count(*) filter (where counts_in_rate) as target_count,
  count(*) filter (where status = 'approved') as approved_count,
  count(*) filter (where status = 'late') as late_count,
  count(*) filter (where status in ('missed', 'rejected')) as incomplete_count,
  count(*) filter (where status = 'submitted') as submitted_count,
  count(*) filter (where status = 'exempted') as exempted_count,
  round(coalesce(sum(completion_score) filter (where counts_in_rate), 0), 2) as earned_score,
  case
    when count(*) filter (where counts_in_rate) = 0 then null
    else round((coalesce(sum(completion_score) filter (where counts_in_rate), 0) / count(*) filter (where counts_in_rate)) * 100, 1)
  end as completion_rate
from public.promotion_assignment_status_view
group by member_id, member_name, gi, school, major;

create or replace view public.promotion_mission_progress_view
with (security_invoker = true)
as
select
  mission_id,
  mission_date,
  mission_title,
  count(*) filter (where counts_in_rate) as target_count,
  count(*) filter (where status = 'approved') as approved_count,
  count(*) filter (where status = 'late') as late_count,
  count(*) filter (where status in ('missed', 'rejected')) as incomplete_count,
  count(*) filter (where status = 'pending') as pending_count,
  count(*) filter (where status = 'submitted') as submitted_count,
  count(*) filter (where status = 'exempted') as exempted_count,
  round(coalesce(sum(completion_score) filter (where counts_in_rate), 0), 2) as earned_score,
  case
    when count(*) filter (where counts_in_rate) = 0 then null
    else round((coalesce(sum(completion_score) filter (where counts_in_rate), 0) / count(*) filter (where counts_in_rate)) * 100, 1)
  end as completion_rate
from public.promotion_assignment_status_view
group by mission_id, mission_date, mission_title;

-- Grants for Data API with "Automatically expose new tables" disabled.
grant usage on schema public to anon, authenticated;

grant select on public.members to anon, authenticated;
grant select on public.settings to anon, authenticated;
grant select on public.promotion_missions to anon, authenticated;
grant select on public.promotion_mission_assignments to anon, authenticated;
grant select on public.promotion_assignment_status_logs to anon, authenticated;
grant select on public.promotion_assignment_status_view to anon, authenticated;
grant select on public.promotion_member_progress_view to anon, authenticated;
grant select on public.promotion_mission_progress_view to anon, authenticated;

grant insert, update on public.promotion_proofs to anon, authenticated;
grant select, insert, update on public.promotion_mission_assignments to anon, authenticated;
grant select on public.promotion_proofs to anon, authenticated;

-- Phase-1 admin-code app support.
-- These grants are intentionally broad because the current app has no Supabase Auth session.
-- Tighten these by moving admin actions to Edge Functions/RPC before public launch.
grant insert, update, delete on public.members to anon, authenticated;
grant insert, update, delete on public.promotion_missions to anon, authenticated;
grant delete on public.promotion_proofs to anon, authenticated;
grant insert on public.promotion_assignment_status_logs to anon, authenticated;

-- Competition read grants for phase 2. Writes should be added when the app is implemented.
grant select on public.competitions to anon, authenticated;
grant select on public.competition_teams to anon, authenticated;
grant select on public.competition_team_members to anon, authenticated;
grant select on public.competition_applications to anon, authenticated;

-- RLS
alter table public.members enable row level security;
alter table public.settings enable row level security;
alter table public.promotion_missions enable row level security;
alter table public.promotion_mission_assignments enable row level security;
alter table public.promotion_proofs enable row level security;
alter table public.promotion_assignment_status_logs enable row level security;
alter table public.competitions enable row level security;
alter table public.competition_teams enable row level security;
alter table public.competition_team_members enable row level security;
alter table public.competition_applications enable row level security;

-- Drop existing policies for repeatable setup.
drop policy if exists "read active members" on public.members;
drop policy if exists "phase1 insert members" on public.members;
drop policy if exists "phase1 update members" on public.members;
drop policy if exists "phase1 delete members" on public.members;
drop policy if exists "read settings" on public.settings;
drop policy if exists "read promotion missions" on public.promotion_missions;
drop policy if exists "phase1 insert promotion missions" on public.promotion_missions;
drop policy if exists "phase1 update promotion missions" on public.promotion_missions;
drop policy if exists "phase1 delete promotion missions" on public.promotion_missions;
drop policy if exists "read assignments" on public.promotion_mission_assignments;
drop policy if exists "phase1 insert assignments" on public.promotion_mission_assignments;
drop policy if exists "phase1 update assignments" on public.promotion_mission_assignments;
drop policy if exists "phase1 delete assignments" on public.promotion_mission_assignments;
drop policy if exists "read proofs" on public.promotion_proofs;
drop policy if exists "submit proofs" on public.promotion_proofs;
drop policy if exists "update proofs" on public.promotion_proofs;
drop policy if exists "delete proofs" on public.promotion_proofs;
drop policy if exists "read status logs" on public.promotion_assignment_status_logs;
drop policy if exists "insert status logs" on public.promotion_assignment_status_logs;
drop policy if exists "read competitions" on public.competitions;
drop policy if exists "read competition teams" on public.competition_teams;
drop policy if exists "read competition team members" on public.competition_team_members;
drop policy if exists "read competition applications" on public.competition_applications;

create policy "read active members"
on public.members for select
to anon, authenticated
using (status = 'active');

create policy "phase1 insert members"
on public.members for insert
to anon, authenticated
with check (true);

create policy "phase1 update members"
on public.members for update
to anon, authenticated
using (true)
with check (true);

create policy "phase1 delete members"
on public.members for delete
to anon, authenticated
using (true);

create policy "read settings"
on public.settings for select
to anon, authenticated
using (true);

create policy "read promotion missions"
on public.promotion_missions for select
to anon, authenticated
using (status in ('active', 'closed', 'archived'));

create policy "phase1 insert promotion missions"
on public.promotion_missions for insert
to anon, authenticated
with check (true);

create policy "phase1 update promotion missions"
on public.promotion_missions for update
to anon, authenticated
using (true)
with check (true);

create policy "phase1 delete promotion missions"
on public.promotion_missions for delete
to anon, authenticated
using (true);

create policy "read assignments"
on public.promotion_mission_assignments for select
to anon, authenticated
using (true);

create policy "phase1 insert assignments"
on public.promotion_mission_assignments for insert
to anon, authenticated
with check (true);

create policy "phase1 update assignments"
on public.promotion_mission_assignments for update
to anon, authenticated
using (true)
with check (true);

create policy "phase1 delete assignments"
on public.promotion_mission_assignments for delete
to anon, authenticated
using (true);

create policy "read proofs"
on public.promotion_proofs for select
to anon, authenticated
using (true);

create policy "submit proofs"
on public.promotion_proofs for insert
to anon, authenticated
with check (true);

create policy "update proofs"
on public.promotion_proofs for update
to anon, authenticated
using (true)
with check (true);

create policy "delete proofs"
on public.promotion_proofs for delete
to anon, authenticated
using (true);

create policy "read status logs"
on public.promotion_assignment_status_logs for select
to anon, authenticated
using (true);

create policy "insert status logs"
on public.promotion_assignment_status_logs for insert
to anon, authenticated
with check (true);

create policy "read competitions"
on public.competitions for select
to anon, authenticated
using (status in ('open', 'closed', 'archived'));

create policy "read competition teams"
on public.competition_teams for select
to anon, authenticated
using (status in ('recruiting', 'full', 'closed', 'archived'));

create policy "read competition team members"
on public.competition_team_members for select
to anon, authenticated
using (true);

create policy "read competition applications"
on public.competition_applications for select
to anon, authenticated
using (true);

-- Storage buckets used by the app.
insert into storage.buckets (id, name, public)
values
  ('proofs', 'proofs', true),
  ('missions', 'missions', true)
on conflict (id) do update
set public = excluded.public;

drop policy if exists "read proof files" on storage.objects;
drop policy if exists "upload proof files" on storage.objects;
drop policy if exists "update proof files" on storage.objects;
drop policy if exists "delete proof files" on storage.objects;
drop policy if exists "read mission files" on storage.objects;
drop policy if exists "upload mission files" on storage.objects;
drop policy if exists "update mission files" on storage.objects;
drop policy if exists "delete mission files" on storage.objects;

create policy "read proof files"
on storage.objects for select
to anon, authenticated
using (bucket_id = 'proofs');

create policy "upload proof files"
on storage.objects for insert
to anon, authenticated
with check (bucket_id = 'proofs');

create policy "update proof files"
on storage.objects for update
to anon, authenticated
using (bucket_id = 'proofs')
with check (bucket_id = 'proofs');

create policy "delete proof files"
on storage.objects for delete
to anon, authenticated
using (bucket_id = 'proofs');

create policy "read mission files"
on storage.objects for select
to anon, authenticated
using (bucket_id = 'missions');

create policy "upload mission files"
on storage.objects for insert
to anon, authenticated
with check (bucket_id = 'missions');

create policy "update mission files"
on storage.objects for update
to anon, authenticated
using (bucket_id = 'missions')
with check (bucket_id = 'missions');

create policy "delete mission files"
on storage.objects for delete
to anon, authenticated
using (bucket_id = 'missions');

-- Verification queries to run manually after setup:
-- select * from public.settings;
-- select table_name from information_schema.tables where table_schema = 'public' order by table_name;
-- select schemaname, tablename, policyname, cmd from pg_policies where schemaname in ('public', 'storage') order by schemaname, tablename, policyname;
