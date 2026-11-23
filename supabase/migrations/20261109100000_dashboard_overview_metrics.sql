-- Overview metrics and leaderboard analysis for the admin dashboard.
-- Definitions (agreed 8 Nov 2026):
--   Real Trip: at least 1 km and 5 minutes of moving time.
--   Travelling: a county entry or a finished real Trip in the last 30 days.
--   Active: any meaningful action in the last 30 days (travel, planning,
--   contributing). Opening the app does not count.
--   Notable Trip: a real Trip that crosses 3+ counties, unlocks a new county,
--   covers 100 km+, has 3 h+ moving time, is the person's longest so far
--   (with an earlier real Trip to beat), or was recorded from a trip plan.
--   Trip score: 3 per new county + 1 per county crossed + 1 per 100 km.
-- Hidden dashboard accounts, automated test accounts and dev-seeded data are
-- left out. The team's own accounts count. Helpers are not callable by
-- clients; the two RPCs check for owner or admin.

-- People counted in every number.
create or replace function public.dashboard_metric_users()
returns uuid[]
language sql stable security definer set search_path = ''
as $$
  select coalesce(array_agg(u.user_id), '{}'::uuid[])
  from public.search_users_dashboard('') u
  where u.dashboard_visibility = 'visible' and not u.is_automated_test_account;
$$;

-- First time each person reached each county, and whether they explored it.
create or replace function public.dashboard_metric_coverage(p_users uuid[], p_to timestamptz)
returns table (user_id uuid, county_id smallint, first_at timestamptz, explored boolean)
language sql stable security definer set search_path = ''
as $$
  with evidence as (
    select e.user_id, e.county_id, e.entered_at as at, e.outcome = 'explored' as explored
    from public.county_visit_events e
    where e.user_id = any(p_users) and e.source <> 'dev_seed'
      and e.outcome in ('explored', 'passed_through') and e.entered_at < p_to
    union all
    select v.user_id, v.county_id, v.entered_at, v.state = 'explored'
    from public.county_visits v
    where v.user_id = any(p_users) and v.state in ('explored', 'passed_through') and v.entered_at < p_to
      and not exists (
        select 1 from public.county_visit_events e
        where e.user_id = v.user_id and e.county_id = v.county_id
      )
  )
  select e.user_id, e.county_id, min(e.at), bool_or(e.explored)
  from evidence e
  group by e.user_id, e.county_id;
$$;

-- Every real Trip finished before p_to, with its notable flags and score.
create or replace function public.dashboard_metric_trips(p_users uuid[], p_to timestamptz)
returns table (
  journey_id uuid, user_id uuid, title text, started_at timestamptz, ended_at timestamptz,
  distance_m numeric, moving_seconds numeric, counties_crossed integer, new_counties integer,
  from_plan boolean, has_break boolean, personal_best boolean, notable boolean, score integer
)
language sql stable security definer set search_path = ''
as $$
  with coverage as (
    select * from public.dashboard_metric_coverage(p_users, p_to)
  ),
  real as (
    select j.id, j.user_id, j.title, j.started_at, j.ended_at, j.distance_m,
      coalesce(j.moving_seconds, extract(epoch from j.ended_at - j.started_at)) as moving_seconds,
      max(j.distance_m) over (
        partition by j.user_id order by j.ended_at, j.id
        rows between unbounded preceding and 1 preceding
      ) as previous_best
    from public.journeys j
    where j.user_id = any(p_users) and j.ended_at < p_to
      and j.distance_m >= 1000
      and coalesce(j.moving_seconds, extract(epoch from j.ended_at - j.started_at)) >= 300
  ),
  facts as (
    select r.*,
      (select count(*)::integer from public.journey_counties jc where jc.journey_id = r.id) as crossed,
      (select count(*)::integer from public.journey_counties jc
         join coverage c on c.user_id = r.user_id and c.county_id = jc.county_id
        where jc.journey_id = r.id
          and c.first_at >= r.started_at - interval '5 minutes'
          and c.first_at <= r.ended_at + interval '1 hour') as unlocked,
      exists (select 1 from public.trip_plan_day_recordings d where d.journey_id = r.id) as planned,
      exists (select 1 from public.journey_points p where p.journey_id = r.id and p.segment_number > 0) as broken
    from real r
  )
  select f.id, f.user_id, f.title, f.started_at, f.ended_at, f.distance_m, f.moving_seconds,
    f.crossed, f.unlocked, f.planned, f.broken,
    coalesce(f.distance_m > f.previous_best, false),
    f.crossed >= 3 or f.unlocked >= 1 or f.distance_m >= 100000 or f.moving_seconds >= 10800
      or coalesce(f.distance_m > f.previous_best, false) or f.planned,
    3 * f.unlocked + f.crossed + floor(f.distance_m / 100000)::integer
  from facts f;
