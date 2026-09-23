-- Discover & Wishlist Module 2: the two queries backing
-- lib/src/features/discover/data/discover_repository.dart's
-- SupabaseDiscoverRepository -- MINE's county list and UNCLAIMED's
-- sortable list. Same posture as doc 07's for_you_candidates()/
-- side_quests_candidates()
-- (supabase/migrations/20260902150058_map_home_ranking_functions.sql):
-- `language sql stable`, no `security definer`, reading auth.uid()
-- directly rather than taking a parameter, since every table touched
-- already has RLS scoping reads to auth.uid() -- these functions add no
-- privilege beyond what the caller already has, just a single
-- supabase.rpc(...) instead of a client-side multi-query dance.
--
-- Place lists/counts and the Wishlist grouping are done client-side
-- against the (currently ~120-row) `places` table and `wishlist_items`
-- directly -- small enough that a dedicated function would be premature.

create or replace function public.discover_mine_counties()
returns table (
  county_id smallint,
  state text,
  rank text,
  pass_count integer,
  entered_at timestamptz
)
language sql
stable
as $$
  select v.county_id, v.state, coalesce(p.rank, 'visitor') as rank,
         v.pass_count, v.entered_at
  from public.county_visits v
  left join public.county_depth_progress p
    on p.user_id = v.user_id and p.county_id = v.county_id
  where v.user_id = auth.uid()
    and v.state in ('explored', 'passed_through')
  order by v.entered_at desc;
$$;

revoke execute on function public.discover_mine_counties() from public;
grant execute on function public.discover_mine_counties() to authenticated;

-- Every county the caller has no EXPLORED visit for, with a straight-line
-- distance from wherever `for_you_candidates()` would anchor from (last
-- visited county, falling back to the home county's centroid -- see
-- that function and the 2026-09-03 for_you_candidates() migration for
-- why) and whatever `counties.rarity_pct` currently holds. rarity_pct is
-- null for every county until a real computation job runs against real
-- badge holders (see supabase/migrations/20260902160000_seed_counties.sql)
-- -- this function passes that null straight through rather than
-- inventing a number; the Dart side is the layer that decides how to
-- render "rarity not known yet".
create or replace function public.discover_unclaimed_counties()
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
    select county_id, centroid from visited_current_county
    union all
    select p.home_county_id, c.centroid
    from public.profiles p
    join public.counties c on c.id = p.home_county_id
    where p.id = auth.uid()
      and p.home_county_id is not null
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

revoke execute on function public.discover_unclaimed_counties() from public;
grant execute on function public.discover_unclaimed_counties() to authenticated;
