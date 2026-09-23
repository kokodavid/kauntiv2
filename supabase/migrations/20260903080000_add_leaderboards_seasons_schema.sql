-- Leaderboards & Seasons, module 1: competitive schema, RPCs, and
-- eligibility rules.
--
-- The important line this migration draws is between personal progress and
-- competition. `county_visits` remains the compact per-county progress row
-- used by Map Home, Discover, and Badges. Competitive standings read an
-- append-only event log instead, so seasonal boards can count visits inside a
-- 90-day window and depth ranks can eventually use distinct calendar months.
--
-- Eligibility is deliberately strict:
--   - confirmed EXPLORED outcomes only
--   - automatic detection only; manual-mode visits never enter boards
--   - the user must opt in via profiles.show_on_leaderboards
--   - the user must have a verified, unexpired device attestation
--
-- That last gate means early dev boards will be empty until the attestation
-- write path exists or a dev seed marks a test user verified. This is
-- intentional: Ranks is the trust-sensitive feature, so the schema starts with
-- the competitive rule rather than adding it after a public board exists.

-- ---------------------------------------------------------------------
-- Seasons
-- ---------------------------------------------------------------------

create table if not exists public.leaderboard_seasons (
  id uuid primary key default gen_random_uuid(),
  season_number integer not null unique,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  status text not null default 'scheduled'
    check (status in ('scheduled', 'active', 'closed')),
  closed_at timestamptz,
  created_at timestamptz not null default now(),
  check (ends_at > starts_at),
  check (
    (status = 'closed' and closed_at is not null)
    or (status <> 'closed' and closed_at is null)
  )
);

create unique index if not exists leaderboard_seasons_one_active_idx
  on public.leaderboard_seasons ((status))
  where status = 'active';

alter table public.leaderboard_seasons enable row level security;

drop policy if exists "Anyone signed in can read leaderboard seasons"
  on public.leaderboard_seasons;

create policy "Anyone signed in can read leaderboard seasons"
  on public.leaderboard_seasons
  for select
  to authenticated
  using (true);

-- ---------------------------------------------------------------------
-- Device eligibility
-- ---------------------------------------------------------------------

alter table public.profiles
  add column if not exists show_on_leaderboards boolean not null default true;

create table if not exists public.competitive_device_attestations (
  user_id uuid primary key references auth.users (id) on delete cascade,
  provider text not null check (provider in ('play_integrity', 'app_attest')),
  status text not null default 'pending'
    check (status in ('pending', 'verified', 'rejected', 'expired')),
  verified_at timestamptz,
  expires_at timestamptz,
  updated_at timestamptz not null default now(),
  check (
    (status = 'verified' and verified_at is not null and expires_at is not null)
    or status <> 'verified'
  )
);

alter table public.competitive_device_attestations enable row level security;

drop policy if exists "Users can read their own competitive attestation"
  on public.competitive_device_attestations;

create policy "Users can read their own competitive attestation"
  on public.competitive_device_attestations
  for select
  to authenticated
  using (auth.uid() = user_id);

-- No client insert/update policies on purpose. A trusted server/Admin path must
-- verify Play Integrity/App Attest evidence and write this table.

-- ---------------------------------------------------------------------
-- Append-only visit events for competitive accounting
-- ---------------------------------------------------------------------

create table if not exists public.county_visit_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  county_id smallint not null references public.counties (id),
  outcome text not null check (outcome in ('explored', 'passed_through')),
  source text not null default 'automatic'
    check (source in ('automatic', 'manual', 'dev_seed')),
  entered_at timestamptz not null,
  confirmed_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create index if not exists county_visit_events_user_county_entered_idx
  on public.county_visit_events (user_id, county_id, entered_at desc);

create index if not exists county_visit_events_county_entered_idx
  on public.county_visit_events (county_id, entered_at desc)
  where outcome = 'explored' and source = 'automatic';

alter table public.county_visit_events enable row level security;

drop policy if exists "Users can read their own county visit events"
  on public.county_visit_events;

create policy "Users can read their own county visit events"
  on public.county_visit_events
  for select
  to authenticated
  using (auth.uid() = user_id);

-- No client insert/update/delete policies. `record_county_visit()` is the
-- trusted write path for automatic detection.

-- Backfill one event for already-confirmed explored visits. This preserves
-- existing progress enough for development, but cannot reconstruct historical
-- repeat visits because older schema only kept a counter and latest timestamp.
insert into public.county_visit_events (
  user_id,
  county_id,
  outcome,
  source,
  entered_at,
  confirmed_at
)
select
  v.user_id,
  v.county_id,
  'explored',
  'automatic',
  v.entered_at,
  coalesce(v.confirmed_at, v.entered_at)
