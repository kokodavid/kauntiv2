-- The stats migration introduced a six-argument overload, but clients call
-- the eight-argument upload (which also stores paused time and county splits).
-- Replace that function instead, and remove the unintended overload.
drop function if exists public.upload_journey(
  uuid, uuid, text, timestamptz, timestamptz, jsonb
);

create or replace function public.upload_journey(
  p_user_id uuid,
  p_journey_id uuid,
  p_title text,
  p_started_at timestamptz,
  p_ended_at timestamptz,
  p_points jsonb,
  p_paused_ms bigint default 0,
  p_counties jsonb default '[]'::jsonb
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

  if p_paused_ms is null
     or p_paused_ms < 0
     or p_paused_ms > extract(epoch from (p_ended_at - p_started_at)) * 1000 then
    raise exception 'Journey paused time is not valid' using errcode = '22023';
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
    id, user_id, title, started_at, ended_at, distance_m, paused_ms,
    top_speed_mps, highest_elevation_m
  ) values (
    p_journey_id, v_user, p_title, p_started_at, p_ended_at,
    round(v_distance, 2), p_paused_ms, v_top_speed, v_highest_elevation
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

  if p_counties is not null and jsonb_typeof(p_counties) = 'array' then
    insert into public.journey_counties (journey_id, user_id, county_id, distance_m)
    select p_journey_id, v_user, c.id, round(greatest(sum(c.distance), 0), 2)
    from (
      select (item ->> 'county_id')::smallint as id,
             coalesce((item ->> 'distance_m')::numeric, 0) as distance
      from jsonb_array_elements(p_counties) item
      where jsonb_typeof(item) = 'object'
        and (item ->> 'county_id') ~ '^[0-9]{1,2}$'
    ) c
    where exists (select 1 from public.counties k where k.id = c.id)
    group by c.id;
  end if;

  return jsonb_build_object(
    'id', p_journey_id,
    'distance_m', round(v_distance, 2),
    'top_speed_mps', v_top_speed,
    'highest_elevation_m', v_highest_elevation,
    'already_uploaded', false
  );
end;
$$;

revoke execute on function public.upload_journey(
  uuid, uuid, text, timestamptz, timestamptz, jsonb, bigint, jsonb
) from public;
grant execute on function public.upload_journey(
  uuid, uuid, text, timestamptz, timestamptz, jsonb, bigint, jsonb
) to authenticated;