$$;

-- Dated meaningful actions. kind = 'travel' or 'other'.
create or replace function public.dashboard_metric_actions(p_users uuid[], p_to timestamptz)
returns table (user_id uuid, at timestamptz, kind text)
language sql stable security definer set search_path = ''
as $$
  select e.user_id, e.entered_at, 'travel' from public.county_visit_events e
   where e.user_id = any(p_users) and e.source <> 'dev_seed' and e.entered_at < p_to
  union all
  select t.user_id, t.ended_at, 'travel' from public.dashboard_metric_trips(p_users, p_to) t
  union all
  select p.owner_id, greatest(p.created_at, coalesce(p.updated_at, p.created_at)), 'other'
    from public.trip_plans p where p.owner_id = any(p_users) and p.created_at < p_to
  union all
  select s.added_by, s.created_at, 'other' from public.trip_plan_stops s
   where s.added_by = any(p_users) and s.created_at < p_to
  union all
  select s.added_by, s.created_at, 'other' from public.trip_plan_places s
   where s.added_by = any(p_users) and s.created_at < p_to
  union all
  select s.user_id, greatest(s.created_at, s.updated_at), 'other' from public.saved_trips s
   where s.user_id = any(p_users) and s.created_at < p_to
  union all
  select w.user_id, w.saved_at, 'other' from public.wishlist_items w
   where w.user_id = any(p_users) and w.saved_at < p_to
  union all
  select s.user_id, s.created_at, 'other' from public.place_photo_submissions s
   where s.user_id = any(p_users) and s.created_at < p_to
  union all
  select c.user_id, c.checked_in_at, 'other' from public.place_check_ins c
   where c.user_id = any(p_users) and c.checked_in_at < p_to
  union all
  select pub.owner_id, r.submitted_at, 'other'
    from public.public_trip_revisions r
    join public.public_trip_publications pub on pub.id = r.publication_id
   where pub.owner_id = any(p_users) and r.submitted_at is not null and r.submitted_at < p_to;
$$;

-- Each person's state right now. Order: Travelling, Planning only, New,
-- Never started, At risk, Dormant, Gone.
create or replace function public.dashboard_metric_states(p_users uuid[])
returns table (user_id uuid, state text, last_action_at timestamptz, created_at timestamptz)
language sql stable security definer set search_path = ''
as $$
  with acts as (
    select a.user_id, max(a.at) as last_any,
      max(a.at) filter (where a.kind = 'travel') as last_travel
    from public.dashboard_metric_actions(p_users, now()) a
    group by a.user_id
  )
  select p.id,
    case
      when a.last_travel >= now() - interval '30 days' then 'travelling'
      when a.last_any >= now() - interval '30 days' then 'planning'
      when p.created_at >= now() - interval '14 days' then 'new'
      when a.last_travel is null then 'never_started'
      when a.last_any >= now() - interval '60 days' then 'at_risk'
      when a.last_any >= now() - interval '120 days' then 'dormant'
      else 'gone'
    end,
    a.last_any,
    p.created_at
  from public.profiles p
  left join acts a on a.user_id = p.id
  where p.id = any(p_users);
$$;