from public.county_visits v
where v.state = 'explored'
  and v.confirmed_at is not null
  and not exists (
    select 1
    from public.county_visit_events e
    where e.user_id = v.user_id
      and e.county_id = v.county_id
      and e.entered_at = v.entered_at
      and e.outcome = 'explored'
  );

-- ---------------------------------------------------------------------
-- Season honours: settled profile records after season close.
-- ---------------------------------------------------------------------

create table if not exists public.season_honours (
  season_id uuid not null references public.leaderboard_seasons (id)
    on delete cascade,
  county_id smallint not null references public.counties (id),
  user_id uuid not null references auth.users (id) on delete cascade,
  segment text not null check (segment in ('locals', 'visitors')),
  rank_position integer not null check (rank_position > 0),
  field_size integer not null check (field_size > 0),
  visits integer not null check (visits > 0),
  settled_at timestamptz not null default now(),
  primary key (season_id, county_id, segment, user_id)
);

create index if not exists season_honours_user_idx
  on public.season_honours (user_id, settled_at desc);

alter table public.season_honours enable row level security;

drop policy if exists "Users can read their own season honours"
  on public.season_honours;

create policy "Users can read their own season honours"
  on public.season_honours
  for select
  to authenticated
  using (auth.uid() = user_id);

-- ---------------------------------------------------------------------
-- Eligibility helper
-- ---------------------------------------------------------------------

create or replace function public.competitive_eligibility(p_user_id uuid)
returns table (
  user_id uuid,
  is_eligible boolean,
  show_on_leaderboards boolean,
  location_mode text,
  attestation_status text,
  attestation_expires_at timestamptz,
  in_manual_mode boolean,
  missing_verified_attestation boolean
)
language sql
stable
security definer
set search_path = public, extensions
as $$
  select
    p.id as user_id,
    coalesce(p.show_on_leaderboards, true)
      and p.location_mode = 'automatic'
      and coalesce(a.status = 'verified' and a.expires_at > now(), false)
        as is_eligible,
    coalesce(p.show_on_leaderboards, true) as show_on_leaderboards,
    p.location_mode,
    coalesce(a.status, 'missing') as attestation_status,
    a.expires_at as attestation_expires_at,
    p.location_mode = 'manual' as in_manual_mode,
    not coalesce(a.status = 'verified' and a.expires_at > now(), false)
      as missing_verified_attestation
  from public.profiles p
  left join public.competitive_device_attestations a on a.user_id = p.id
  where p.id = p_user_id
    and p.id = auth.uid();
$$;

revoke execute on function public.competitive_eligibility(uuid) from public;
grant execute on function public.competitive_eligibility(uuid) to authenticated;

create or replace function public.my_competitive_eligibility()
returns table (
  user_id uuid,
  is_eligible boolean,
  show_on_leaderboards boolean,
  location_mode text,
  attestation_status text,
  attestation_expires_at timestamptz,
  in_manual_mode boolean,
  missing_verified_attestation boolean
)
language sql
stable
security definer
set search_path = public, extensions
as $$
  select *
  from public.competitive_eligibility(auth.uid());
$$;

revoke execute on function public.my_competitive_eligibility() from public;
grant execute on function public.my_competitive_eligibility() to authenticated;

-- ---------------------------------------------------------------------
-- Single write path for automatic visits, now also logging events.
-- ---------------------------------------------------------------------

create or replace function public.record_county_visit(
  p_county_id smallint,
  p_outcome text,
  p_entered_at timestamptz
)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_user_id uuid := auth.uid();
  v_existing public.county_visits;
begin
  if v_user_id is null then
    raise exception 'record_county_visit requires an authenticated user';
  end if;

  if p_outcome not in ('explored', 'passed_through') then
    raise exception 'record_county_visit: invalid outcome %', p_outcome;
  end if;

  insert into public.county_visit_events (
    user_id,
    county_id,
    outcome,
    source,
    entered_at,
    confirmed_at
  )
  values (
    v_user_id,
    p_county_id,
    p_outcome,
    'automatic',
    p_entered_at,
    now()
  );

  select * into v_existing
  from public.county_visits
  where user_id = v_user_id and county_id = p_county_id
  for update;

  if not found then
    insert into public.county_visits (
      user_id,
      county_id,
      state,
      entered_at,
      confirmed_at,
      pass_count
    )
    values (
      v_user_id,
      p_county_id,
      p_outcome,
      p_entered_at,
      case when p_outcome = 'explored' then now() else null end,
      1
    );
    return;
  end if;

  if v_existing.state = 'explored' then
    update public.county_visits
      set pass_count = pass_count + 1
      where id = v_existing.id;
    return;
  end if;

  update public.county_visits
    set state = p_outcome,
        entered_at = p_entered_at,
        pass_count = pass_count + 1,
        confirmed_at = case
          when p_outcome = 'explored' then now()
          else confirmed_at
        end
    where id = v_existing.id;
