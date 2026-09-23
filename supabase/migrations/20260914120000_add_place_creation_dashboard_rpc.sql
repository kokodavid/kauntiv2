-- Dashboard RPC for creating a brand-new place, gated the same way as
-- update_place_dashboard_profile and the place_images RPCs. `places.lat`/
-- `lng` are generated columns over `location`, so this builds `location`
-- from the given lat/lng rather than accepting lat/lng as raw columns.
-- external_id is left null (only meaningful for imported/sourced batches,
-- and the (source, external_id) unique index only applies when
-- external_id is not null, so dashboard-created rows don't collide).

create or replace function public.create_place_dashboard_entry(
  p_county_id smallint,
  p_name text,
  p_type text,
  p_summary text,
  p_description text,
  p_source text,
  p_source_url text,
  p_licence text,
  p_last_verified_at date,
  p_lat double precision,
  p_lng double precision
)
returns public.places
language plpgsql
security definer
set search_path = public
as $$
declare
  v_role public.admin_role;
  v_place public.places;
begin
  v_role := public.current_admin_role();
  if v_role not in ('owner', 'admin', 'editor') then
    raise exception 'Place creation requires owner, admin, or editor access'
      using errcode = '42501';
  end if;

  if p_county_id is null then
    raise exception 'p_county_id is required' using errcode = '22004';
  end if;

  if not exists (select 1 from public.counties where id = p_county_id) then
    raise exception 'County % was not found', p_county_id using errcode = 'P0002';
  end if;

  if btrim(coalesce(p_name, '')) = '' then
    raise exception 'p_name is required' using errcode = '22004';
  end if;

  if btrim(coalesce(p_type, '')) = '' then
    raise exception 'p_type is required' using errcode = '22004';
  end if;

  if btrim(coalesce(p_source, '')) = '' then
    raise exception 'p_source is required' using errcode = '22004';
  end if;

  if p_lat is null or p_lng is null then
    raise exception 'p_lat and p_lng are required' using errcode = '22004';
  end if;

  if p_lat < -90 or p_lat > 90 then
    raise exception 'p_lat must be between -90 and 90' using errcode = '22003';
  end if;

  if p_lng < -180 or p_lng > 180 then
    raise exception 'p_lng must be between -180 and 180' using errcode = '22003';
  end if;

  if p_last_verified_at is not null and p_last_verified_at > current_date then
    raise exception 'p_last_verified_at cannot be in the future'
      using errcode = '22003';
  end if;

  insert into public.places (
    county_id,
    name,
    type,
    summary,
    description,
    location,
    source,
    source_url,
    licence,
    last_verified_at
  )
  values (
    p_county_id,
    btrim(p_name),
    btrim(p_type),
    nullif(btrim(p_summary), ''),
    nullif(btrim(p_description), ''),
    extensions.ST_SetSRID(extensions.ST_MakePoint(p_lng, p_lat), 4326),
    btrim(p_source),
    nullif(btrim(p_source_url), ''),
    nullif(btrim(p_licence), ''),
    p_last_verified_at
  )
  returning * into v_place;

  return v_place;
end;
$$;

revoke all on function public.create_place_dashboard_entry(
  smallint, text, text, text, text, text, text, text, date,
  double precision, double precision
) from public;
grant execute on function public.create_place_dashboard_entry(
  smallint, text, text, text, text, text, text, text, date,
  double precision, double precision
) to authenticated;
