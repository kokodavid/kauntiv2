-- The Badges gallery (board 11) needs a live depth rank per EXPLORED
-- county -- doc 02's 4-rung ladder (Passed through / Visited / Regular /
-- Local Expert) -- but nothing in the schema has ever computed one.
-- `county_depth_progress.rank` looks like the answer, except its only
-- writer anywhere is `dev_seed_user_progress()` (see that migration): a
-- real, pre-existing gap found while building Badges, not something this
-- migration silently works around. This function is the actual fix --
-- `SupabaseBadgesRepository.gallery()` calls it instead of reading that
-- stale table.
--
-- A second, narrower gap this function's comment flags rather than
-- hides: doc 02's exact thresholds are "3+ EXPLORED visits across 3+
-- distinct months" (regular) and "6+ EXPLORED visits across 5+ distinct
-- months" (local expert). `county_visits` doesn't have the per-visit
-- history that "distinct months" needs -- `record_county_visit()`
-- upserts a single row per (user, county), overwriting `entered_at` on
-- every visit and only ever bumping a running `pass_count` counter, with
-- no log of *when* each of those visits happened. So this function ranks
-- by `pass_count` alone (a real, if visit-history-free, doc 01 UI
-- placeholder in the seed script's own admission), because the
-- distinct-month check doc 02 specifies simply cannot be computed from
-- what the current schema retains. Recording per-visit timestamps (a new
-- `county_visit_events` table, most likely) is the real fix and a
-- follow-up, not something to fake here with a wrong answer that merely
-- looks plausible.
--
-- `security invoker` (the default) is enough -- `county_visits` already
-- has a `select` policy scoping every user to their own rows, so a plain
-- `where user_id = auth.uid()` is sufficient without `security definer`.
create or replace function public.county_depth_ranks()
returns table (county_id smallint, rank text)
language sql
stable
as $$
  select
    v.county_id,
    case
      when v.pass_count >= 6 then 'local_expert'
      when v.pass_count >= 3 then 'regular'
      else 'visitor'
    end as rank
  from public.county_visits v
  where v.user_id = auth.uid()
    and v.state = 'explored';
$$;

revoke execute on function public.county_depth_ranks() from public;
grant execute on function public.county_depth_ranks() to authenticated;
