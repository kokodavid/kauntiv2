set search_path = extensions, public;

-- Interests drive "For you".
--
-- 1. interest_place_types maps each interest key a traveller can pick
--    (profiles.interests, see 20261012100000_add_profile_interests.sql)
--    to the raw places.type values that count as a match. places.type is
--    free text typed in the dashboard, so this table is the one place
--    where "waterfall" and "hike" are said to be the "water" interest.
--    Edit rows here (or from the dashboard) to change matching without an
--    app release. A type may belong to several interests (a park is both
--    nature and wildlife), and unknown types simply match nothing.
-- 2. for_you_candidates() now leans toward counties that hold places
--    matching the signed-in user's interests: a matching county's
--    distance is counted as 60% of its real distance when ordering, so it
--    can edge ahead of an equally close county without one. It only
--    reorders. Nothing is hidden, the returned distance_m is still the
--    real distance, and someone with no interests (unanswered, or
--    answered "none") gets exactly the previous order. The return shape
--    is unchanged, so no drop is needed.

create table if not exists public.interest_place_types (
  interest_key text not null,
  place_type text not null,
  primary key (interest_key, place_type),
  constraint interest_place_types_key_known check (
    interest_key in (
      'nature', 'water', 'coast', 'culture',
      'wild', 'food', 'views', 'relax'
    )
  ),
  constraint interest_place_types_type_lower check (
    place_type = lower(btrim(place_type)) and place_type <> ''
  )
);

alter table public.interest_place_types enable row level security;

create policy "Anyone signed in can read interest place types"
  on public.interest_place_types
  for select
  to authenticated
  using (true);

insert into public.interest_place_types (interest_key, place_type) values
  ('nature', 'park'), ('nature', 'forest'), ('nature', 'reserve'),
  ('nature', 'garden'), ('nature', 'conservancy'),
  ('water', 'waterfall'), ('water', 'hike'), ('water', 'hiking'),
  ('water', 'trail'), ('water', 'gorge'), ('water', 'river'),
  ('coast', 'shore'), ('coast', 'beach'), ('coast', 'coast'),
  ('coast', 'island'),
  ('culture', 'culture'), ('culture', 'museum'), ('culture', 'heritage'),
  ('culture', 'historic'), ('culture', 'monument'),
  ('wild', 'park'), ('wild', 'wildlife'), ('wild', 'reserve'),
  ('wild', 'conservancy'), ('wild', 'sanctuary'),
  ('food', 'market'), ('food', 'restaurant'), ('food', 'food'),
  ('views', 'viewpoint'), ('views', 'view'), ('views', 'escarpment'),
  ('views', 'lookout'),
  ('relax', 'spring'), ('relax', 'hot_spring'), ('relax', 'lake'),
  ('relax', 'retreat'), ('relax', 'stay')
on conflict do nothing;

create or replace function public.for_you_candidates(
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
    select ST_SetSRID(
             ST_MakePoint(p_longitude, p_latitude), 4326
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
           ST_DistanceSphere(cc.centroid, cand.location) as distance_m
    from candidates cand, current_county cc
  ),
  nearest_per_county as (
    select distinct on (county_id)
           reason, county_id, place_id, distance_m
    from ranked_candidates
    order by county_id, distance_m asc
  ),
  my_interests as (
    select unnest(p.interests) as interest_key
    from public.profiles p
    where p.id = auth.uid()
  ),
  matching_counties as (
    select distinct pl.county_id
    from public.places pl
    join public.interest_place_types ipt on ipt.place_type = lower(pl.type)
    join my_interests mi on mi.interest_key = ipt.interest_key
  )
  select
    npc.reason, npc.county_id, npc.place_id, npc.distance_m,
    pl.name as place_name,
    pl.area_km2,
    pl.elevation_m,
    pl.visit_duration_minutes
  from nearest_per_county npc
  left join public.places pl on pl.id = npc.place_id
  order by
    npc.distance_m * case
      when exists (
        select 1 from matching_counties mc where mc.county_id = npc.county_id
      ) then 0.6
      else 1
    end asc
  limit 3;
$$;

revoke execute on function public.for_you_candidates(double precision, double precision) from public;
grant execute on function public.for_you_candidates(double precision, double precision) to authenticated;
