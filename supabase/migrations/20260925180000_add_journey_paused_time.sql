-- Journeys keep how long they were paused, so the recorded time (start to
-- end minus pauses) can be shown; the live clock already stands still
-- while paused. Existing Journeys get 0 (their time includes pauses).
alter table public.journeys
  add column paused_ms bigint not null default 0,
  add constraint journeys_paused_ms_range check (
    paused_ms >= 0
    and paused_ms <= extract(epoch from (ended_at - started_at)) * 1000
  );

-- upload_journey gains p_paused_ms (default 0, so an older app build that
-- doesn't send it still uploads). Same checks as before, plus: paused time
-- must fit inside the Journey (22023).
drop function public.upload_journey(uuid, uuid, text, timestamptz, timestamptz, jsonb);

create function public.upload_journey(
  p_user_id uuid,
  p_journey_id uuid,
  p_title text,
  p_started_at timestamptz,
  p_ended_at timestamptz,
  p_points jsonb,
  p_paused_ms bigint default 0
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
      'already_uploaded', true
    );
  end if;

  if p_ended_at <= p_started_at
     or p_ended_at > now() + interval '5 minutes'
     or p_ended_at - p_started_at > interval '7 days'
     or p_started_at < now() - interval '90 days' then
    raise exception 'Journey timing is not valid' using errcode = '22023';
  end if;

  -- Paused time sits inside the Journey (recorded time is never negative).
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

  insert into public.journeys (
    id, user_id, title, started_at, ended_at, distance_m, paused_ms
  ) values (
    p_journey_id, v_user, p_title, p_started_at, p_ended_at,
    round(v_distance, 2), p_paused_ms
  );

  insert into public.journey_points (
    journey_id, sequence_number, segment_number, recorded_at,
    latitude, longitude, accuracy_m
  )
  select
    p_journey_id, sequence_number, segment_number, recorded_at,
    round(latitude, 6), round(longitude, 6), round(accuracy_m, 2)
  from public.journey_upload_rows(p_points);

  return jsonb_build_object(
    'id', p_journey_id,
    'distance_m', round(v_distance, 2),
    'already_uploaded', false
  );
end;
$$;

revoke execute on function public.upload_journey(uuid, uuid, text, timestamptz, timestamptz, jsonb, bigint)
  from public;
grant execute on function public.upload_journey(uuid, uuid, text, timestamptz, timestamptz, jsonb, bigint)
  to authenticated;
