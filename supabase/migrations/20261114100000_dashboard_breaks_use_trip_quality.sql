-- Recording reliability: count only real recording problems as breaks.
--
-- Until now a Trip "had a break" when any route point sat in a later segment,
-- which also counted pauses the person made and, now, confirmed GPS jumps.
-- Trips with a journey_quality summary (sent by the updated app) use it
-- instead; older Trips keep the previous rule, so past weeks do not move.
-- Replaces dashboard_metric_trips only; the overview and growth series read
-- has_break from it.

-- Every real Trip finished before p_to, with its notable flags and score.
-- has_break: a Trip recorded by an app that sends a quality summary has a
-- break only if the app lost recording (a system pause, or a gap of 2 minutes
-- or more); pauses the person made and far jumps do not count. Older Trips
-- keep the earlier rule: any route point after a segment change.
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
      coalesce(
        (select coalesce((q.summary ->> 'gaps')::int, 0) > 0
             or coalesce((q.summary #>> '{pauses,location_lost}')::int, 0)
              + coalesce((q.summary #>> '{pauses,app_restarted}')::int, 0)
              + coalesce((q.summary #>> '{pauses,start_failed}')::int, 0)
              + coalesce((q.summary #>> '{pauses,account_changed}')::int, 0) > 0
           from public.journey_quality q where q.journey_id = r.id),
        exists (select 1 from public.journey_points p where p.journey_id = r.id and p.segment_number > 0)
      ) as broken
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
