-- Place type audit. READ ONLY: run each block on its own in the Supabase SQL
-- editor (dev first, then prod). Works before and after the place_types
-- migration; it does not depend on any new table.
--
-- Goal: see what the places really are, so the type list and the interest
-- groups can be fixed from data, not guesses.

-- A. What types exist today and how many places use each -------------------
select type, count(*) as places
from public.places
where archived_at is null
group by type
order by places desc, type;

-- B. Coastal counties (the only counties that may carry the Coast group) ---
select id, name, is_coastal from public.counties where is_coastal order by name;

-- C. Every place with its county, coordinates and a keyword-based suggestion.
-- "suggested" reads the NAME only. It is a hint to check, not an answer.
with p as (
  select
    pl.id, c.name as county, c.is_coastal, pl.name, pl.type,
    pl.lat, pl.lng, pl.status,
    lower(pl.name) as n
  from public.places pl
  join public.counties c on c.id = pl.county_id
  where pl.archived_at is null
)
select
  county, name, type, is_coastal, status,
  case
    when n ~ '(waterfall|falls)\M' then 'waterfall'
    when n ~ '\m(marine)\M' then 'marine_park'
    when n ~ '\m(island|isle)\M' then 'island'
    when n ~ '\m(beach|shore)\M' then 'beach'
    when n ~ '\m(hot spring|hot springs|geyser)\M' or n ~ 'springs?\M' then 'hot_spring'
    when n ~ '\mlake\M|\mdam\M|reservoir' then 'lake'
    when n ~ '\mriver\M|gorge|rapids' then 'river'
    when n ~ '\m(mt|mount|mountain|peak|hills?|crater|volcano)\M' then 'mountain'
    when n ~ '\m(escarpment|viewpoint|view point|lookout|plateau)\M' then 'viewpoint'
    when n ~ '\mcaves?\M' then 'cave'
    when n ~ '\m(desert|dunes?)\M' then 'desert'
    when n ~ 'forest|woodland' then 'forest'
    when n ~ 'conservancy|sanctuary|reserve' then 'conservancy_or_park'
    when n ~ 'national park|\mpark\M' then 'park'
    when n ~ 'garden|arboretum' then 'garden'
    when n ~ 'museum' then 'museum'
    when n ~ '\m(fort|ruins|memorial|monument|statue|heritage)\M' then 'historic_or_monument'
    when n ~ 'market' then 'market'
    when n ~ '\m(hotel|lodge|camp|resort|retreat)\M' then 'stay'
    else null
  end as name_suggests,
  lat, lng
from p
order by county, type, name;

-- D. Disagreements: the name points one way, the stored type another -------
-- (reuses block C; run it as one statement)
with p as (
  select c.name as county, pl.name, pl.type, lower(pl.name) as n
  from public.places pl
  join public.counties c on c.id = pl.county_id
  where pl.archived_at is null
), s as (
  select *,
    case
      when n ~ '(waterfall|falls)\M' then 'waterfall'
      when n ~ '\mmarine\M' then 'marine_park'
      when n ~ '\m(island|isle)\M' then 'island'
      when n ~ '\m(beach|shore)\M' then 'beach'
      when n ~ 'springs?\M' then 'hot_spring'
      when n ~ '\mlake\M|\mdam\M|reservoir' then 'lake'
      when n ~ '\mriver\M|gorge|rapids' then 'river'
      when n ~ '\m(mt|mount|mountain|peak|hills?|crater|volcano)\M' then 'mountain'
      when n ~ '\mcaves?\M' then 'cave'
      when n ~ '\m(desert|dunes?)\M' then 'desert'
      when n ~ 'forest|woodland' then 'forest'
      when n ~ 'garden|arboretum' then 'garden'
      when n ~ 'museum' then 'museum'
      when n ~ 'market' then 'market'
    end as name_suggests
  from p
)
select county, name, type as stored_type, name_suggests
from s
where name_suggests is not null
  and replace(lower(type), ' ', '_') <> name_suggests
order by name_suggests, county, name;

-- E. Coast problems: coastal-style types in counties that are NOT coastal ---
-- Beach / island / marine park / coast belong to the five coastal counties.
-- Anything listed here is either a lake shore (should be a lake or a beach
-- on a lake) or a wrong county / wrong type.
select c.name as county, pl.name, pl.type
from public.places pl
join public.counties c on c.id = pl.county_id
where pl.archived_at is null
  and not c.is_coastal
  and lower(pl.type) in ('beach', 'island', 'marine_park', 'marine park',
                         'coast', 'shore', 'shores', 'beaches', 'islands')
order by c.name, pl.name;

-- F. The reverse: coastal counties with places that are not coast-like ------
select c.name as county, pl.type, count(*) as places
from public.places pl
join public.counties c on c.id = pl.county_id
where pl.archived_at is null and c.is_coastal
group by c.name, pl.type
order by c.name, places desc;

-- G. Water group check: lakes, hot springs, rivers and where they sit -------
select c.name as county, c.is_coastal, pl.type, count(*) as places,
       string_agg(pl.name, ', ' order by pl.name) as names
from public.places pl
join public.counties c on c.id = pl.county_id
where pl.archived_at is null
  and lower(replace(pl.type, '_', ' ')) in
      ('lake', 'lakes', 'river', 'rivers', 'hot spring', 'hot springs',
       'waterfall', 'waterfalls', 'dam', 'spring', 'springs')
group by c.name, c.is_coastal, pl.type
order by pl.type, c.name;

-- H. Places that cannot be placed with confidence --------------------------
-- No keyword in the name AND a vague stored type. These need a human
-- decision (open the description / image) before the migration maps them.
select c.name as county, pl.name, pl.type, left(pl.summary, 90) as summary
from public.places pl
join public.counties c on c.id = pl.county_id
where pl.archived_at is null
  and lower(btrim(pl.type)) in
      ('nature', 'energy', 'pool', 'culture', 'heritage', 'retreat',
       'view', 'views', 'park', 'reserve', 'other', '')
order by pl.type, c.name, pl.name;

-- I. Descriptions that mention a type word the stored type does not match ---
-- Catches names that hide the type ("Ngurunit", "Paradise Lost").
select c.name as county, pl.name, pl.type,
  concat_ws(', ',
    case when d ~ 'waterfall' then 'waterfall' end,
    case when d ~ 'hot spring|geothermal' then 'hot spring' end,
    case when d ~ '\mlake\M' then 'lake' end,
    case when d ~ '\mriver\M|gorge' then 'river' end,
    case when d ~ '\mcave' then 'cave' end,
    case when d ~ 'beach|coral|\mreef\M' then 'beach/coast' end,
    case when d ~ 'museum' then 'museum' end,
    case when d ~ 'viewpoint|panoram' then 'view' end,
    case when d ~ 'hik(e|ing)|trail' then 'hike' end,
    case when d ~ 'wildlife|game|safari' then 'wildlife' end
  ) as description_mentions
from (
  select pl2.*, lower(coalesce(pl2.description, pl2.summary, '')) as d
  from public.places pl2 where pl2.archived_at is null
) pl
join public.counties c on c.id = pl.county_id
where pl.d <> ''
order by c.name, pl.name;