end;
$$;

revoke execute on function public.record_county_visit(smallint, text, timestamptz) from public;
grant execute on function public.record_county_visit(smallint, text, timestamptz) to authenticated;

-- ---------------------------------------------------------------------
-- Leaderboard RPCs
-- ---------------------------------------------------------------------

create or replace function public.active_leaderboard_season()
returns table (
  season_id uuid,
  season_number integer,
  starts_at timestamptz,
  ends_at timestamptz,
  days_remaining integer
)
language sql
stable
security definer
set search_path = public, extensions
as $$
  select
    s.id,
    s.season_number,
    s.starts_at,
    s.ends_at,
    greatest(ceil(extract(epoch from (s.ends_at - now())) / 86400), 0)::integer
      as days_remaining
  from public.leaderboard_seasons s
  where s.status = 'active'
    and s.starts_at <= now()
    and s.ends_at > now()
  order by s.starts_at desc
  limit 1;
$$;

revoke execute on function public.active_leaderboard_season() from public;
grant execute on function public.active_leaderboard_season() to authenticated;

create or replace function public.county_season_leaderboard(
  p_county_id smallint,
  p_segment text default 'visitors',
  p_limit integer default 50,
  p_season_id uuid default null
)
returns table (
  user_id uuid,
  rank_position bigint,
  visits bigint,
  segment text,
  field_size bigint,
  is_current_user boolean
)
language sql
stable
security definer
set search_path = public, extensions
as $$
  with selected_season as (
    select s.*
    from public.leaderboard_seasons s
    where s.id = coalesce(
      p_season_id,
      (
        select active.id
        from public.leaderboard_seasons active
        where active.status = 'active'
          and active.starts_at <= now()
          and active.ends_at > now()
        order by active.starts_at desc
        limit 1
      )
    )
  ),
  eligible_events as (
    select
      e.user_id,
      case
        when p.home_county_id = p_county_id then 'locals'
        else 'visitors'
      end as segment
    from public.county_visit_events e
    join selected_season s on e.entered_at >= s.starts_at
      and e.entered_at < s.ends_at
    join public.profiles p on p.id = e.user_id
    join public.competitive_device_attestations a on a.user_id = e.user_id
    where e.county_id = p_county_id
      and e.outcome = 'explored'
      and e.source = 'automatic'
      and p.show_on_leaderboards = true
      and p.location_mode = 'automatic'
      and a.status = 'verified'
      and a.expires_at > now()
  ),
  scored as (
    select eligible_events.user_id, eligible_events.segment, count(*) as visits
    from eligible_events
    where eligible_events.segment = p_segment
    group by eligible_events.user_id, eligible_events.segment
  ),
  ranked as (
    select
      scored.*,
      rank() over (order by scored.visits desc, scored.user_id)
        as rank_position,
      count(*) over () as field_size
    from scored
  )
  select
    ranked.user_id,
    ranked.rank_position,
    ranked.visits,
    ranked.segment,
    ranked.field_size,
    ranked.user_id = auth.uid() as is_current_user
  from ranked
  where ranked.rank_position <= greatest(p_limit, 1)
     or ranked.user_id = auth.uid()
  order by ranked.rank_position asc, ranked.user_id;
$$;

revoke execute on function public.county_season_leaderboard(smallint, text, integer, uuid) from public;
grant execute on function public.county_season_leaderboard(smallint, text, integer, uuid) to authenticated;

create or replace function public.kenya_season_leaderboard(
  p_limit integer default 50,
  p_season_id uuid default null
)
returns table (
  user_id uuid,
  rank_position bigint,
  score bigint,
  held_counties bigint,
  rare_counties bigint,
  field_size bigint,
  is_current_user boolean
)
language sql
stable
security definer
set search_path = public, extensions
as $$
  with selected_season as (
    select s.*
    from public.leaderboard_seasons s
    where s.id = coalesce(
      p_season_id,
      (
        select active.id
        from public.leaderboard_seasons active
        where active.status = 'active'
          and active.starts_at <= now()
          and active.ends_at > now()
        order by active.starts_at desc
        limit 1
      )
    )
  ),
  held as (
    select distinct e.user_id, e.county_id
    from public.county_visit_events e
    join selected_season s on e.entered_at >= s.starts_at
      and e.entered_at < s.ends_at
    join public.profiles p on p.id = e.user_id
    join public.competitive_device_attestations a on a.user_id = e.user_id
    where e.outcome = 'explored'
      and e.source = 'automatic'
      and p.show_on_leaderboards = true
      and p.location_mode = 'automatic'
      and a.status = 'verified'
      and a.expires_at > now()
  ),
  scored as (
    select
      h.user_id,
      sum(round(10000 / greatest(coalesce(c.rarity_pct, 100), 1)))::bigint
        as score,
      count(*)::bigint as held_counties,
      count(*) filter (where coalesce(c.rarity_pct, 100) <= 10)::bigint
        as rare_counties
    from held h
    join public.counties c on c.id = h.county_id
    group by h.user_id
  ),
  ranked as (
    select
      scored.*,
      rank() over (order by scored.score desc, scored.held_counties desc, scored.user_id)
        as rank_position,
      count(*) over () as field_size
    from scored
  )
  select
    ranked.user_id,
    ranked.rank_position,
    ranked.score,
    ranked.held_counties,
    ranked.rare_counties,
    ranked.field_size,
    ranked.user_id = auth.uid() as is_current_user
  from ranked
  where ranked.rank_position <= greatest(p_limit, 1)
     or ranked.user_id = auth.uid()
  order by ranked.rank_position asc, ranked.user_id;
