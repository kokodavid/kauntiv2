-- Nearest county first for the For You promotion picker.
--
-- 20260924150000 ranked promotions in three tiers (anchor county,
-- neighbouring county, everywhere else). Every non-neighbouring county was
-- treated as equally far, so from Murang'a a Turkana ad could tie with a
-- Nairobi one and win the random pick.
--
-- Now: the anchor county's own promotions first, then by the distance
-- between the anchor county's centroid and the promoted place's county
-- centroid, then priority, then random among ties. Distance is county to
-- county, never from the traveller's exact position (doc 04: targeting is
-- county-level only). `local_tier` is kept as an informational column.

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
set search_path = public
as $$
  with live_county as (
    select c.id
    from public.counties c
    where p_latitude is not null
      and p_longitude is not null
      and extensions.ST_Contains(
        c.geometry,
        extensions.ST_SetSRID(
          extensions.ST_MakePoint(p_longitude, p_latitude), 4326
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
      extensions.ST_DistanceSphere(ac.centroid, pc.centroid) as county_distance_m,
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
    c.county_distance_m asc nulls last,
    c.priority desc,
    random()
  limit 1;
$$;

revoke execute on function public.for_you_promotion(double precision, double precision) from public;
grant execute on function public.for_you_promotion(double precision, double precision) to authenticated;
