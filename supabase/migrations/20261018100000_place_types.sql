set search_path = extensions, public;

-- One fixed list of place types.
--
-- places.type was free text typed in the dashboard, so the same idea was
-- stored as "hike", "hiking" and "trail", the app grouped everything into six
-- categories and showed anything it did not recognise as Culture. This
-- migration:
--   1. adds place_types (the list) and place_type_aliases (old spellings),
--   2. rewrites every existing places.type to its canonical key,
--   3. stops with a list of any type it cannot map (nothing is guessed),
--   4. makes places.type a foreign key to place_types,
--   5. adds a trigger that maps known spellings on insert/update, so the
--      current dashboard, imports and the scraper keep working, and gives a
--      clear error for anything unknown,
--   6. rebuilds interest_place_types on the canonical keys.
--
-- Keep the list in step with lib/src/core/domain/place_type.dart.
--
-- Before running on an environment, check what it holds:
--   select type, count(*) from public.places group by type order by 2 desc;
-- Add any missing spelling to the alias insert below.

-- 1. The list ---------------------------------------------------------------
create table if not exists public.place_types (
  key text primary key,
  label text not null,
  plural_label text not null,
  icon text not null,
  sort_order integer not null,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  constraint place_types_key_format check (key ~ '^[a-z][a-z_]*[a-z]$')
);

comment on table public.place_types is
  'The fixed list of place kinds. places.type references key. Mirrors lib/src/core/domain/place_type.dart in the app.';

insert into public.place_types (key, label, plural_label, icon, sort_order) values
  ('waterfall', 'Waterfall', 'Waterfalls', 'water_drop', 10),
  ('hike', 'Hike', 'Hikes', 'hiking', 20),
  ('mountain', 'Mountain', 'Mountains', 'landscape', 30),
  ('viewpoint', 'Viewpoint', 'Views', 'visibility', 40),
  ('beach', 'Beach', 'Beaches', 'beach_access', 50),
  ('island', 'Island', 'Islands', 'sailing', 60),
  ('marine_park', 'Marine park', 'Marine parks', 'scuba_diving', 65),
  ('lake', 'Lake', 'Lakes', 'water', 70),
  ('river', 'River', 'Rivers', 'kayaking', 80),
  ('hot_spring', 'Hot spring', 'Hot springs', 'hot_tub', 90),
  ('park', 'Park', 'Parks', 'park', 100),
  ('conservancy', 'Conservancy', 'Conservancies', 'pets', 110),
  ('forest', 'Forest', 'Forests', 'forest', 120),
  ('cave', 'Cave', 'Caves', 'terrain', 130),
  ('desert', 'Desert', 'Deserts', 'wb_sunny', 135),
  ('garden', 'Garden', 'Gardens', 'local_florist', 140),
  ('museum', 'Museum', 'Museums', 'museum', 150),
  ('historic_site', 'Historic site', 'Historic sites', 'fort', 160),
  ('monument', 'Monument', 'Monuments', 'account_balance', 170),
  ('landmark', 'Landmark', 'Landmarks', 'tour', 175),
  ('cultural_site', 'Cultural site', 'Culture', 'theater_comedy', 180),
  ('market', 'Market', 'Markets', 'storefront', 190),
  ('food', 'Food spot', 'Food', 'restaurant', 200),
  ('stay', 'Stay', 'Stays', 'hotel', 210)
on conflict (key) do nothing;

-- 2. Old spellings ----------------------------------------------------------
-- alias is normalised: lower case, single spaces, no _ or -.
create table if not exists public.place_type_aliases (
  alias text primary key,
  place_type text not null references public.place_types (key) on update cascade,
  constraint place_type_aliases_normalised check (
    alias = regexp_replace(lower(btrim(alias)), '[\s_-]+', ' ', 'g') and alias <> ''
  )
);