-- Public name used in staff views; null for people who opted out.
create or replace function public.dashboard_metric_name(p_user uuid)
returns text
language sql stable security definer set search_path = ''
as $$
  select case when coalesce(p.show_on_leaderboards, true)
    then coalesce(nullif(q.handle, ''), nullif(q.display_name, ''), 'Traveller') end
  from public.profiles p
  left join public.quest_public_profiles q on q.user_id = p.id
  where p.id = p_user;
$$;

revoke all on function public.dashboard_metric_users() from public, anon, authenticated;
revoke all on function public.dashboard_metric_coverage(uuid[], timestamptz) from public, anon, authenticated;
revoke all on function public.dashboard_metric_trips(uuid[], timestamptz) from public, anon, authenticated;
revoke all on function public.dashboard_metric_actions(uuid[], timestamptz) from public, anon, authenticated;
revoke all on function public.dashboard_metric_states(uuid[]) from public, anon, authenticated;
revoke all on function public.dashboard_metric_name(uuid) from public, anon, authenticated;

create or replace function public.dashboard_overview_metrics(
  p_start timestamptz default null,
  p_end timestamptz default null
) returns jsonb
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_end timestamptz := least(coalesce(p_end, now()), now());
  v_start timestamptz;
  v_prev timestamptz;
  v_users uuid[];
  v_first_travel timestamptz;
  v_result jsonb;
