-- Journeys: transport mode (Drive/Walk/Cycle), chosen on the phone before
-- a Trip starts. Existing Trips have none (recorded before this existed).
alter table public.journeys
  add column transport_mode text
    check (transport_mode is null or transport_mode in ('drive', 'walk', 'cycle'));

-- upload_journey gains p_transport_mode (default null, so an older app
-- build that doesn't send it still uploads). Everything else - ownership,
-- timing, paused time, point validation, distance/speed/elevation, county
-- split, the free-Trip allowance - is unchanged from the previous version.
drop function public.upload_journey(
  uuid, uuid, text, timestamptz, timestamptz, jsonb, bigint, jsonb
);

create function public.upload_journey(
  p_user_id uuid,
  p_journey_id uuid,
  p_title text,
  p_started_at timestamptz,
  p_ended_at timestamptz,
  p_points jsonb,
  p_paused_ms bigint default 0,
  p_counties jsonb default '[]'::jsonb,
  p_transport_mode text default null
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
  v_free boolean;
  v_period date;
  v_trial_used smallint;
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

  if p_transport_mode is not null
     and p_transport_mode not in ('drive', 'walk', 'cycle') then
    raise exception 'Journey transport mode is not valid' using errcode = '22023';
  end if;

  -- Pro is unlimited. A free account gets 3 saved Trips a month; locking
  -- the usage row (for update) keeps two concurrent uploads from both
  -- reading "2 used" and both being allowed through as the 3rd.
  v_free := not public.has_pro_at(v_user, now());
  if v_free then
    v_period := date_trunc('month', timezone('UTC', now()))::date;
    insert into public.journey_trial_usage (user_id, period_month, trips_used)
    values (v_user, v_period, 0)
    on conflict (user_id, period_month) do nothing;

    select trips_used into v_trial_used
      from public.journey_trial_usage
      where user_id = v_user and period_month = v_period
      for update;
    if coalesce(v_trial_used, 0) >= 3 then
      raise exception 'Free Trip limit reached for this month'
        using errcode = '75001';
    end if;
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
    top_speed_mps, highest_elevation_m, transport_mode
  ) values (
    p_journey_id, v_user, p_title, p_started_at, p_ended_at,
    round(v_distance, 2), p_paused_ms, v_top_speed, v_highest_elevation,
    p_transport_mode
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

  if v_free then
    insert into public.journey_trial_usage (user_id, period_month, trips_used)
    values (v_user, v_period, 1)
    on conflict (user_id, period_month)
    do update set trips_used = journey_trial_usage.trips_used + 1;
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
  uuid, uuid, text, timestamptz, timestamptz, jsonb, bigint, jsonb, text
) from public;
grant execute on function public.upload_journey(
  uuid, uuid, text, timestamptz, timestamptz, jsonb, bigint, jsonb, text
) to authenticated;

-- upload_journey_to_place gains the same p_transport_mode and forwards it
-- to upload_journey, unchanged otherwise.
drop function public.upload_journey_to_place(
  uuid, uuid, text, timestamptz, timestamptz, jsonb, bigint, jsonb,
  uuid, text, double precision, double precision
);

create function public.upload_journey_to_place(
  p_user_id uuid,
  p_journey_id uuid,
  p_title text,
  p_started_at timestamptz,
  p_ended_at timestamptz,
  p_points jsonb,
  p_paused_ms bigint,
  p_counties jsonb,
  p_destination_place_id uuid,
  p_destination_name text,
  p_destination_latitude double precision,
  p_destination_longitude double precision,
  p_transport_mode text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_result jsonb;
  v_existing_place_id uuid;
begin
  if auth.uid() is null or auth.uid() <> p_user_id then
    raise exception 'Journey owner does not match the signed-in account'
      using errcode = '42501';
  end if;
  if p_destination_place_id is null
     or p_destination_name is null
     or length(btrim(p_destination_name)) not between 1 and 160
     or (p_destination_latitude is null) <> (p_destination_longitude is null)
     or p_destination_latitude not between -90 and 90
     or p_destination_longitude not between -180 and 180 then
    raise exception 'Journey destination is not valid' using errcode = '22023';
  end if;

  v_result := public.upload_journey(
    p_user_id, p_journey_id, p_title, p_started_at, p_ended_at,
    p_points, p_paused_ms, p_counties, p_transport_mode
  );

  select destination_place_id into v_existing_place_id
  from public.journeys
  where id = p_journey_id and user_id = p_user_id;
  if v_existing_place_id is not null
     and v_existing_place_id <> p_destination_place_id then
    raise exception 'Journey destination cannot change on retry'
      using errcode = '22023';
  end if;

  update public.journeys
  set destination_place_id = p_destination_place_id,
      destination_name = p_destination_name,
      destination_latitude = p_destination_latitude,
      destination_longitude = p_destination_longitude
  where id = p_journey_id and user_id = p_user_id
    and destination_place_id is null;
  return v_result;
end;
$$;

revoke execute on function public.upload_journey_to_place(
  uuid, uuid, text, timestamptz, timestamptz, jsonb, bigint, jsonb,
  uuid, text, double precision, double precision, text
) from public;
grant execute on function public.upload_journey_to_place(
  uuid, uuid, text, timestamptz, timestamptz, jsonb, bigint, jsonb,
  uuid, text, double precision, double precision, text
) to authenticated;
