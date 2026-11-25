-- Usage numbers for the dashboard home: activity, Trips, county entries,
-- app versions, new-user progress, feedback and Pro. Totals only, never
-- per-person rows, and owner/admin only.
create or replace function public.dashboard_usage_stats()
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_week timestamptz := now() - interval '7 days';
  v_prev timestamptz := now() - interval '14 days';
  v_month_ago timestamptz := now() - interval '30 days';
  v_period date := date_trunc('month', timezone('UTC', now()))::date;
  v_active jsonb;
  v_trips jsonb;
  v_counties jsonb;
  v_versions jsonb;
  v_new_users jsonb;
  v_feedback jsonb;
  v_pro jsonb;
begin
  if coalesce(public.current_admin_role() in ('owner', 'admin'), false) is not true then
    raise exception 'Owner or admin access required' using errcode = '42501';
  end if;

  -- 1. Active: recorded a Trip, entered a county, or the app checked in.
  -- Phones only keep their latest check-in, so the earlier week undercounts
  -- people who were active then but have not opened the app since.
  with activity as (
    select user_id, started_at as at from public.journeys where started_at >= v_prev
    union all
    select user_id, entered_at from public.county_visit_events
      where entered_at >= v_prev and source <> 'dev_seed'
    union all
    select user_id, last_seen_at from public.push_devices where last_seen_at >= v_prev
  )
  select jsonb_build_object(
    'this_week', count(distinct user_id) filter (where at >= v_week),
    'previous_week', count(distinct user_id) filter (where at < v_week),
    'last_30_days', (
      select count(distinct a.user_id) from (
        select user_id from public.journeys where started_at >= v_month_ago
        union all
        select user_id from public.county_visit_events
          where entered_at >= v_month_ago and source <> 'dev_seed'
        union all
        select user_id from public.push_devices where last_seen_at >= v_month_ago
      ) a
    )
  ) into v_active
  from activity;

  -- 2 and 3. Finished Trips, and how many have a break in the route
  -- (a pause, or 2+ minutes without location, starts a new segment).
  with trips as (
    select j.id,
           j.ended_at,
           j.distance_m,
           extract(epoch from j.ended_at - j.started_at) as seconds,
           exists (
             select 1 from public.journey_points p
             where p.journey_id = j.id and p.segment_number > 0
           ) as has_break
    from public.journeys j
    where j.ended_at >= v_prev
  )
  select jsonb_build_object(
    'this_week', count(*) filter (where ended_at >= v_week),
    'previous_week', count(*) filter (where ended_at < v_week),
    'people_this_week', (
      select count(distinct user_id) from public.journeys where ended_at >= v_week
    ),
    'distance_km_this_week',
      round(coalesce(sum(distance_m) filter (where ended_at >= v_week), 0) / 1000.0, 1),
    'median_minutes_this_week',
      round((percentile_cont(0.5) within group (order by seconds)
        filter (where ended_at >= v_week) / 60.0)::numeric, 0),
    'with_breaks_this_week', count(*) filter (where ended_at >= v_week and has_break),
    'with_breaks_previous_week', count(*) filter (where ended_at < v_week and has_break)
  ) into v_trips
  from trips;

  -- 4. County entries recorded on the server (all are confirmed by then).
  select jsonb_build_object(
    'this_week', count(*) filter (where entered_at >= v_week),
    'previous_week', count(*) filter (where entered_at < v_week),
    'people_this_week', count(distinct user_id) filter (where entered_at >= v_week),
    'explored_this_week',
      count(*) filter (where entered_at >= v_week and outcome = 'explored'),
    'automatic_this_week',
      count(*) filter (where entered_at >= v_week and source = 'automatic')
  ) into v_counties
  from public.county_visit_events
  where entered_at >= v_prev and source <> 'dev_seed';

  -- 5. People on the newest live version for their platform, from each
  -- person's most recently seen phone in the last 30 days.
  with latest as (
    select distinct on (platform) platform, version
    from public.app_version_releases
    where status = 'live' and channel <> 'development'
    order by platform, major desc, minor desc, patch desc, build desc
  ),
  phones as (
    select distinct on (d.user_id) d.user_id, d.platform,
           nullif(split_part(coalesce(d.app_version, ''), '+', 1), '') as version
    from public.push_devices d
    where d.last_seen_at >= v_month_ago
    order by d.user_id, d.last_seen_at desc
  )
  select jsonb_build_object(
    'people', count(*),
    -- Only phones on a platform with a live release can be compared.
    'known_version', count(*) filter (where p.version is not null and l.version is not null),
    'on_latest', count(*) filter (where p.version is not null and p.version = l.version),
    'latest', (
      select coalesce(jsonb_object_agg(platform, version), '{}'::jsonb) from latest
    )
  ) into v_versions
  from phones p
  left join latest l on l.platform = p.platform;

  -- 6. New people in the last 30 days, and how far each got.
  select jsonb_build_object(
    'signed_up', count(*),
    'set_home_county', count(*) filter (where pr.home_county_id is not null),
    'first_county', count(*) filter (where exists (
      select 1 from public.county_visit_events e
      where e.user_id = pr.id and e.source <> 'dev_seed'
    )),
    'first_trip', count(*) filter (where exists (
      select 1 from public.journeys j where j.user_id = pr.id
    ))
  ) into v_new_users
  from public.profiles pr
  where pr.created_at >= v_month_ago;

  -- 7. Feedback still open, and how fast the team replies.
  select jsonb_build_object(
    'open', count(*) filter (where status in ('received', 'triaged', 'investigating', 'planned')),
    'open_blocking', count(*) filter (
      where status in ('received', 'triaged', 'investigating', 'planned') and severity = 'blocking'
    ),
    'waiting_reply', count(*) filter (
      where status in ('received', 'triaged', 'investigating', 'planned') and responded_at is null
    ),
    'median_reply_hours_30_days', round((
      percentile_cont(0.5) within group (order by extract(epoch from responded_at - created_at))
        filter (where created_at >= v_month_ago and responded_at is not null) / 3600.0
    )::numeric, 1)
  ) into v_feedback
  from public.feedback_reports;

  -- 8. Pro now, and free Trips used this month (limit 3).
  select jsonb_build_object(
    'pro_now', (
      select count(distinct user_id) from public.pro_entitlement_periods
      where starts_at <= now() and (ends_at is null or ends_at > now())
    ),
    'pro_new_this_week', (
      select count(distinct user_id) from public.pro_entitlement_periods
      where starts_at >= v_week and starts_at <= now()
    ),
    'trial_users_this_month', count(*) filter (where trips_used > 0),
    'trial_at_limit_this_month', count(*) filter (where trips_used >= 3)
  ) into v_pro
  from public.journey_trial_usage
  where period_month = v_period;

  return jsonb_build_object(
    'generated_at', now(),
    'active', v_active,
    'trips', v_trips,
    'counties', v_counties,
    'versions', v_versions,
    'new_users', v_new_users,
    'feedback', v_feedback,
    'pro', v_pro
  );
end;
$$;

revoke all on function public.dashboard_usage_stats() from public, anon;
grant execute on function public.dashboard_usage_stats() to authenticated;
