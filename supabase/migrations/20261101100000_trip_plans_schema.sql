-- Trip planner v2, part 1: tables, limits, access rules and switches.
--
-- A plan is its own object: a title, a start, an optional start date, a
-- loose "places to visit" list and days of ordered stops. Members can read a
-- plan; owners and editors change it. Clients never write these tables
-- directly: every change goes through the functions in part 2, which check
-- membership, role and the owner's limits (Free or Pro).
--
-- Plan: claude/trip-planner-build-plan.md (decisions D1 to D17).
-- Invites, joining and roles beyond the owner arrive with slice S9; the
-- members table is created now so access rules are final from the start.

create schema if not exists trip_plan_private;
revoke all on schema trip_plan_private from public;

-- Plans ---------------------------------------------------------------------

create table public.trip_plans (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users (id) on delete cascade,
  title text not null check (length(btrim(title)) between 1 and 80),
  -- Where Day 1 starts: the phone's location when the trip starts, a place,
  -- or a point picked on the map. A place or point keeps a label so the
  -- plan still reads well if the place is removed later.
  start_kind text not null default 'current_location'
    check (start_kind in ('current_location', 'place', 'point')),
  start_place_id uuid references public.places (id) on delete set null,
  start_label text check (start_label is null or length(btrim(start_label)) between 1 and 120),
  start_lat double precision check (start_lat is null or start_lat between -90 and 90),
  start_lng double precision check (start_lng is null or start_lng between -180 and 180),
  start_date date,
  archived_at timestamptz,
  -- Set on plans made from the old planner's saved_trips. They never count
  -- toward the Free plan limit (D5).
  converted_from_saved_trip uuid unique,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  updated_by uuid references auth.users (id) on delete set null,
  constraint trip_plans_start_point_check check (
    (start_lat is null) = (start_lng is null)
    and (start_kind <> 'point' or start_lat is not null)
  )
);

create index trip_plans_owner_idx on public.trip_plans (owner_id, archived_at);

-- Days ----------------------------------------------------------------------
-- position is the day's number (1, 2, 3...). Removing a day renumbers the
-- rest; stops and recordings point at the day's id, not its number.

create table public.trip_plan_days (
  id uuid primary key default gen_random_uuid(),
  plan_id uuid not null references public.trip_plans (id) on delete cascade,
  position integer not null check (position between 1 and 60),
  title text check (title is null or length(btrim(title)) between 1 and 60),
  -- Optional overnight place or point. Without one the next day starts where
  -- this day's last stop is.
  overnight_place_id uuid references public.places (id) on delete set null,
  overnight_label text check (overnight_label is null or length(btrim(overnight_label)) between 1 and 120),
  overnight_lat double precision check (overnight_lat is null or overnight_lat between -90 and 90),
  overnight_lng double precision check (overnight_lng is null or overnight_lng between -180 and 180),
  -- The last route the app worked out for this day, so plan cards can show
  -- distance and counties without routing every plan. route_stops_key is
  -- the stop ids in order when it was worked out; a stale key is refused.
  route_stops_key text,
  route_distance_m integer check (route_distance_m is null or route_distance_m >= 0),
  route_duration_s integer check (route_duration_s is null or route_duration_s >= 0),
  route_county_codes smallint[],
  route_updated_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint trip_plan_days_overnight_point_check check (
    (overnight_lat is null) = (overnight_lng is null)
  )
);

create index trip_plan_days_plan_idx on public.trip_plan_days (plan_id, position);

-- Stops ---------------------------------------------------------------------
-- One row per stop, so two people editing different stops never overwrite
-- each other. position uses gaps (1024, 2048...) so a move touches one row;
-- the move functions rebalance a day when a gap runs out (D17).