begin
  if coalesce(public.current_admin_role() in ('owner', 'admin'), false) is not true then
    raise exception 'Owner or admin access required' using errcode = '42501';
  end if;
  v_users := public.dashboard_metric_users();
  select coalesce(p_start, least(min(p.created_at), v_end - interval '1 second'))
    into v_start from public.profiles p where p.id = any(v_users);
  v_start := coalesce(v_start, v_end - interval '30 days');
  if not isfinite(v_start) or not isfinite(v_end) or v_start >= v_end then
    raise exception 'Invalid reporting dates' using errcode = '22023';
  end if;
  v_prev := v_start - (v_end - v_start);

  create temp table if not exists dm_trips on commit drop as
    select * from public.dashboard_metric_trips(v_users, v_end) limit 0;
  truncate dm_trips;
  insert into dm_trips select * from public.dashboard_metric_trips(v_users, v_end);

  create temp table if not exists dm_actions on commit drop as
    select * from public.dashboard_metric_actions(v_users, v_end) limit 0;
  truncate dm_actions;
  insert into dm_actions select * from public.dashboard_metric_actions(v_users, v_end);

  create temp table if not exists dm_coverage on commit drop as
    select * from public.dashboard_metric_coverage(v_users, v_end) limit 0;
  truncate dm_coverage;
  insert into dm_coverage select * from public.dashboard_metric_coverage(v_users, v_end);

  create temp table if not exists dm_states on commit drop as
    select * from public.dashboard_metric_states(v_users) limit 0;
  truncate dm_states;
  insert into dm_states select * from public.dashboard_metric_states(v_users);

  select min(a.at) into v_first_travel from dm_actions a where a.kind = 'travel';

  with
  travel as (select a.user_id, a.at from dm_actions a where a.kind = 'travel'),
  cur as (select distinct t.user_id from travel t where t.at >= v_end - interval '30 days'),
  prev30 as (select distinct t.user_id from travel t where t.at >= v_end - interval '60 days' and t.at < v_end - interval '30 days'),
  prev60 as (select distinct t.user_id from travel t where t.at >= v_end - interval '90 days' and t.at < v_end - interval '60 days'),
  weeks as (
    select w, v_end - (w * interval '7 days') as week_end from generate_series(7, 0, -1) w
  ),
  period_trips as (select * from dm_trips t where t.ended_at >= v_start),
  cohort as (
    select p.id, p.created_at, p.home_county_id from public.profiles p
    where p.id = any(v_users) and p.created_at >= v_start and p.created_at < v_end
  ),
  hit as (
    select u.user_id, min(u.period_month) as first_month
    from public.journey_trial_usage u
    where u.user_id = any(v_users) and u.trips_used >= 3
      and u.period_month >= date_trunc('month', v_start)::date and u.period_month < v_end
    group by u.user_id
  ),
  latest as (
    select distinct on (r.platform) r.platform, r.version from public.app_version_releases r
    where r.status = 'live' and r.channel = 'production'
    order by r.platform, r.major desc, r.minor desc, r.patch desc, r.build desc
  ),
  phones as (
    select distinct on (d.user_id) d.user_id, d.platform,
      nullif(split_part(coalesce(d.app_version, ''), '+', 1), '') as version
    from public.push_devices d
    where d.user_id = any(v_users) and d.last_seen_at >= now() - interval '30 days'
    order by d.user_id, d.last_seen_at desc, d.id
  ),
  board as (
    select c.user_id, count(*) as total, count(*) filter (where c.explored) as explored
    from dm_coverage c join public.profiles p on p.id = c.user_id
    where coalesce(p.show_on_leaderboards, true)
    group by c.user_id having count(*) > 3
  ),
  named_trips as (
    select t.*, public.dashboard_metric_name(t.user_id) as name from period_trips t
  )
  select jsonb_build_object(
    'generated_at', now(),
    'period', jsonb_build_object('start', v_start, 'end', v_end, 'comparable', p_start is not null),
    'north_star', jsonb_build_object(
      'current', (select count(*) from cur),
      'previous', (select count(*) from prev30),
      'previous_comparable', v_first_travel is not null and v_first_travel <= v_end - interval '60 days',
      'weeks_of_data', case when v_first_travel is null then 0
        else floor(extract(epoch from v_end - v_first_travel) / 604800)::integer end,
      'weekly', (select coalesce(jsonb_agg(jsonb_build_object('week_end', wk.week_end,
          'value', (select count(distinct t.user_id) from travel t
                    where t.at >= wk.week_end - interval '30 days' and t.at < wk.week_end))
        order by wk.w desc), '[]'::jsonb) from weeks wk)
    ),
    'states', (select jsonb_build_object(
      'total', count(*),
      'travelling', count(*) filter (where s.state = 'travelling'),
      'planning', count(*) filter (where s.state = 'planning'),
      'new', count(*) filter (where s.state = 'new'),
      'never_started', count(*) filter (where s.state = 'never_started'),
      'at_risk', count(*) filter (where s.state = 'at_risk'),
      'dormant', count(*) filter (where s.state = 'dormant'),
      'gone', count(*) filter (where s.state = 'gone')
    ) from dm_states s),
    'new_counties', jsonb_build_object(
      'current', (select count(*) from dm_coverage c where c.first_at >= v_start),
      'previous', (select count(*) from dm_coverage c where c.first_at >= v_prev and c.first_at < v_start)
    ),
    'trips', jsonb_build_object(
      'real', (select count(*) from period_trips),
      'notable', (select count(*) from period_trips t where t.notable),
      'notable_previous', (select count(*) from dm_trips t where t.notable and t.ended_at >= v_prev and t.ended_at < v_start),
      'with_breaks', (select count(*) from period_trips t where t.has_break),
      'short_recordings', (select count(*) from public.journeys j
        where j.user_id = any(v_users) and j.ended_at >= v_start and j.ended_at < v_end
          and not exists (select 1 from dm_trips t where t.journey_id = j.id))
    ),
    'came_back', jsonb_build_object(
      'comparable', v_first_travel is not null and v_first_travel <= v_end - interval '60 days',
      'base', (select count(*) from prev30),
      'returned', (select count(*) from prev30 p join cur c using (user_id)),
      'previous_base', (select count(*) from prev60),
      'previous_returned', (select count(*) from prev60 p join prev30 c using (user_id)),
      'previous_comparable', v_first_travel is not null and v_first_travel <= v_end - interval '90 days'
    ),
    'new_people', (select jsonb_build_object(
      'signed_up', count(*),
      'set_home_county', count(*) filter (where c.home_county_id is not null),
      'first_county', count(*) filter (where exists (select 1 from dm_coverage cv where cv.user_id = c.id)),
      'first_trip', count(*) filter (where exists (select 1 from dm_trips t where t.user_id = c.id)),
      'activation_eligible', count(*) filter (where c.created_at <= v_end - interval '7 days'),
      'activated_7d', count(*) filter (where c.created_at <= v_end - interval '7 days' and exists (
        select 1 from travel t where t.user_id = c.id
          and t.at >= c.created_at and t.at < c.created_at + interval '7 days'))
    ) from cohort c),
    'records', jsonb_build_object(
      'longest', (select to_jsonb(x) from (
        select t.journey_id, t.user_id, t.name, t.title, t.ended_at,
          round(t.distance_m / 1000.0, 1) as km, t.counties_crossed, round(t.moving_seconds / 60.0) as moving_minutes
        from named_trips t order by t.distance_m desc, t.ended_at limit 1) x),
      'most_counties', (select to_jsonb(x) from (
        select t.journey_id, t.user_id, t.name, t.title, t.ended_at, t.counties_crossed,
          round(t.distance_m / 1000.0, 1) as km
        from named_trips t where t.counties_crossed > 0
        order by t.counties_crossed desc, t.distance_m desc limit 1) x),
      'most_new', (select to_jsonb(x) from (
        select t.journey_id, t.user_id, t.name, t.title, t.ended_at, t.new_counties, t.score
        from named_trips t where t.new_counties > 0
        order by t.new_counties desc, t.score desc limit 1) x),
      'top', (select coalesce(jsonb_agg(to_jsonb(x) order by x.score desc, x.km desc), '[]'::jsonb) from (
        select t.journey_id, t.user_id, t.name, t.title, t.ended_at, t.score,
          round(t.distance_m / 1000.0, 1) as km, t.counties_crossed, t.new_counties
        from named_trips t where t.notable
        order by t.score desc, t.distance_m desc limit 5) x)
    ),
    'pro', jsonb_build_object(
      'members_now', (select count(distinct e.user_id) from public.pro_entitlement_periods e
        where e.user_id = any(v_users) and e.starts_at <= now() and (e.ends_at is null or e.ends_at > now())),
      'hit_limit', (select count(*) from hit),
      'upgraded', (select count(*) from hit h where exists (
        select 1 from public.pro_entitlement_periods e
        where e.user_id = h.user_id and e.source <> 'admin'
          and e.starts_at >= h.first_month and e.starts_at < v_end))
    ),
    'feedback', (select jsonb_build_object(
      'open', count(*) filter (where f.status in ('received', 'triaged', 'investigating', 'planned')),
      'open_blocking', count(*) filter (where f.status in ('received', 'triaged', 'investigating', 'planned') and f.severity = 'blocking'),
      'waiting_reply', count(*) filter (where f.status in ('received', 'triaged', 'investigating', 'planned') and f.responded_at is null),
      'median_reply_hours', round((percentile_cont(0.5) within group (order by extract(epoch from f.responded_at - f.created_at) / 3600.0)
        filter (where f.responded_at is not null and f.created_at >= now() - interval '30 days'))::numeric, 1)
    ) from public.feedback_reports f),
    'versions', (select jsonb_build_object(
      'known_version', count(*) filter (where p.version is not null and l.version is not null),
      'on_latest', count(*) filter (where p.version = l.version),
      'latest', (select coalesce(jsonb_object_agg(lt.platform, lt.version), '{}'::jsonb) from latest lt)
    ) from phones p left join latest l on l.platform = p.platform),
    'leaderboard_preview', (select coalesce(jsonb_agg(to_jsonb(x) order by x.rank), '[]'::jsonb) from (
      select row_number() over (order by b.total desc, b.explored desc, b.user_id) as rank,
        b.user_id, public.dashboard_metric_name(b.user_id) as name,
        b.total, b.explored, b.total - b.explored as passed_through
      from board b order by b.total desc, b.explored desc, b.user_id limit 5) x)
  ) into v_result;
  return v_result;
