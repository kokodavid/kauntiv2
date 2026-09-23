-- Fixes for_you_candidates() for a genuinely brand-new user: doc 07
-- defines "current county" as the user's most recent county_visits
-- row, but a user who just finished onboarding has none yet -- no
-- ENTER has resolved to a real visit. Without a fallback, the query's
-- `current_county` CTE returned zero rows and the final join produced
-- nothing, so "For You" silently showed no suggestions at all for
-- every user until their very first badge or pass-through resolved --
-- exactly the moment doc 01's "First open" board most wants to show a
-- concrete next move.
--
-- Falls back to the self-declared home county's centroid only when no
-- real visit exists yet; a real visit always takes precedence once one
-- exists. Everything else about the function (candidate pool, ranking,
-- limit 3) is unchanged.
create or replace function public.for_you_candidates()
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
    select county_id, centroid from visited_current_county
    union all
    select p.home_county_id, c.centroid
    from public.profiles p
    join public.counties c on c.id = p.home_county_id
    where p.id = auth.uid()
      and p.home_county_id is not null
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

revoke execute on function public.for_you_candidates() from public;
grant execute on function public.for_you_candidates() to authenticated;
