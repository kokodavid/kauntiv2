-- Journeys per county, for the badge sheet ("2 Journeys · 38 km").
--
-- journey_counties: the counties a Journey's route crossed and roughly
-- how far it went in each. Computed on the phone from the bundled county
-- boundaries at upload and written only by upload_journey; private to the
-- owner like the Journey itself (deleting the Journey removes them).
-- Journeys uploaded before this have none.
create table public.journey_counties (
  journey_id uuid not null references public.journeys (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  county_id smallint not null references public.counties (id),
  distance_m numeric(12, 2) not null default 0 check (distance_m >= 0),
  primary key (journey_id, county_id)
);

create index journey_counties_user_county_idx
  on public.journey_counties (user_id, county_id);

alter table public.journey_counties enable row level security;

create policy "Users read their own journey counties"
  on public.journey_counties
  for select
  to authenticated
  using (user_id = auth.uid());

-- upload_journey gains p_counties (default [], so older builds still
-- upload). Everything else is unchanged.
drop function public.upload_journey(uuid, uuid, text, timestamptz, timestamptz, jsonb, bigint);

create function public.upload_journey(
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

  -- Counties the route crossed and the distance in each (computed on the
  -- phone from the bundled boundaries). Unknown county ids are skipped.
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
    'already_uploaded', false
  );
end;
$$;

revoke execute on function public.upload_journey(uuid, uuid, text, timestamptz, timestamptz, jsonb, bigint, jsonb)
  from public;
grant execute on function public.upload_journey(uuid, uuid, text, timestamptz, timestamptz, jsonb, bigint, jsonb)
  to authenticated;

-- county_badge_detail adds the last visit (explored or passed through)
-- and Journeys in the county.
create or replace function public.county_badge_detail(p_county_id smallint)
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  with visit as (
    select v.state, v.confirmed_at
    from public.county_visits v
    where v.user_id = auth.uid() and v.county_id = p_county_id
  ),
  explored as (
    select
      count(*) as visits,
      count(distinct date_trunc('month', e.entered_at)) as months,
      max(e.entered_at) as last_at
    from public.county_visit_events e
    where e.user_id = auth.uid()
      and e.county_id = p_county_id
      and e.outcome = 'explored'
  ),
  last_visit as (
    select max(e.entered_at) as at
    from public.county_visit_events e
    where e.user_id = auth.uid() and e.county_id = p_county_id
  ),
  journeys as (
    select count(distinct jc.journey_id) as count,
           coalesce(sum(jc.distance_m), 0) as distance
    from public.journey_counties jc
    where jc.user_id = auth.uid() and jc.county_id = p_county_id
  ),
  saved as (
    select
      count(distinct w.place_id) as saved,
      count(distinct w.place_id) filter (where w.ticked_at is not null)
        as visited
    from public.wishlist_items w
    where w.user_id = auth.uid()
      and w.county_id = p_county_id
      and w.place_id is not null
  ),
  county_places as (
    select count(*) as total
    from public.places p
    where p.county_id = p_county_id
  ),
  suggestions as (
    select coalesce(
      jsonb_agg(
        jsonb_build_object('id', s.id, 'name', s.name, 'type', s.type)
        order by s.name
      ),
      '[]'::jsonb
    ) as list
    from (
      select p.id, p.name, p.type
      from public.places p
      where p.county_id = p_county_id and p.lat is not null
      order by p.name
      limit 5
    ) s
  )
  select jsonb_build_object(
    'state', (select state from visit),
    'earned_at', (select confirmed_at from visit),
    'explored_visits', (select visits from explored),
    'explored_months', (select months from explored),
    'last_explored_at', (select last_at from explored),
    'last_visited_at', (select at from last_visit),
    'journeys', (select count from journeys),
    'journey_distance_m', (select distance from journeys),
    'saved_places', (select saved from saved),
    'saved_visited', (select visited from saved),
    'places_total', (select total from county_places),
    'places_visited', (select visited from saved),
    'suggested_places', (select list from suggestions)
  );
$$;

revoke execute on function public.county_badge_detail(smallint) from public;
grant execute on function public.county_badge_detail(smallint) to authenticated;
