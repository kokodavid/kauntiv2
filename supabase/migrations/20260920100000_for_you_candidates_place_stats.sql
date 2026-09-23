-- Extends for_you_candidates() to also return the linked place's own
-- name and trip stats (name, area_km2, elevation_m,
-- visit_duration_minutes -- doc 07's places table, added by
-- 20260920090000_add_place_trip_stats.sql) for a 'saved' candidate,
-- so the featured card in MapHomeSuggestionRow (the nearest "For you"
-- result, promoted to a full-width photo card, Figma node
-- 235:5214/5448) can show the specific saved place's name and its
-- Area/Elevation/Duration stats row instead of just the county.
--
-- All four new columns are null for 'unclaimed'/'depth_progress'
-- candidates (no single place_id to join against) and for a 'saved'
-- candidate whose place doesn't have the trip-stat columns filled in
-- yet -- the client already treats "all three stats null" as "hide the
-- stats row entirely", so this stays additive/safe with no dev-data
-- backfill required.
--
-- The return shape is changing (four new output columns), which
-- postgres does not allow via a plain CREATE OR REPLACE FUNCTION, so
-- this drops the old 2-arg signature first, same pattern
-- 20260904000000_add_live_location_to_ranking_functions.sql used the
-- last time this function's shape changed.
drop function if exists public.for_you_candidates(double precision, double precision);

create function public.for_you_candidates(
  p_latitude double precision default null,
  p_longitude double precision default null
)
returns table (
  reason text,
  county_id smallint,
  place_id uuid,
  distance_m double precision,
  place_name text,
  area_km2 numeric,
  elevation_m integer,
  visit_duration_minutes integer
)
language sql
stable
as $$
  with visited_current_county as (
    select v.county_id, c.centroid
    from public.county_visits v
    join public.counties c on c.id = v.county_id
    where v.user_id = auth.uid()
    order by v.entered_at desc
    limit 1
  ),
  current_county as (
    select extensions.ST_SetSRID(
             extensions.ST_MakePoint(p_longitude, p_latitude), 4326
           ) as centroid
    where p_latitude is not null and p_longitude is not null

    union all

    select centroid from visited_current_county
    where p_latitude is null or p_longitude is null

    union all

    select c.centroid
    from public.profiles p
    join public.counties c on c.id = p.home_county_id
    where p.id = auth.uid()
      and p.home_county_id is not null
      and (p_latitude is null or p_longitude is null)
      and not exists (select 1 from visited_current_county)
    limit 1
  ),
  candidates as (
    -- unclaimed counties
    select 'unclaimed'::text as reason, c.id as county_id, null::uuid as place_id, c.centroid as location
    from public.counties c
    where c.id not in (
      select county_id from public.county_visits
      where user_id = auth.uid() and state = 'explored'
    )

    union all

    -- held counties not yet Local Expert
    select 'depth_progress', p.county_id, null, c.centroid
    from public.county_depth_progress p
    join public.counties c on c.id = p.county_id
    where p.user_id = auth.uid() and p.rank <> 'local_expert'

    union all

    -- saved, un-ticked wishlist places
    select 'saved', w.county_id, w.place_id, coalesce(pl.location, c.centroid)
    from public.wishlist_items w
    left join public.places pl on pl.id = w.place_id
    join public.counties c on c.id = w.county_id
    where w.user_id = auth.uid() and w.ticked_at is null
  ),
  ranked_candidates as (
    select cand.reason, cand.county_id, cand.place_id,
           extensions.ST_DistanceSphere(cc.centroid, cand.location) as distance_m
    from candidates cand, current_county cc
  ),
  nearest_per_county as (
    select distinct on (county_id)
           reason, county_id, place_id, distance_m
    from ranked_candidates
    order by county_id, distance_m asc
  )
  select
    npc.reason, npc.county_id, npc.place_id, npc.distance_m,
    pl.name as place_name,
    pl.area_km2,
    pl.elevation_m,
    pl.visit_duration_minutes
  from nearest_per_county npc
  left join public.places pl on pl.id = npc.place_id
  order by npc.distance_m asc
  limit 3;
$$;

revoke execute on function public.for_you_candidates(double precision, double precision) from public;
grant execute on function public.for_you_candidates(double precision, double precision) to authenticated;