end;
$$;

revoke all on function public.dashboard_overview_metrics(timestamptz, timestamptz) from public, anon;
grant execute on function public.dashboard_overview_metrics(timestamptz, timestamptz) to authenticated;

-- People in one state, newest action first, for the "See who" list.
create or replace function public.dashboard_people_in_state(p_state text)
returns table (user_id uuid, name text, last_action_at timestamptz, signed_up_at timestamptz)
language plpgsql stable security definer set search_path = ''
as $$
begin
  if coalesce(public.current_admin_role() in ('owner', 'admin'), false) is not true then
    raise exception 'Owner or admin access required' using errcode = '42501';
  end if;
  if p_state not in ('travelling', 'planning', 'new', 'never_started', 'at_risk', 'dormant', 'gone') then
    raise exception 'Unknown state' using errcode = '22023';
  end if;
  return query
  select s.user_id,
    coalesce(nullif(q.handle, ''), nullif(q.display_name, ''), 'Traveller'),
    s.last_action_at, s.created_at
  from public.dashboard_metric_states(public.dashboard_metric_users()) s
  left join public.quest_public_profiles q on q.user_id = s.user_id
  where s.state = p_state
  order by s.last_action_at desc nulls last, s.created_at desc
  limit 500;
end;
$$;

revoke all on function public.dashboard_people_in_state(text) from public, anon;
grant execute on function public.dashboard_people_in_state(text) to authenticated;

