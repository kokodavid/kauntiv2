-- PostgREST/Supabase RPC routing is not reliable with overloaded function
-- names. Keep `county_season_leaderboard(...)` for SQL compatibility, but give
-- the Flutter app a unique wrapper name so the Ranks page can call it without
-- ambiguity.
create or replace function public.county_season_leaderboard_for_code(
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

revoke execute on function public.county_season_leaderboard_for_code(integer, text, integer, uuid) from public;
grant execute on function public.county_season_leaderboard_for_code(integer, text, integer, uuid) to authenticated;
