-- Journeys step 3: average/top speed and highest elevation.
--
-- Average speed is always distance/duration and computed client-side, so it
-- needs no storage. Top speed and highest elevation require scanning every
-- point, so they are computed once at upload time and stored on the
-- journey row.

alter table public.journeys
  add column top_speed_mps numeric,
  add column highest_elevation_m numeric;

alter table public.journey_points
  add column altitude_m numeric,
  add column speed_mps numeric;

-- journey_upload_rows() is a table function: its output columns can only
-- change by dropping and recreating it, not CREATE OR REPLACE.
drop function public.journey_upload_rows(jsonb);

create function public.journey_upload_rows(p_points jsonb)
returns table (
  sequence_number integer,
  segment_number integer,
  recorded_at timestamptz,
  latitude numeric,
  longitude numeric,
  accuracy_m numeric,
  altitude_m numeric,
  speed_mps numeric
)
language sql
stable
set search_path = public
as $$
  select
    (e.ord - 1)::integer,
    (e.p ->> 'segment')::integer,
    (e.p ->> 'recorded_at')::timestamptz,
    (e.p ->> 'lat')::numeric,
    (e.p ->> 'lng')::numeric,
    (e.p ->> 'accuracy_m')::numeric,
    nullif(e.p ->> 'altitude_m', '')::numeric,
    nullif(e.p ->> 'speed_mps', '')::numeric
  from jsonb_array_elements(p_points) with ordinality as e (p, ord);
$$;

revoke execute on function public.journey_upload_rows(jsonb) from public;

-- Re-published with the two new stats. Same signature and rules as before;
-- only the stored/returned fields grow.
create or replace function public.upload_journey(
  p_user_id uuid,
  p_journey_id uuid,
  p_title text,
  p_started_at timestamptz,
  p_ended_at timestamptz,
  p_points jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_existing public.journeys;
  v_count integer;
  v_bad integer;
  v_distance numeric;
  v_top_speed numeric;
  v_highest_elevation numeric;
begin
  if v_user is null or v_user <> p_user_id then
    raise exception 'Journey owner does not match the signed-in account'
      using errcode = '42501';
  end if;

  select * into v_existing from public.journeys where id = p_journey_id;
  if found then
    if v_existing.user_id <> v_user then
      raise exception 'Journey belongs to another account'
        using errcode = '42501';
    end if;
    return jsonb_build_object(
      'id', v_existing.id,
      'distance_m', v_existing.distance_m,
      'top_speed_mps', v_existing.top_speed_mps,
      'highest_elevation_m', v_existing.highest_elevation_m,
      'already_uploaded', true
    );
  end if;

  if p_ended_at <= p_started_at
     or p_ended_at > now() + interval '5 minutes'
     or p_ended_at - p_started_at > interval '7 days'
     or p_started_at < now() - interval '90 days' then
    raise exception 'Journey timing is not valid' using errcode = '22023';
  end if;

  if not public.has_pro_at(v_user, p_started_at) then
    raise exception 'Pro was not active when this Journey started'
      using errcode = '42501';
  end if;

  if p_points is null or jsonb_typeof(p_points) <> 'array' then
    raise exception 'Journey points must be an array' using errcode = '22023';
  end if;
  v_count := jsonb_array_length(p_points);
  if v_count > 50000 then
    raise exception 'Too many Journey points' using errcode = '22023';
  end if;

  select count(*) into v_bad
  from (
    select
      point.*,
      lag(point.recorded_at) over w as previous_at,
      lag(point.segment_number) over w as previous_segment
    from public.journey_upload_rows(p_points) point
    window w as (order by point.sequence_number)
  ) checked
  where checked.segment_number is null
     or checked.recorded_at is null
     or checked.latitude is null
     or checked.longitude is null
     or checked.accuracy_m is null
     or checked.segment_number < 0
     or checked.recorded_at < p_started_at
     or checked.recorded_at > p_ended_at
     or checked.recorded_at <= checked.previous_at
     or checked.segment_number < checked.previous_segment;
  if v_bad > 0 then
    raise exception 'Journey points are not valid' using errcode = '22023';
  end if;

  select coalesce(sum(
    2 * 6371000 * asin(sqrt(
      power(sin(radians(pair.latitude - pair.previous_latitude) / 2), 2)
      + cos(radians(pair.previous_latitude)) * cos(radians(pair.latitude))
        * power(sin(radians(pair.longitude - pair.previous_longitude) / 2), 2)
    ))
  ), 0) into v_distance
  from (
    select
      point.latitude,
      point.longitude,
      lag(point.latitude) over w as previous_latitude,
      lag(point.longitude) over w as previous_longitude
    from public.journey_upload_rows(p_points) point
    window w as (partition by point.segment_number order by point.sequence_number)
  ) pair
  where pair.previous_latitude is not null;

  select max(point.speed_mps), max(point.altitude_m)
    into v_top_speed, v_highest_elevation
  from public.journey_upload_rows(p_points) point;

  insert into public.journeys (
    id, user_id, title, started_at, ended_at, distance_m,
    top_speed_mps, highest_elevation_m
  ) values (
    p_journey_id, v_user, p_title, p_started_at, p_ended_at,
    round(v_distance, 2), v_top_speed, v_highest_elevation
  );

  insert into public.journey_points (
    journey_id, sequence_number, segment_number, recorded_at,
    latitude, longitude, accuracy_m, altitude_m, speed_mps
  )
  select
    p_journey_id, sequence_number, segment_number, recorded_at,
    round(latitude, 6), round(longitude, 6), round(accuracy_m, 2),
    altitude_m, speed_mps
  from public.journey_upload_rows(p_points);

  return jsonb_build_object(
    'id', p_journey_id,
    'distance_m', round(v_distance, 2),
    'top_speed_mps', v_top_speed,
    'highest_elevation_m', v_highest_elevation,
    'already_uploaded', false
  );
end;
$$;

revoke execute on function public.upload_journey(uuid, uuid, text, timestamptz, timestamptz, jsonb)
  from public;
grant execute on function public.upload_journey(uuid, uuid, text, timestamptz, timestamptz, jsonb)
  to authenticated;
