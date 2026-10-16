set search_path = extensions, public;

-- Interests move to the backend.
--
-- Until now the list of interests (nature, water, coast ...) lived in the app
-- and in two check constraints, so adding one meant an app release. This
-- migration:
--   1. adds public.interests (key, label, short name, icon name, optional
--      icon image, order, active). The app renders whatever is active.
--   2. replaces the fixed-key checks on interest_place_types and
--      profiles.interests with a foreign key / a trigger that reads the table.
--   3. adds interest_place_types.is_primary (the type's home interest; the
--      app shows a place once, under the first matching interest) and
--      county_scope ('any', 'coastal' or 'inland': whether the link counts
--      only in counties with is_coastal, or only in those without).
--   4. rewrites the mapping: Coast is beach / island / marine park in the
--      coastal counties only, Water takes lakes and hot springs, hikes move
--      to the new Activities interest.
--   5. re-creates the three ranking functions so they honour county_scope.
--
-- Run place_types (20261018100000) first. Dev before prod.

-- 1. The list ---------------------------------------------------------------
create table if not exists public.interests (
  key text primary key,
  label text not null,
  short_name text not null,
  icon_name text not null default 'place',
  icon_url text,
  sort_order integer not null default 100,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  constraint interests_key_format check (key ~ '^[a-z][a-z_]*[a-z]$')
);

comment on column public.interests.icon_name is
  'Name looked up in the app''s icon list; unknown names show a default icon.';
comment on column public.interests.icon_url is
  'Optional image (SVG or PNG) in storage. When set the app shows it instead of icon_name.';

insert into public.interests (key, label, short_name, icon_name, sort_order) values
  ('nature', 'Nature and parks', 'parks', 'park', 10),
  ('water', 'Lakes, rivers and waterfalls', 'lakes and waterfalls', 'water_drop', 20),
  ('activities', 'Hikes and activities', 'hikes', 'hiking', 30),
  ('coast', 'Beaches and coast', 'coast', 'beach_access', 40),
  ('culture', 'Culture and history', 'heritage sites', 'museum', 50),
  ('wild', 'Wildlife', 'wildlife', 'pets', 60),
  ('food', 'Food and markets', 'markets', 'restaurant', 70),
  ('views', 'Views and viewpoints', 'viewpoints', 'visibility', 80),
  ('relax', 'Relaxing spots', 'quiet spots', 'spa', 90)
on conflict (key) do nothing;

alter table public.interests enable row level security;
drop policy if exists "Anyone signed in can read interests" on public.interests;
create policy "Anyone signed in can read interests"
  on public.interests for select to authenticated using (true);
grant select on public.interests to authenticated;

-- 2. Checks that read the table ---------------------------------------------
alter table public.interest_place_types
  drop constraint if exists interest_place_types_key_known;
alter table public.interest_place_types
  drop constraint if exists interest_place_types_interest_fkey;
alter table public.interest_place_types
  add constraint interest_place_types_interest_fkey
  foreign key (interest_key) references public.interests (key)
  on update cascade on delete cascade;

alter table public.profiles drop constraint if exists profiles_interests_known;

create or replace function public.profiles_check_interests()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if exists (
    select 1 from unnest(new.interests) as k
    where k not in (select key from public.interests)
  ) then
    raise exception 'Unknown interest in profiles.interests'
      using errcode = '23514';
  end if;
  return new;
end;
$$;

drop trigger if exists profiles_check_interests on public.profiles;
create trigger profiles_check_interests
  before insert or update of interests on public.profiles
  for each row execute function public.profiles_check_interests();

-- 3. Link flags --------------------------------------------------------------
alter table public.interest_place_types
  add column if not exists is_primary boolean not null default false,
  add column if not exists county_scope text not null default 'any';

alter table public.interest_place_types
  drop constraint if exists interest_place_types_scope_check;
alter table public.interest_place_types
  add constraint interest_place_types_scope_check
  check (county_scope in ('any', 'coastal', 'inland'));

create or replace function public.interest_applies(
  p_scope text,
  p_county smallint
)
returns boolean
language sql
stable
set search_path = public
as $$
  select case coalesce(p_scope, 'any')
    when 'coastal' then exists (
      select 1 from public.counties c where c.id = p_county and c.is_coastal)
    when 'inland' then not exists (
      select 1 from public.counties c where c.id = p_county and c.is_coastal)
    else true
  end;
$$;

grant execute on function public.interest_applies(text, smallint) to authenticated;

-- 4. The mapping -------------------------------------------------------------
-- is_primary: the type's home interest. Extras let a filter find the type
-- under a second interest; the app never lists the same place twice.
delete from public.interest_place_types where true;

insert into public.interest_place_types
  (interest_key, place_type, is_primary, county_scope) values
  ('nature', 'park', true, 'any'), ('nature', 'forest', true, 'any'),
  ('nature', 'garden', true, 'any'), ('nature', 'cave', true, 'any'),
  ('nature', 'mountain', true, 'any'),
  ('water', 'waterfall', true, 'any'), ('water', 'lake', true, 'any'),
  ('water', 'river', true, 'any'), ('water', 'hot_spring', true, 'any'),
  -- Islands and beaches on lakes (Central Island, Crescent Island,
  -- Takawiri) belong to Water, never to Coast.
  ('water', 'island', true, 'inland'), ('water', 'beach', true, 'inland'),
  ('activities', 'hike', true, 'any'),
  ('coast', 'beach', true, 'coastal'), ('coast', 'island', true, 'coastal'),
  ('coast', 'marine_park', true, 'coastal'),
  ('culture', 'museum', true, 'any'), ('culture', 'historic_site', true, 'any'),
  ('culture', 'monument', true, 'any'), ('culture', 'cultural_site', true, 'any'),
  ('culture', 'landmark', true, 'any'),
  ('wild', 'conservancy', true, 'any'), ('wild', 'park', false, 'any'),
  ('food', 'market', true, 'any'), ('food', 'food', true, 'any'),
  ('views', 'viewpoint', true, 'any'), ('views', 'desert', true, 'any'),
  ('views', 'mountain', false, 'any'),
  ('relax', 'stay', true, 'any'), ('relax', 'hot_spring', false, 'any'),
  ('relax', 'lake', false, 'any');

-- 5. Ranking functions honour county_scope -----------------------------------
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
  join public.places pl
    on lower(pl.type) = ipt.place_type
   and public.interest_applies(ipt.county_scope, pl.county_id)
  where me.id = auth.uid()
  order by pl.county_id, mine.pick_order, pl.name;
$$;

revoke execute on function public.my_interest_matches() from public;
grant execute on function public.my_interest_matches() to authenticated;

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
    join public.interest_place_types ipt
      on ipt.place_type = lower(pl.type)
     and public.interest_applies(ipt.county_scope, pl.county_id)
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
          and public.interest_applies(ipt.county_scope, pl.county_id)
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
