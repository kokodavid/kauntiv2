set search_path = extensions, public;

-- Average speed on a trip is distance / MOVING time, so a stop at a market,
-- a long lunch or a traffic standstill doesn't drag it down.
--
-- Moving time is worked out on the server from the saved route points, once,
-- and stored on the journey (the app reads it with the rest of the trip).
-- Between two consecutive points of the same recording segment, the time
-- counts as moving when the phone covered at least 3 m at 0.5 m/s (1.8 km/h)
-- or faster. Slower than that is a stop or GPS drift. Gaps between segments
-- are pauses and never count.
--
-- Null on trips that haven't been calculated; the app then falls back to the
-- recorded time (start to end, minus pauses), as before.
alter table public.journeys
  add column if not exists moving_seconds numeric
  check (moving_seconds is null or moving_seconds >= 0);

create or replace function public.journey_moving_seconds(p_journey_id uuid)
returns numeric
language sql
stable
set search_path = public, extensions
as $$
  with legs as (
    select
      extract(epoch from (
        p.recorded_at - lag(p.recorded_at) over w
      )) as seconds,
      st_distance(
        st_setsrid(
          st_makepoint(p.longitude::double precision, p.latitude::double precision),
          4326
        )::geography,
        st_setsrid(
          st_makepoint(
            (lag(p.longitude) over w)::double precision,
            (lag(p.latitude) over w)::double precision
          ),
          4326
        )::geography
      ) as meters
    from public.journey_points p
    where p.journey_id = p_journey_id
    window w as (partition by p.segment_number order by p.sequence_number)
  )
  select coalesce(sum(seconds), 0)::numeric(12, 2)
  from legs
  where seconds > 0 and meters >= 3 and meters / seconds >= 0.5;
$$;

revoke execute on function public.journey_moving_seconds(uuid)
  from public, anon;

-- Keeps it current: whenever points are inserted (an upload), recompute for
-- the journeys they belong to. Statement-level over the distinct journeys,
-- like the public-trip guard on the same table.
create or replace function public.refresh_journey_moving_time()
returns trigger
language plpgsql
security definer
set search_path = public, extensions
as $$
begin
  update public.journeys j
  set moving_seconds = public.journey_moving_seconds(j.id)
  where j.id in (select distinct journey_id from new_points_moving);
  return null;
end;
$$;

drop trigger if exists journey_points_moving_time on public.journey_points;
create trigger journey_points_moving_time
  after insert on public.journey_points
  referencing new table as new_points_moving
  for each statement execute function public.refresh_journey_moving_time();

-- Backfill for trips already uploaded. Service role only; not run by this
-- migration. Run `select public.backfill_journey_moving_time();` repeatedly
-- until it returns 0 (each call does up to p_limit trips).
create or replace function public.backfill_journey_moving_time(
  p_limit integer default 200
)
returns integer
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_done integer;
begin
  with todo as (
    select id from public.journeys
    where moving_seconds is null
    order by started_at
    limit greatest(p_limit, 1)
  ), done as (
    update public.journeys j
    set moving_seconds = public.journey_moving_seconds(j.id)
    from todo
    where j.id = todo.id
    returning 1
  )
  select count(*) into v_done from done;
  return v_done;
end;
$$;

revoke execute on function public.backfill_journey_moving_time(integer)
  from public, anon, authenticated;
