set search_path = extensions, public;

-- Interests, part 2.
--
-- 1. my_interest_matches(): for the signed-in user, one row per county
--    that holds a place matching one of their interests (see
--    interest_place_types), naming the place and the interest it matched.
--    Home uses it to lean the "Nearby and unclaimed" row toward matching
--    counties and to say why ("Because you like waterfalls"). When a
--    county has several matches the earlier pick wins, then name order.
-- 2. for_you_promotion(): after the anchor county's own promotions, a
--    promoted place that matches the user's interests now beats one that
--    does not, before distance and priority decide. Same return shape;
--    with no interests the order is exactly as before.

create or replace function public.my_interest_matches()
returns table (
  county_id smallint,
  place_id uuid,
  place_name text,
  interest_key text
)
language sql
stable
security invoker
set search_path = public
as $$
  select distinct on (pl.county_id)
         pl.county_id, pl.id, pl.name, mine.interest_key
  from public.profiles me
  cross join lateral unnest(me.interests)
    with ordinality as mine(interest_key, pick_order)
  join public.interest_place_types ipt
    on ipt.interest_key = mine.interest_key
  join public.places pl on lower(pl.type) = ipt.place_type
  where me.id = auth.uid()
  order by pl.county_id, mine.pick_order, pl.name;
$$;

revoke execute on function public.my_interest_matches() from public;
grant execute on function public.my_interest_matches() to authenticated;

create or replace function public.for_you_promotion(
  p_latitude double precision default null,
  p_longitude double precision default null
)
returns table (
  promotion_id uuid,
  place_id uuid,
  place_name text,
  county_id smallint,
  summary text,
  lat double precision,
  lng double precision,
  area_km2 numeric,
  elevation_m integer,
  visit_duration_minutes integer,
  image_url text,
  disclosure_label text,
  sponsor_name text,
  local_tier integer
)
language sql
volatile
security invoker
set search_path = public, extensions
as $$
  with live_county as (
    select c.id
    from public.counties c
    where p_latitude is not null
      and p_longitude is not null
      and ST_Contains(
        c.geometry,
        ST_SetSRID(
          ST_MakePoint(p_longitude, p_latitude), 4326
        )
      )
    limit 1
  ),
  last_visit as (
    select v.county_id as id
    from public.county_visits v
    where v.user_id = auth.uid()
    order by v.entered_at desc
    limit 1
  ),
  home as (
    select p.home_county_id as id
    from public.profiles p
    where p.id = auth.uid()
      and p.home_county_id is not null
  ),
  anchor as (
    select id from live_county
    union all
    select id from last_visit
    where not exists (select 1 from live_county)
    union all
    select id from home
    where not exists (select 1 from live_county)
      and not exists (select 1 from last_visit)
    limit 1
  ),
  candidates as (
    select
      pp.id as promotion_id,
      pp.priority,
      pp.disclosure_label,
      pp.sponsor_name,
      pl.id as place_id,
      pl.name as place_name,
      pl.county_id,
      pl.summary,
      pl.lat,
      pl.lng,
      pl.area_km2,
      pl.elevation_m,
      pl.visit_duration_minutes,
      ST_DistanceSphere(ac.centroid, pc.centroid) as county_distance_m,
      exists (
        select 1
        from public.profiles me
        cross join lateral unnest(me.interests) as mine(interest_key)
        join public.interest_place_types ipt
          on ipt.interest_key = mine.interest_key
        where me.id = auth.uid()
          and ipt.place_type = lower(pl.type)
      ) as matches_interest,
      case
        when a.id is null then 2
        when pl.county_id = a.id then 0
        when pl.county_id = any (ac.neighbor_codes) then 1
        else 2
      end as local_tier
    from public.place_promotions pp
    join public.places pl on pl.id = pp.place_id
    left join anchor a on true
    left join public.counties ac on ac.id = a.id
    join public.counties pc on pc.id = pl.county_id
    where pp.placement = 'for_you'
      and pp.deactivated_at is null
      and pp.starts_at <= now()
      and (pp.ends_at is null or pp.ends_at > now())
  )
  select
    c.promotion_id,
    c.place_id,
    c.place_name,
    c.county_id,
    c.summary,
    c.lat,
    c.lng,
    c.area_km2,
    c.elevation_m,
    c.visit_duration_minutes,
    (
      select pi.image_url
      from public.place_images pi
      where pi.place_id = c.place_id
      order by pi.sort_order asc
      limit 1
    ) as image_url,
    c.disclosure_label,
    c.sponsor_name,
    c.local_tier
  from candidates c
  order by
    c.local_tier = 0 desc,
    c.matches_interest desc,
    c.county_distance_m asc nulls last,
    c.priority desc,
    random()
  limit 1;
$$;

revoke execute on function public.for_you_promotion(double precision, double precision) from public;
grant execute on function public.for_you_promotion(double precision, double precision) to authenticated;
