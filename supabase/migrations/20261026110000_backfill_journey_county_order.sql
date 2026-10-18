-- Backfill journey_counties.position from the saved route points and the
-- county polygons in public.counties (PostGIS). Position 0 is the county
-- whose first matching route point comes earliest in recording order.
--
-- Counties no point falls inside (a boundary mismatch with the app's
-- bundled polygons, say) are ranked after the matched ones, by county id,
-- so every row ends up with a position and is never picked up again.
--
-- Not run by the migration itself. From the SQL editor (service role):
--   select public.backfill_journey_county_order('<user uuid>');  -- one user
--   select public.backfill_journey_county_order();               -- everyone
-- Each call handles p_limit trips and returns how many county rows it set;
-- call it again until it returns 0.
create or replace function public.backfill_journey_county_order(
  p_user_id uuid default null,
  p_limit integer default 200
)
returns integer
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_rows integer;
begin
  with todo as (
    select distinct jc.journey_id
    from public.journey_counties jc
    where jc.position is null
      and (p_user_id is null or jc.user_id = p_user_id)
    order by jc.journey_id
    limit p_limit
  ),
  first_in as (
    select
      jc.journey_id,
      jc.county_id,
      (
        select min(p.sequence_number)
        from public.journey_points p
        where p.journey_id = jc.journey_id
          and st_covers(
            c.geometry,
            st_setsrid(
              st_makepoint(p.longitude::double precision, p.latitude::double precision),
              4326
            )
          )
      ) as first_seq
    from todo t
    join public.journey_counties jc on jc.journey_id = t.journey_id
    join public.counties c on c.id = jc.county_id
  ),
  ranked as (
    select
      journey_id,
      county_id,
      (row_number() over (
        partition by journey_id
        order by first_seq nulls last, county_id
      ) - 1)::smallint as pos
    from first_in
  )
  update public.journey_counties jc
  set position = r.pos
  from ranked r
  where jc.journey_id = r.journey_id
    and jc.county_id = r.county_id;

  get diagnostics v_rows = row_count;
  return v_rows;
end;
$$;

revoke execute on function public.backfill_journey_county_order(uuid, integer)
  from public, anon, authenticated;
grant execute on function public.backfill_journey_county_order(uuid, integer)
  to service_role;