create table public.trip_plan_stops (
  id uuid primary key default gen_random_uuid(),
  plan_id uuid not null references public.trip_plans (id) on delete cascade,
  day_id uuid not null references public.trip_plan_days (id) on delete cascade,
  place_id uuid not null references public.places (id) on delete cascade,
  position integer not null,
  note text check (note is null or length(btrim(note)) between 1 and 200),
  added_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index trip_plan_stops_day_idx on public.trip_plan_stops (day_id, position);
create index trip_plan_stops_plan_idx on public.trip_plan_stops (plan_id);

-- Places to visit -----------------------------------------------------------
-- Ideas not yet on a day. A place is on the list at most once.

create table public.trip_plan_places (
  id uuid primary key default gen_random_uuid(),
  plan_id uuid not null references public.trip_plans (id) on delete cascade,
  place_id uuid not null references public.places (id) on delete cascade,
  note text check (note is null or length(btrim(note)) between 1 and 200),
  added_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now(),
  unique (plan_id, place_id)
);

-- Members -------------------------------------------------------------------
-- The owner is a member too (role owner). Editors and viewers arrive with
-- invites (S9).

create table public.trip_plan_members (
  plan_id uuid not null references public.trip_plans (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  role text not null check (role in ('owner', 'editor', 'viewer')),
  status text not null default 'joined' check (status in ('invited', 'joined')),
  invited_by uuid references auth.users (id) on delete set null,
  muted boolean not null default false,
  joined_at timestamptz,
  created_at timestamptz not null default now(),
  primary key (plan_id, user_id)
);

create unique index trip_plan_members_one_owner_idx
  on public.trip_plan_members (plan_id) where role = 'owner';
create index trip_plan_members_user_idx on public.trip_plan_members (user_id, status);

-- Helpers -------------------------------------------------------------------

-- The caller's role in a plan if they have joined it, else null.
create function trip_plan_private.role_of(p_plan uuid, p_user uuid)
returns text
language sql
stable
security definer
set search_path = ''
as $$
  select m.role from public.trip_plan_members m
  where m.plan_id = p_plan and m.user_id = p_user and m.status = 'joined';
$$;

create function trip_plan_private.is_member(p_plan uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select trip_plan_private.role_of(p_plan, auth.uid()) is not null;
$$;

-- The owner's limits (D1: a plan's limits always come from its owner).
-- Null means no limit.
create function trip_plan_private.limits(p_owner uuid)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select case when public.has_pro_at(p_owner, now()) then jsonb_build_object(
      'pro', true, 'max_upcoming_plans', null, 'max_days', 14,
      'max_stops_per_day', 20, 'max_places', 100, 'max_members', 6,
      'roles', true, 'best_order', true, 'offline_copy', true)
    else jsonb_build_object(
      'pro', false, 'max_upcoming_plans', 3, 'max_days', 3,
      'max_stops_per_day', 8, 'max_places', 30, 'max_members', 2,
      'roles', false, 'best_order', false, 'offline_copy', false)
    end;
$$;

-- A plan is past when its last day's date has gone by (D16: past plans never
-- count). Undated plans are never past.
create function trip_plan_private.is_past(p_plan uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select p.start_date is not null
    and p.start_date + (
      (select count(*) from public.trip_plan_days d where d.plan_id = p.id)::integer - 1
    ) < current_date
  from public.trip_plans p where p.id = p_plan;
$$;

-- Plans that count toward the Free limit of 3 upcoming plans (D5, D6):
-- owned, not archived, not past, not converted from the old planner.
create function trip_plan_private.upcoming_count(p_owner uuid)
returns integer
language sql
stable
security definer
set search_path = ''
as $$
  select count(*)::integer from public.trip_plans p
  where p.owner_id = p_owner
    and p.archived_at is null
    and p.converted_from_saved_trip is null
    and not coalesce(trip_plan_private.is_past(p.id), false);
$$;

-- The planner switch: writes are refused while it is off, so turning it off
-- from the dashboard stops new plans and edits at once.
create function trip_plan_private.assert_enabled()
returns void
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not exists (select 1 from public.app_feature_flags f
      where f.feature_key = 'trip_plans' and f.enabled) then
    raise exception 'trip_plans_unavailable' using errcode = '42501';
  end if;
end $$;

-- Raises unless the caller may change the plan (owner or editor), and
-- returns the plan's owner for limit checks.
create function trip_plan_private.assert_editor(p_plan uuid)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare v_role text; v_owner uuid;
begin
  perform trip_plan_private.assert_enabled();
  if auth.uid() is null then
    raise exception 'not_signed_in' using errcode = '42501';
  end if;
  v_role := trip_plan_private.role_of(p_plan, auth.uid());
  if v_role is null then
    raise exception 'trip_plan_not_found' using errcode = 'P0002';
  end if;
  if v_role not in ('owner', 'editor') then
    raise exception 'trip_plan_view_only' using errcode = '42501';
  end if;
  select p.owner_id into v_owner from public.trip_plans p where p.id = p_plan;
  return v_owner;
end $$;

create function trip_plan_private.assert_owner(p_plan uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform trip_plan_private.assert_enabled();
  if trip_plan_private.role_of(p_plan, auth.uid()) is distinct from 'owner' then
    raise exception 'trip_plan_owner_only' using errcode = '42501';
  end if;
end $$;

-- Only places app users can see (reviewed, not archived) can be planned.
create function trip_plan_private.assert_place(p_place uuid)
returns void
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if p_place is null or not exists (select 1 from public.places pl
      where pl.id = p_place and pl.status = 'reviewed' and pl.archived_at is null) then
    raise exception 'trip_plan_place_unavailable' using errcode = '22023';
  end if;
end $$;

-- Marks a plan changed (plan cards sort and show "updated by" from this).
create function trip_plan_private.touch(p_plan uuid)
returns void
language sql
security definer
set search_path = ''
as $$
  update public.trip_plans set updated_at = now(), updated_by = auth.uid()
  where id = p_plan;
$$;

revoke all on all functions in schema trip_plan_private from public;
grant usage on schema trip_plan_private to authenticated;
grant execute on function trip_plan_private.is_member(uuid) to authenticated;

-- Row level security: members read, nobody writes directly ------------------

alter table public.trip_plans enable row level security;
alter table public.trip_plan_days enable row level security;
alter table public.trip_plan_stops enable row level security;
alter table public.trip_plan_places enable row level security;
alter table public.trip_plan_members enable row level security;

create policy "Members read their plans" on public.trip_plans
  for select to authenticated using (trip_plan_private.is_member(id));
create policy "Members read plan days" on public.trip_plan_days
  for select to authenticated using (trip_plan_private.is_member(plan_id));
create policy "Members read plan stops" on public.trip_plan_stops
  for select to authenticated using (trip_plan_private.is_member(plan_id));
create policy "Members read plan places" on public.trip_plan_places
  for select to authenticated using (trip_plan_private.is_member(plan_id));
create policy "Members read plan members" on public.trip_plan_members
  for select to authenticated using (trip_plan_private.is_member(plan_id));

revoke all on public.trip_plans, public.trip_plan_days, public.trip_plan_stops,
  public.trip_plan_places, public.trip_plan_members from anon, authenticated;
grant select on public.trip_plans, public.trip_plan_days, public.trip_plan_stops,
  public.trip_plan_places, public.trip_plan_members to authenticated;

-- Live updates for shared plans (used from S10). RLS applies to Realtime.
do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    alter publication supabase_realtime add table
      public.trip_plans, public.trip_plan_days, public.trip_plan_stops,
      public.trip_plan_places, public.trip_plan_members;
  end if;
end $$;

-- Dashboard switches --------------------------------------------------------
-- trip_plans: the planner (Planned in the Trips tab, Add to trip).
-- trip_plan_invites: sharing a plan (S9). Both off by default.

alter table public.app_feature_flags
  drop constraint if exists app_feature_flags_feature_key_check;
alter table public.app_feature_flags add constraint app_feature_flags_feature_key_check
  check (feature_key in (
    'county_news', 'public_trips_read', 'public_trips_publish',
    'place_photos', 'push_broadcasts', 'place_check_ins', 'ads',
    'trip_plans', 'trip_plan_invites'
  ));
insert into public.app_feature_flags (feature_key, enabled)
values ('trip_plans', false), ('trip_plan_invites', false)
on conflict (feature_key) do nothing;

create or replace function public.set_trip_plans_flag_dashboard(
  p_feature_key text,
  p_enabled boolean
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
begin
  if coalesce(public.current_admin_role() in ('owner', 'admin'), false) is not true then
    raise exception 'Owner or admin access required' using errcode = '42501';
  end if;
  if p_feature_key is null or p_feature_key not in ('trip_plans', 'trip_plan_invites') then
    raise exception 'Unknown planner switch' using errcode = '22023';
  end if;
  if p_enabled is null then
    raise exception 'Enabled value is required' using errcode = '22004';
  end if;
  insert into public.app_feature_flags (feature_key, enabled, updated_at, updated_by)
  values (p_feature_key, p_enabled, now(), auth.uid())
  on conflict (feature_key) do update
  set enabled = excluded.enabled,
      updated_at = excluded.updated_at,
      updated_by = excluded.updated_by;
  return p_enabled;
end;
$$;

revoke execute on function public.set_trip_plans_flag_dashboard(text, boolean) from public;
grant execute on function public.set_trip_plans_flag_dashboard(text, boolean) to authenticated;
