-- Map Home Module 3 ranking functions: doc 07's "For you" and "Side
-- Quests" queries, wrapped as Postgres functions so the Flutter app can
-- call them with a single supabase.rpc(...) instead of trying to express
-- a multi-CTE union query through PostgREST's fluent query builder.
--
-- Both read auth.uid() directly rather than taking a user id parameter --
-- every table they touch already has RLS scoping reads to auth.uid(), so
-- accepting a separate parameter would be redundant at best and a rough
-- edge at worst (a caller passing a different id wouldn't get someone
-- else's data anyway, since RLS still applies underneath, but there's no
-- reason to invite the question). `language sql stable` (not `security
-- definer`), so they run with the caller's own privileges and RLS intact.

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
  with current_county as (
    select v.county_id, c.centroid
    from public.county_visits v
    join public.counties c on c.id = v.county_id
    where v.user_id = auth.uid()
    order by v.entered_at desc
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

create or replace function public.side_quests_candidates()
returns table (
  quest_type text,
  quest_id uuid,
  anchor_county_id smallint,
  required_count integer,
  completed_count integer,
  deadline_at timestamptz,
  title text,
  remaining integer
)
language sql
stable
as $$
  with candidates as (
    -- personal nudges: a passed-through county not yet converted,
    -- repeated enough to be worth surfacing
    select 'personal'::text as quest_type, null::uuid as quest_id, v.county_id as anchor_county_id,
           1 as required_count, 0 as completed_count, null::timestamptz as deadline_at,
           'Finally stop in ' || c.name as title
    from public.county_visits v
    join public.counties c on c.id = v.county_id
    where v.user_id = auth.uid()
      and v.state = 'passed_through'
      and v.pass_count >= 3
      and not exists (
        select 1 from public.county_visits e
        where e.user_id = auth.uid() and e.county_id = v.county_id and e.state = 'explored'
      )

    union all

    -- editorial quests: authored, time-bound, one or more counties
    select 'seasonal', q.id, null,
           q.required_count, coalesce(p.completed_count, 0), q.ends_at, q.title
    from public.editorial_quests q
    left join public.editorial_quest_progress p
      on p.quest_id = q.id and p.user_id = auth.uid()
    where q.starts_at <= now() and q.ends_at >= now()
      and coalesce(p.completed_count, 0) < q.required_count

    union all

    -- collections: themed sets, no deadline
    select 'collection', col.id, null,
           col.required_count, coalesce(cp.completed_count, 0), null, col.title
    from public.collections col
    left join public.collection_progress cp
      on cp.collection_id = col.id and cp.user_id = auth.uid()
    where coalesce(cp.completed_count, 0) < col.required_count
  )
  select quest_type, quest_id, anchor_county_id, required_count, completed_count,
         deadline_at, title,
         (required_count - completed_count) as remaining
  from candidates
  order by remaining asc, deadline_at asc nulls last
  limit 3;
$$;

revoke execute on function public.side_quests_candidates() from public;
grant execute on function public.side_quests_candidates() to authenticated;
