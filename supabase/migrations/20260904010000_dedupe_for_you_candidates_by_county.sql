-- Fixes for_you_candidates(): the candidate pool is a union of three
-- independent sources (unclaimed counties, held-but-not-Local-Expert
-- counties, saved-but-un-ticked wishlist places), and nothing deduped
-- the final ranked list by county_id. A county with several qualifying
-- candidates near the anchor point -- e.g. itself unclaimed *and*
-- holding two separate saved places -- could contribute multiple rows
-- to the same top-3 result, crowding out every other county even when
-- one of them was only slightly farther away. Confirmed live: a user
-- standing near Nairobi with two saved, un-ticked Nairobi places saw
-- three "For you" cards, all Nairobi, one UNCLAIMED and two SAVED HERE.
--
-- The rule (doc 01/07: "For you recommends the nearest place or county
-- you haven't finished") was always meant to surface *counties*, not to
-- let one county fill every slot. Each county now contributes at most
-- its single nearest-ranked candidate to the final list -- `distinct on
-- (county_id)` ordered by distance picks that candidate (whichever
-- reason has the smaller distance wins; no other tie-break needed since
-- distance is already the one ranking rule) -- and the outer query then
-- ranks those per-county picks and takes the nearest 3 distinct
-- counties.
--
-- Same 2-argument signature as the previous migration
-- (20260904000000_add_live_location_to_ranking_functions.sql), so this
-- is a plain `create or replace` -- no drop needed, unlike that one.
create or replace function public.for_you_candidates(
  p_latitude double precision default null,
  p_longitude double precision default null
)
returns table (
  reason text,
  county_id smallint,
  place_id uuid,
  distance_m double precision
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
  select reason, county_id, place_id, distance_m
  from nearest_per_county
  order by distance_m asc
  limit 3;
$$;

revoke execute on function public.for_you_candidates(double precision, double precision) from public;
grant execute on function public.for_you_candidates(double precision, double precision) to authenticated;
