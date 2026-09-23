-- Adds an optional live GPS anchor to the two "nearest" ranking RPCs
-- (for_you_candidates(), discover_unclaimed_counties()), for the new
-- foreground-only current-location read on the Flutter side (distinct
-- from Module 4's background geofencing, which drives badge crossings
-- via native_geofence's own OS-level region monitoring and is untouched
-- by this migration).
--
-- Both functions anchor their distance math on a "current county" CTE
-- that falls back from the most recently visited county's centroid to
-- the declared home county's centroid to nothing at all. That's a
-- reasonable default when there's no live fix, but it's necessarily
-- stale -- it answers "where were you last seen/where do you live", not
-- "where are you right now". A user standing in a county they've
-- already explored, deciding what to do next, gets suggestions ranked
-- from that county's centroid rather than from underfoot.
--
-- p_latitude/p_longitude are optional (default null) so every existing
-- caller -- including an app build that predates this migration, or a
-- call made with location permission denied/no fix yet -- keeps getting
-- exactly today's behavior. When both are supplied, the live point wins
-- outright over the visited/home fallback chain, added as a third
-- mutually-exclusive arm of the same union-all pattern the fallback
-- chain already used, so the null-coordinate path's row count (0 or 1)
-- is untouched -- deliberately not restructured into a form (e.g. a
-- bare `case` expression) that would turn an empty anchor into a
-- guaranteed one-row-with-null-centroid result, which would silently
-- change for_you_candidates()'s existing "no visit, no home county ->
-- no suggestions at all" behavior (its `from candidates cand,
-- current_county cc` is a cross join, not a left join).
--
-- Postgres note: this can't be a plain `create or replace` on the
-- existing zero-argument functions -- adding parameters (even
-- defaulted ones) changes the signature, so `create or replace` would
-- create a second overloaded function rather than replace the first,
-- and a zero-argument call would then be ambiguous between the two
-- ("function is not unique"). Each function is dropped first.

drop function if exists public.for_you_candidates();

create function public.for_you_candidates(
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
    -- Live location, when supplied, wins outright over both fallbacks
    -- below.
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
  )
  select cand.reason, cand.county_id, cand.place_id,
         extensions.ST_DistanceSphere(cc.centroid, cand.location) as distance_m
  from candidates cand, current_county cc
  order by distance_m asc
  limit 3;
$$;

revoke execute on function public.for_you_candidates(double precision, double precision) from public;
grant execute on function public.for_you_candidates(double precision, double precision) to authenticated;

drop function if exists public.discover_unclaimed_counties();

create function public.discover_unclaimed_counties(
  p_latitude double precision default null,
  p_longitude double precision default null
)
returns table (
  county_id smallint,
  distance_m double precision,
  rarity_pct numeric
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
  )
  select c.id as county_id,
         case
           when cc.centroid is null then null
           else extensions.ST_DistanceSphere(cc.centroid, c.centroid)
         end as distance_m,
         c.rarity_pct
  from public.counties c
  left join current_county cc on true
  where c.id not in (
    select county_id from public.county_visits
    where user_id = auth.uid() and state = 'explored'
  );
$$;

revoke execute on function public.discover_unclaimed_counties(double precision, double precision) from public;
grant execute on function public.discover_unclaimed_counties(double precision, double precision) to authenticated;
