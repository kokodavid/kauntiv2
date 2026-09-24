-- Picks the one promoted place for Home's For You slot.
--
-- Several `for_you` promotions can be active at once, but Home shows a
-- single ad card. Order of preference:
--   1. Local first (doc 04: targeting is county-level only). The anchor
--      county is the county containing the live foreground fix when the
--      app passes one, else the traveller's last visited county, else
--      their home county. A place in the anchor county beats one in a
--      neighbouring county, which beats one anywhere else. The fix is only
--      used for this lookup and is never stored (doc 05).
--   2. Higher `priority`.
--   3. Ties take turns: random() per call, so equally ranked advertisers
--      share the slot across loads. Once impressions are recorded this can
--      favour the least-seen promotion instead.
--
-- Security invoker: the place_promotions RLS policy already limits rows to
-- active promotions inside their start/end window; the same filter is
-- repeated here so the intent is explicit.

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
  order by c.local_tier asc, c.priority desc, random()
  limit 1;
$$;

revoke execute on function public.for_you_promotion(double precision, double precision) from public;
grant execute on function public.for_you_promotion(double precision, double precision) to authenticated;
