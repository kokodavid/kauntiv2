-- Trip planner: custom places that people keep adding, and moving them onto
-- the real place once Kaunti47 has it.

-- Lower-case letters and digits only, for comparing names.
create function trip_plan_private.place_key(p_name text)
returns text
language sql
immutable
set search_path = ''
as $$
  select regexp_replace(lower(coalesce(p_name, '')), '[^a-z0-9]+', '', 'g');
$$;

-- Metres between two points (haversine).
create function trip_plan_private.metres_between(
  a_lat double precision, a_lng double precision,
  b_lat double precision, b_lng double precision
)
returns double precision
language sql
immutable
set search_path = ''
as $$
  select 2 * 6371000 * asin(least(1, sqrt(
    power(sin(radians(b_lat - a_lat) / 2), 2)
    + cos(radians(a_lat)) * cos(radians(b_lat))
      * power(sin(radians(b_lng - a_lng) / 2), 2))));
$$;

-- Points every custom place that matches the place at its place: the same
-- name within 500 m, or one name inside the other within 150 m. Stops keep
-- their position, note and day; a Places to visit entry that would repeat a
-- place already on the list is dropped. Returns how many were upgraded.
create function trip_plan_private.upgrade_custom_places(p_place uuid)
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare v_pl record; v_key text; v_custom record; v_count integer := 0;
begin
  select id, name, lat, lng into v_pl from public.places
  where id = p_place and status = 'reviewed' and archived_at is null;
  if not found or v_pl.lat is null or v_pl.lng is null then
    return 0;
  end if;
  v_key := trip_plan_private.place_key(v_pl.name);
  if length(v_key) < 3 then
    return 0;
  end if;
  for v_custom in
    select c.id, c.plan_id from public.trip_plan_custom_places c
    where trip_plan_private.metres_between(c.lat, c.lng, v_pl.lat, v_pl.lng) <= 500
      and (
        trip_plan_private.place_key(c.name) = v_key
        or (trip_plan_private.metres_between(c.lat, c.lng, v_pl.lat, v_pl.lng) <= 150
          and length(trip_plan_private.place_key(c.name)) >= 4
          and (position(v_key in trip_plan_private.place_key(c.name)) > 0
            or position(trip_plan_private.place_key(c.name) in v_key) > 0))
      )
  loop
    update public.trip_plan_days set route_stops_key = null, updated_at = now()
    where id in (select day_id from public.trip_plan_stops where custom_id = v_custom.id);
    update public.trip_plan_stops
    set place_id = p_place, custom_id = null, updated_at = now()
    where custom_id = v_custom.id;
    if exists (select 1 from public.trip_plan_places
        where plan_id = v_custom.plan_id and place_id = p_place) then
      delete from public.trip_plan_places where custom_id = v_custom.id;
    else
      update public.trip_plan_places set place_id = p_place, custom_id = null
      where custom_id = v_custom.id;
    end if;
    delete from public.trip_plan_custom_places where id = v_custom.id;
    v_count := v_count + 1;
  end loop;
  return v_count;
end $$;

create function trip_plan_private.upgrade_on_place_change()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.status = 'reviewed' and new.archived_at is null
    and (tg_op = 'INSERT' or old.status is distinct from 'reviewed'
      or old.archived_at is not null) then
    perform trip_plan_private.upgrade_custom_places(new.id);
  end if;
  return new;
end $$;

create trigger trip_plan_custom_places_upgrade
  after insert or update of status, archived_at on public.places
  for each row execute function trip_plan_private.upgrade_on_place_change();

-- Dashboard: the unknown places people add most, nearby spellings together.
create function public.trip_plan_custom_place_suggestions(p_limit integer default 50)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if coalesce(public.current_admin_role() in ('owner', 'admin', 'editor'), false) is not true then
    raise exception 'Dashboard access required' using errcode = '42501';
  end if;
  return coalesce((
    select jsonb_agg(row_to_json(g) order by g.plans desc, g.last_added desc)
    from (
      select min(c.name) as name,
        round(avg(c.lat)::numeric, 5) as lat,
        round(avg(c.lng)::numeric, 5) as lng,
        mode() within group (order by c.county_code) as county_code,
        count(distinct c.plan_id) as plans,
        count(*) filter (where c.source = 'search') as from_search,
        count(*) filter (where c.source = 'pin') as from_pin,
        max(c.created_at) as last_added
      from public.trip_plan_custom_places c
      group by trip_plan_private.place_key(c.name),
        round(c.lat::numeric, 2), round(c.lng::numeric, 2)
      order by count(distinct c.plan_id) desc, max(c.created_at) desc
      limit greatest(1, least(coalesce(p_limit, 50), 200))
    ) g
  ), '[]'::jsonb);
end $$;

revoke execute on function public.trip_plan_custom_place_suggestions(integer) from public;
grant execute on function public.trip_plan_custom_place_suggestions(integer) to authenticated;