-- Leaderboard analysis: how people compare. Names only for people who allow
-- leaderboards; aggregate panels count everyone; groups under 5 are hidden.
create or replace function public.dashboard_leaderboard_analysis(
  p_start timestamptz default null,
  p_end timestamptz default null
) returns jsonb
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_end timestamptz := least(coalesce(p_end, now()), now());
  v_start timestamptz;
  v_users uuid[];
  v_result jsonb;
begin
  if coalesce(public.current_admin_role() in ('owner', 'admin'), false) is not true then
    raise exception 'Owner or admin access required' using errcode = '42501';
  end if;
  v_users := public.dashboard_metric_users();
  select coalesce(p_start, least(min(p.created_at), v_end - interval '1 second'))
    into v_start from public.profiles p where p.id = any(v_users);
  v_start := coalesce(v_start, v_end - interval '30 days');
  if not isfinite(v_start) or not isfinite(v_end) or v_start >= v_end then
    raise exception 'Invalid reporting dates' using errcode = '22023';
  end if;

  create temp table if not exists dl_trips on commit drop as
    select * from public.dashboard_metric_trips(v_users, v_end) limit 0;
  truncate dl_trips;
  insert into dl_trips select * from public.dashboard_metric_trips(v_users, v_end);

  create temp table if not exists dl_coverage on commit drop as
    select * from public.dashboard_metric_coverage(v_users, v_end) limit 0;
  truncate dl_coverage;
  insert into dl_coverage select * from public.dashboard_metric_coverage(v_users, v_end);

  create temp table if not exists dl_travel on commit drop as
    select a.user_id, a.at from public.dashboard_metric_actions(v_users, v_end) a limit 0;
  truncate dl_travel;
  insert into dl_travel select a.user_id, a.at from public.dashboard_metric_actions(v_users, v_end) a where a.kind = 'travel';

  create temp table if not exists dl_people (
    user_id uuid primary key, shown boolean, name text, home_county text, pro boolean, state text,
    total integer, explored integer, new_in_period integer, real_trips integer, notable_trips integer,
    best_score integer, total_km numeric, longest_km numeric, travel_days integer, streak_months integer
  ) on commit drop;
  truncate dl_people;

  insert into dl_people
  with months as (
    select distinct t.user_id, date_trunc('month', t.ended_at at time zone 'Africa/Nairobi')::date as m
    from dl_trips t
  ),
  anchored as (
    -- A streak counts back from this month, or last month if this one is still empty.
    select m.user_id, m.m,
      (extract(year from age(date_trunc('month', v_end at time zone 'Africa/Nairobi')::date, m.m)) * 12
        + extract(month from age(date_trunc('month', v_end at time zone 'Africa/Nairobi')::date, m.m)))::integer as back,
      row_number() over (partition by m.user_id order by m.m desc) - 1 as idx
    from months m
  ),
  streaks as (
    select a.user_id, count(*)::integer as months
    from anchored a
    where a.back - a.idx = (select min(b.back) from anchored b where b.user_id = a.user_id)
      and (select min(b.back) from anchored b where b.user_id = a.user_id) <= 1
    group by a.user_id
  )
  select p.id,
    coalesce(p.show_on_leaderboards, true),
    public.dashboard_metric_name(p.id),
    c.name,
    exists (select 1 from public.pro_entitlement_periods e
      where e.user_id = p.id and e.starts_at <= now() and (e.ends_at is null or e.ends_at > now())),
    s.state,
    (select count(*)::integer from dl_coverage cv where cv.user_id = p.id),
    (select count(*)::integer from dl_coverage cv where cv.user_id = p.id and cv.explored),
    (select count(*)::integer from dl_coverage cv where cv.user_id = p.id and cv.first_at >= v_start),
    (select count(*)::integer from dl_trips t where t.user_id = p.id and t.ended_at >= v_start),
    (select count(*)::integer from dl_trips t where t.user_id = p.id and t.ended_at >= v_start and t.notable),
    (select max(t.score) from dl_trips t where t.user_id = p.id and t.ended_at >= v_start),
    (select round(coalesce(sum(t.distance_m), 0) / 1000.0, 1) from dl_trips t where t.user_id = p.id and t.ended_at >= v_start),
    (select round(max(t.distance_m) / 1000.0, 1) from dl_trips t where t.user_id = p.id and t.ended_at >= v_start),
    (select count(distinct (tr.at at time zone 'Africa/Nairobi')::date)::integer from dl_travel tr
      where tr.user_id = p.id and tr.at >= v_start),
    coalesce((select st.months from streaks st where st.user_id = p.id), 0)
  from public.profiles p
  left join public.counties c on c.id = p.home_county_id
  left join public.dashboard_metric_states(v_users) s on s.user_id = p.id
  where p.id = any(v_users);

  with
  board as (
    select row_number() over (order by d.total desc, d.explored desc, d.user_id) as rank, d.*
    from dl_people d where d.shown and d.total > 3
  ),
  by_notable as (
    select b.*, lead(b.user_id) over (order by b.notable_trips desc, b.rank) as next_id
    from board b where b.notable_trips > 0
  ),
  races as (
    select a.name as a_name, b.name as b_name, a.total as a_value, b.total as b_value,
      'counties' as measure, a.rank as sort_key
    from board a join board b on b.rank = a.rank + 1
    where a.total - b.total <= 1
    union all
    select a.name, b.name, a.notable_trips, b.notable_trips, 'notable_trips', 1000 + a.rank
    from by_notable a join board b on b.user_id = a.next_id
    where a.notable_trips - b.notable_trips <= 1
  ),
  holders as (
    select cv.county_id, count(*) as people from dl_coverage cv group by cv.county_id
  ),
  board_cov as (
    select cv.user_id, cv.county_id from dl_coverage cv join board b on b.user_id = cv.user_id
  ),
  pairs as (
    select x.user_id as a, y.user_id as b, count(*) as shared
    from board_cov x join board_cov y on y.county_id = x.county_id and y.user_id > x.user_id
    group by x.user_id, y.user_id
  ),
  homes as (
    select d.home_county, count(*) as people,
      (select t.name from dl_people t where t.home_county = d.home_county and t.shown and t.total > 0
        order by t.total desc, t.explored desc, t.user_id limit 1) as top_name
    from dl_people d where d.home_county is not null group by d.home_county
  ),
  prev30 as (select distinct t.user_id from dl_travel t where t.at >= v_end - interval '60 days' and t.at < v_end - interval '30 days'),
  cur as (select distinct t.user_id from dl_travel t where t.at >= v_end - interval '30 days'),
  back as (
    select (b.user_id is not null) as leader, count(*) as base, count(c.user_id) as returned
    from prev30 p
    left join board b on b.user_id = p.user_id
    left join cur c on c.user_id = p.user_id
    group by (b.user_id is not null)
  )
  select jsonb_build_object(
    'generated_at', now(),
    'period', jsonb_build_object('start', v_start, 'end', v_end, 'comparable', p_start is not null),
    'people', (select count(*) from dl_people),
    'spread', (select jsonb_build_object(
      'none', count(*) filter (where d.total = 0),
      'one_to_three', count(*) filter (where d.total between 1 and 3),
      'four_to_nine', count(*) filter (where d.total between 4 and 9),
      'ten_to_nineteen', count(*) filter (where d.total between 10 and 19),
      'twenty_to_46', count(*) filter (where d.total between 20 and 46),
      'all_47', count(*) filter (where d.total >= 47)
    ) from dl_people d),
    'close_races', (select coalesce(jsonb_agg(to_jsonb(r) order by r.sort_key), '[]'::jsonb) from (
      select * from races order by sort_key limit 10) r),
    'home_groups', (select coalesce(jsonb_agg(jsonb_build_object(
        'county', h.home_county,
        'people', case when h.people >= 5 then h.people end,
        'top_name', case when h.people >= 5 then h.top_name end
      ) order by h.people desc, h.home_county), '[]'::jsonb)
      from (select * from homes order by people desc, home_county limit 10) h),
    'shared', jsonb_build_object(
      'most_held', (select coalesce(jsonb_agg(jsonb_build_object('county', c.name, 'people', h.people)
          order by h.people desc, c.name), '[]'::jsonb)
        from (select * from holders order by people desc, county_id limit 5) h
        join public.counties c on c.id = h.county_id),
      'rarest', (select coalesce(jsonb_agg(jsonb_build_object('county', c.name, 'people', h.people)
          order by h.people, c.name), '[]'::jsonb)
        from (select * from holders order by people, county_id limit 5) h
        join public.counties c on c.id = h.county_id),
      'nobody_yet', (select count(*) from public.counties c where not exists (select 1 from holders h where h.county_id = c.id)),
      'pairs', (select coalesce(jsonb_agg(jsonb_build_object(
          'a_name', public.dashboard_metric_name(pr.a), 'b_name', public.dashboard_metric_name(pr.b), 'shared', pr.shared)
          order by pr.shared desc), '[]'::jsonb)
        from (select * from pairs order by shared desc, a, b limit 5) pr)
    ),
    'leaders_vs_everyone', jsonb_build_object(
      'comparable', exists (select 1 from dl_travel t where t.at < v_end - interval '60 days'),
      'leaders_base', coalesce((select base from back where leader), 0),
      'leaders_returned', coalesce((select returned from back where leader), 0),
      'others_base', coalesce((select base from back where not leader), 0),
      'others_returned', coalesce((select returned from back where not leader), 0)
    ),
    'table', (select coalesce(jsonb_agg(jsonb_build_object(
        'rank', b.rank, 'user_id', b.user_id, 'name', b.name, 'home_county', b.home_county,
        'pro', b.pro, 'state', b.state, 'total', b.total, 'explored', b.explored,
        'passed_through', b.total - b.explored, 'new_in_period', b.new_in_period,
        'real_trips', b.real_trips, 'notable_trips', b.notable_trips, 'best_score', b.best_score,
        'total_km', b.total_km, 'longest_km', b.longest_km, 'travel_days', b.travel_days,
        'streak_months', b.streak_months
      ) order by b.rank), '[]'::jsonb)
      from (select * from board order by rank limit 200) b),
    'eligible', (select count(*) from board)
  ) into v_result;
  return v_result;
end;
$$;

revoke all on function public.dashboard_leaderboard_analysis(timestamptz, timestamptz) from public, anon;
grant execute on function public.dashboard_leaderboard_analysis(timestamptz, timestamptz) to authenticated;
