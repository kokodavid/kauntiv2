-- Explore (Field Guide v2) "All 47 claimed" state: the headline names the
-- last county visited and the "Go back" chapter lists counties by how long
-- ago the traveller was there. `entered_at` on county_visits is the first
-- entry; the most recent visit lives in county_visit_events.
--
-- The return type gains a column, so the function is dropped and recreated.
-- Run on dev first; prod after the app build that reads `last_visited_at`
-- ships (the app treats a missing column as "no date").

drop function if exists public.discover_mine_counties();

create function public.discover_mine_counties()
returns table (
  county_id smallint,
  state text,
  rank text,
  pass_count integer,
  entered_at timestamptz,
  last_visited_at timestamptz
)
language sql
stable
as $$
  select v.county_id, v.state, coalesce(p.rank, 'visitor') as rank,
         v.pass_count, v.entered_at,
         (
           select max(e.entered_at)
           from public.county_visit_events e
           where e.user_id = v.user_id and e.county_id = v.county_id
         ) as last_visited_at
  from public.county_visits v
  left join public.county_depth_progress p
    on p.user_id = v.user_id and p.county_id = v.county_id
  where v.user_id = auth.uid()
    and v.state in ('explored', 'passed_through')
  order by v.entered_at desc;
$$;

revoke execute on function public.discover_mine_counties() from public;
grant execute on function public.discover_mine_counties() to authenticated;
