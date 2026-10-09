-- Planned stops: the places a Trip was meant to pass on the way to its
-- destination, in order. A record of the plan only: badges and county
-- credit still come from the recorded points.
alter table public.journeys
  add column stops jsonb not null default '[]'::jsonb;

alter table public.journeys
  add constraint journeys_stops_is_short_array check (
    jsonb_typeof(stops) = 'array' and jsonb_array_length(stops) <= 6
  );

-- Each stop needs a place id, a 1-160 character name and valid coordinates.
create function public.journey_stops_valid(p_stops jsonb)
returns boolean
language sql
immutable
set search_path = public
as $$
  select p_stops is not null
    and jsonb_typeof(p_stops) = 'array'
    and jsonb_array_length(p_stops) <= 6
    and not exists (
      select 1
      from jsonb_array_elements(p_stops) stop
      where jsonb_typeof(stop) <> 'object'
         or jsonb_typeof(stop -> 'place_id') is distinct from 'string'
         or jsonb_typeof(stop -> 'name') is distinct from 'string'
         or length(btrim(stop ->> 'name')) not between 1 and 160
         or jsonb_typeof(stop -> 'lat') is distinct from 'number'
         or jsonb_typeof(stop -> 'lng') is distinct from 'number'
         or (stop ->> 'lat')::double precision not between -90 and 90
         or (stop ->> 'lng')::double precision not between -180 and 180
    );
$$;

-- upload_journey_to_place gains p_stops (default none, so an older app
-- build that doesn't send it still uploads). Stops are stored on the first
-- upload only, like the destination: a retry cannot change them.
drop function public.upload_journey_to_place(
  uuid, uuid, text, timestamptz, timestamptz, jsonb, bigint, jsonb,
  uuid, text, double precision, double precision, text
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
  p_transport_mode text default null,
  p_stops jsonb default '[]'::jsonb
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
  if not public.journey_stops_valid(coalesce(p_stops, '[]'::jsonb)) then
    raise exception 'Journey stops are not valid' using errcode = '22023';
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
      destination_longitude = p_destination_longitude,
      stops = coalesce(p_stops, '[]'::jsonb)
  where id = p_journey_id and user_id = p_user_id
    and destination_place_id is null;
  return v_result;
end;
$$;

revoke execute on function public.upload_journey_to_place(
  uuid, uuid, text, timestamptz, timestamptz, jsonb, bigint, jsonb,
  uuid, text, double precision, double precision, text, jsonb
) from public;
grant execute on function public.upload_journey_to_place(
  uuid, uuid, text, timestamptz, timestamptz, jsonb, bigint, jsonb,
  uuid, text, double precision, double precision, text, jsonb
) to authenticated;
