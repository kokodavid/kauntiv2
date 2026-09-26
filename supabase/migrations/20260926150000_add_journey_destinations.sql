-- An optional place chosen before recording. Keep a name and coordinates
-- snapshot so replay remains meaningful if the place listing changes.
alter table public.journeys
  add column destination_place_id uuid,
  add column destination_name text,
  add column destination_latitude double precision,
  add column destination_longitude double precision;

alter table public.journeys
  add constraint journeys_destination_consistent check (
    (destination_place_id is null and destination_name is null
      and destination_latitude is null and destination_longitude is null)
    or
    (destination_place_id is not null
      and destination_name is not null
      and length(btrim(destination_name)) between 1 and 160
      and ((destination_latitude is null and destination_longitude is null)
        or (destination_latitude between -90 and 90
          and destination_longitude between -180 and 180)))
  );

-- Wrap the existing validated upload rather than copying its point,
-- entitlement and county checks. Both writes share one transaction.
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
  p_destination_longitude double precision
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
    p_points, p_paused_ms, p_counties
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
  uuid, text, double precision, double precision
) from public;
grant execute on function public.upload_journey_to_place(
  uuid, uuid, text, timestamptz, timestamptz, jsonb, bigint, jsonb,
  uuid, text, double precision, double precision
) to authenticated;