insert into public.place_type_aliases (alias, place_type) values
  ('waterfalls', 'waterfall'), ('falls', 'waterfall'), ('fall', 'waterfall'),
  ('hiking', 'hike'), ('trail', 'hike'), ('trails', 'hike'),
  ('hiking trail', 'hike'), ('nature trail', 'hike'), ('walk', 'hike'),
  ('nature walk', 'hike'),
  ('peak', 'mountain'), ('hill', 'mountain'), ('hills', 'mountain'),
  ('mount', 'mountain'), ('crater', 'mountain'), ('volcano', 'mountain'),
  ('view', 'viewpoint'), ('views', 'viewpoint'), ('view point', 'viewpoint'),
  ('lookout', 'viewpoint'), ('escarpment', 'viewpoint'),
  ('coast', 'beach'), ('beaches', 'beach'),
  ('islands', 'island'),
  ('dam', 'lake'), ('reservoir', 'lake'), ('lakes', 'lake'),
  ('gorge', 'river'), ('rapids', 'river'), ('rivers', 'river'),
  ('hot springs', 'hot_spring'), ('spring', 'hot_spring'),
  ('springs', 'hot_spring'), ('geyser', 'hot_spring'),
  ('national park', 'park'), ('national reserve', 'park'),
  ('reserve', 'park'), ('game reserve', 'park'), ('parks', 'park'),
  ('sanctuary', 'conservancy'), ('wildlife', 'conservancy'),
  ('wildlife sanctuary', 'conservancy'),
  ('forest reserve', 'forest'), ('woodland', 'forest'), ('forests', 'forest'),
  ('caves', 'cave'), ('lava cave', 'cave'),
  ('marine park', 'marine_park'), ('marine national park', 'marine_park'),
  ('marine reserve', 'marine_park'),
  ('deserts', 'desert'), ('dunes', 'desert'), ('sand dunes', 'desert'),
  ('landmarks', 'landmark'), ('wind farm', 'landmark'),
  ('arboretum', 'garden'), ('botanical garden', 'garden'), ('gardens', 'garden'),
  ('museums', 'museum'),
  ('heritage', 'historic_site'), ('historic', 'historic_site'),
  ('heritage site', 'historic_site'), ('ruins', 'historic_site'),
  ('fort', 'historic_site'),
  ('memorial', 'monument'), ('statue', 'monument'),
  ('culture', 'cultural_site'), ('cultural', 'cultural_site'),
  ('cultural centre', 'cultural_site'), ('cultural center', 'cultural_site'),
  ('shrine', 'cultural_site'),
  ('markets', 'market'),
  ('eat', 'food'), ('restaurant', 'food'), ('cafe', 'food'),
  ('vineyard', 'food'), ('winery', 'food'),
  ('retreat', 'stay'), ('hotel', 'stay'), ('lodge', 'stay'), ('camp', 'stay'),
  ('campsite', 'stay'), ('camping', 'stay'), ('resort', 'stay')
on conflict (alias) do nothing;

alter table public.place_types enable row level security;
alter table public.place_type_aliases enable row level security;

drop policy if exists "Anyone signed in can read place types" on public.place_types;
create policy "Anyone signed in can read place types"
  on public.place_types for select to authenticated using (true);

drop policy if exists "Anyone signed in can read place type aliases" on public.place_type_aliases;
create policy "Anyone signed in can read place type aliases"
  on public.place_type_aliases for select to authenticated using (true);

grant select on public.place_types, public.place_type_aliases to authenticated;

-- 3. Resolver ---------------------------------------------------------------
-- Canonical key for any spelling, or null when it is not on the list.
create or replace function public.resolve_place_type(p_raw text)
returns text
language sql
stable
set search_path = public
as $$
  with n as (
    select regexp_replace(lower(btrim(coalesce(p_raw, ''))), '[\s_-]+', ' ', 'g') as v
  )
  select coalesce(
    (select t.key from public.place_types t, n where replace(t.key, '_', ' ') = n.v),
    (select a.place_type from public.place_type_aliases a, n where a.alias = n.v)
  );
$$;

grant execute on function public.resolve_place_type(text) to authenticated;

