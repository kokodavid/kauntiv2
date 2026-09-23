-- Make manual SQL verification ergonomic. The canonical RPC takes smallint
-- because county ids are 1-47, but Postgres infers a bare literal like `32` as
-- integer and will not resolve it to the smallint overload automatically.
create or replace function public.county_season_leaderboard(
  p_county_id integer,
  p_segment text default 'visitors',
  p_limit integer default 50,
  p_season_id uuid default null
)
returns table (
  user_id uuid,
  rank_position bigint,
  visits bigint,
  segment text,
  field_size bigint,
  is_current_user boolean
)
language sql
stable
security definer
set search_path = public, extensions
as $$
  select *
  from public.county_season_leaderboard(
    p_county_id::smallint,
    p_segment,
    p_limit,
    p_season_id
  );
$$;

revoke execute on function public.county_season_leaderboard(integer, text, integer, uuid) from public;
grant execute on function public.county_season_leaderboard(integer, text, integer, uuid) to authenticated;