$$;

revoke execute on function public.kenya_season_leaderboard(integer, uuid) from public;
grant execute on function public.kenya_season_leaderboard(integer, uuid) to authenticated;

create or replace function public.close_leaderboard_season(p_season_id uuid)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_season public.leaderboard_seasons;
begin
  select * into v_season
  from public.leaderboard_seasons
  where id = p_season_id
  for update;

  if not found then
    raise exception 'close_leaderboard_season: season % not found', p_season_id;
  end if;

  if v_season.status = 'closed' then
    return;
  end if;

  insert into public.season_honours (
    season_id,
    county_id,
    user_id,
    segment,
    rank_position,
    field_size,
    visits,
    settled_at
  )
  with eligible_events as (
    select
      e.user_id,
      e.county_id,
      case
        when p.home_county_id = e.county_id then 'locals'
        else 'visitors'
      end as segment
    from public.county_visit_events e
    join public.profiles p on p.id = e.user_id
    join public.competitive_device_attestations a on a.user_id = e.user_id
    where e.entered_at >= v_season.starts_at
      and e.entered_at < v_season.ends_at
      and e.outcome = 'explored'
      and e.source = 'automatic'
      and p.show_on_leaderboards = true
      and p.location_mode = 'automatic'
      and a.status = 'verified'
      and a.expires_at > v_season.ends_at
  ),
  scored as (
    select
      eligible_events.county_id,
      eligible_events.user_id,
      eligible_events.segment,
      count(*) as visits
    from eligible_events
    group by
      eligible_events.county_id,
      eligible_events.user_id,
      eligible_events.segment
  ),
  ranked as (
    select
      scored.*,
      rank() over (
        partition by scored.county_id, scored.segment
        order by scored.visits desc, scored.user_id
      ) as rank_position,
      count(*) over (
        partition by scored.county_id, scored.segment
      ) as field_size
    from scored
  )
  select
    p_season_id,
    ranked.county_id,
    ranked.user_id,
    ranked.segment,
    ranked.rank_position::integer,
    ranked.field_size::integer,
    ranked.visits::integer,
    now()
  from ranked
  on conflict (season_id, county_id, segment, user_id) do update
    set rank_position = excluded.rank_position,
        field_size = excluded.field_size,
        visits = excluded.visits,
        settled_at = excluded.settled_at;

  update public.leaderboard_seasons
    set status = 'closed',
        closed_at = now()
    where id = p_season_id;
end;
$$;

revoke execute on function public.close_leaderboard_season(uuid) from public;
revoke execute on function public.close_leaderboard_season(uuid) from authenticated;
grant execute on function public.close_leaderboard_season(uuid) to service_role;

-- `county_depth_ranks()` now has the event history needed for doc 02's
-- distinct-month thresholds.
create or replace function public.county_depth_ranks()
returns table (county_id smallint, rank text)
language sql
stable
security definer
set search_path = public, extensions
as $$
  with explored_events as (
    select
      e.county_id,
      e.id,
      date_trunc('month', e.entered_at)::date as visit_month
    from public.county_visit_events e
    where e.user_id = auth.uid()
      and e.outcome = 'explored'
  ),
  counts as (
    select
      county_id,
      count(*) as explored_visits,
      count(distinct visit_month) as explored_months
    from explored_events
    group by county_id
  )
  select
    counts.county_id,
    case
      when explored_visits >= 6 and explored_months >= 5 then 'local_expert'
      when explored_visits >= 3 and explored_months >= 3 then 'regular'
      else 'visitor'
    end as rank
  from counts;
$$;

revoke execute on function public.county_depth_ranks() from public;
grant execute on function public.county_depth_ranks() to authenticated;