-- 4. Rewrite existing rows, then refuse anything unmapped -------------------
-- Vague or misleading old values ("nature", "energy", "pool", "desert",
-- "shore", and a few "culture", "heritage", "park", "waterfall" rows) are
-- assigned place by place (prod list, 2026-10-15 and 2026-10-16). Any other
-- place still carrying one of the vague values is read by the aliases above
-- or stops the migration below.
update public.places p
set type = fix.place_type
from (values
  ('Chalbi Desert', 'desert'),
  ('North Horr Sun Dunes', 'desert'),
  ('Lake Turkana Windmills', 'landmark'),
  ('Ngurunit', 'river'),
  ('Crater Lake Game Sanctuary', 'conservancy'),
  ('Elephant Hill', 'mountain'),
  ('Kapsimotwa Gardens', 'garden'),
  ('Karura Forest', 'forest'),
  ('Kereita Forest', 'forest'),
  ('Lake Alice', 'lake'),
  ('Lake Paradise', 'lake'),
  ('Mathews Range Forest Reserve', 'forest'),
  ('Mayers Estate', 'historic_site'),
  ('Mount Ololokwe', 'mountain'),
  ('Mt Kulal', 'mountain'),
  ('Nairobi Arboretum', 'garden'),
  ('Nasuulu Community Conservancy', 'conservancy'),
  ('Ndoto Conservancy', 'conservancy'),
  ('Ngong Hills', 'mountain'),
  ('Paradise Lost', 'park'),
  ('Swara Plains Conservancy', 'conservancy'),
  ('Taita Hills', 'mountain'),
  ('Wasini Island', 'island'),
  ('Yatta Plateau', 'viewpoint'),
  ('Kipepeo Butterfly Project', 'conservancy'),
  -- "shore" was used for lake shores, creeks and springs, so it is no longer
  -- an alias for beach. Each one is placed by hand (audit 2026-10-16).
  ('Takawiri Island', 'island'),
  ('Lake Ol Bolossat', 'lake'),
  ('Mida Creek', 'beach'),
  ('Mambrui dunes', 'beach'),
  ('Sabaki River Mouth', 'river'),
  ('Nyakanja Spring', 'river'),
  ('Turtle beach Watamu', 'beach'),
  -- "culture" was a catch-all.
  ('Marafa Hells Kitchen', 'viewpoint'),
  ('Mount Kipipiri', 'mountain'),
  ('Koobi Fora', 'historic_site'),
  ('Namoratunga', 'historic_site'),
  ('Chesowanja', 'historic_site'),
  ('Ruins of Gedi', 'historic_site'),
  ('Karsa, Kenya', 'cultural_site'),
  ('Kazuri Beads Centre', 'cultural_site'),
  ('Vasco da Gama Pillar', 'monument'),
  -- Wildlife places stored as "park".
  ('Ol Pejeta Conservancy', 'conservancy'),
  ('Kigio Wildlife Conservancy', 'conservancy'),
  ('Nguuni Nature Sanctuary', 'conservancy'),
  ('Taita Hills Wildlife Sanctuary', 'conservancy'),
  ('Haller Park', 'conservancy'),
  ('Kathandeini Forest', 'forest'),
  -- Added to prod after the first audit (2026-10-16).
  ('Ol Jogi Wildlife Conservancy', 'conservancy'),
  ('William Holden Wildlife Education Centre', 'conservancy'),
  ('Wine & Spine', 'market')
) as fix (name, place_type)
where p.name = fix.name
  and lower(btrim(p.type)) in (
    'nature', 'energy', 'pool', 'desert', 'shore', 'culture', 'heritage',
    'park', 'waterfall', 'shop'
  );

update public.places
set type = public.resolve_place_type(type)
where public.resolve_place_type(type) is not null
  and public.resolve_place_type(type) <> type;

do $$
declare
  v_unmapped text;
begin
  select string_agg(format('%L (%s)', type, n), ', ' order by n desc)
  into v_unmapped
  from (
    select type, count(*) as n
    from public.places
    where type not in (select key from public.place_types)
    group by type
  ) unmapped;

  if v_unmapped is not null then
    raise exception 'Unmapped place types: %. Add them to place_type_aliases in this migration and run it again.', v_unmapped;
  end if;
end;
$$;

alter table public.places
  drop constraint if exists places_type_fkey;
alter table public.places
  add constraint places_type_fkey
  foreign key (type) references public.place_types (key) on update cascade;

create index if not exists places_type_idx on public.places (type);

-- 5. Map known spellings on write -------------------------------------------
create or replace function public.places_normalise_type()
returns trigger
language plpgsql
set search_path = public
as $$
declare
  v_key text;
begin
  v_key := public.resolve_place_type(new.type);
  if v_key is null then
    raise exception 'Unknown place type "%". Choose one of the place types on the list.', new.type
      using errcode = '23503';
  end if;
  new.type := v_key;
  return new;
end;
$$;

drop trigger if exists places_normalise_type on public.places;
create trigger places_normalise_type
  before insert or update of type on public.places
  for each row execute function public.places_normalise_type();

-- 6. Interests on canonical keys --------------------------------------------
-- Old rows use raw spellings; drop any that are not on the list. The final
-- interest -> type mapping is written by 20261018130000_interests_table.sql.
delete from public.interest_place_types
where place_type not in (select key from public.place_types);

alter table public.interest_place_types
  drop constraint if exists interest_place_types_place_type_fkey;
alter table public.interest_place_types
  add constraint interest_place_types_place_type_fkey
  foreign key (place_type) references public.place_types (key) on update cascade;
