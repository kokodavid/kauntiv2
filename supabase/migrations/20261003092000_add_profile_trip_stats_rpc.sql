-- Profile's progress card (doc 02) adds a Trips / km travelled / longest
-- Trip row alongside the county-claimed progress. `journeys.distance_m`
-- already has everything needed; this is a straight aggregate.
--
-- `security invoker` (the default) is enough -- `journeys` already has a
-- `select` policy scoping every user to their own rows (see
-- add_private_journeys.sql), so a plain `where user_id = auth.uid()` is
-- sufficient without `security definer`, matching county_depth_ranks().
create or replace function public.profile_trip_stats()
returns table (
  trip_count bigint,
  total_distance_m numeric,
  longest_distance_m numeric
)
language sql
stable
as $$
  select
    count(*),
    coalesce(sum(distance_m), 0),
    coalesce(max(distance_m), 0)
  from public.journeys
  where user_id = auth.uid();
$$;

revoke execute on function public.profile_trip_stats() from public;
grant execute on function public.profile_trip_stats() to authenticated;
