-- Module 4: the single write path for a resolved visit (EXPLORED or
-- PASSED_THROUGH) reaching Supabase. `data/visit_sync_queue.dart` calls
-- this once per queued op, rather than the client doing its own
-- read-then-write -- an RPC function makes the "does a row already
-- exist for this county, and how should this new visit merge into it"
-- logic atomic, the same reason for_you_candidates()/
-- side_quests_candidates() were wrapped as functions rather than done
-- client-side.
--
-- Merge rules:
--   - No existing row for this county: insert one. confirmed_at is set
--     immediately for an EXPLORED outcome (there's no separate
--     confirmation step beyond "the sync reached the server") and left
--     null for PASSED_THROUGH.
--   - Existing row already EXPLORED: a return visit. Bump pass_count
--     only -- EXPLORED never downgrades.
--   - Existing row PASSED_THROUGH (or, from an older flow, PENDING):
--     bump pass_count and update entered_at to this visit's time; if
--     this visit resolved to EXPLORED, upgrade the row's state and set
--     confirmed_at -- doc 03's "converting [a passed-through county] to
--     explored is the highest-value action in the territory system."
--
-- `language plpgsql` (not `sql`) since this needs a conditional branch,
-- not a single query. Default security (invoker, i.e. RLS still
-- applies) is enough -- the existing insert/update policies on
-- county_visits already let a user write their own rows.
create or replace function public.record_county_visit(
  p_county_id smallint,
  p_outcome text,
  p_entered_at timestamptz
)
returns void
language plpgsql
as $$
declare
  v_user_id uuid := auth.uid();
  v_existing public.county_visits;
begin
  if v_user_id is null then
    raise exception 'record_county_visit requires an authenticated user';
  end if;

  if p_outcome not in ('explored', 'passed_through') then
    raise exception 'record_county_visit: invalid outcome %', p_outcome;
  end if;

  select * into v_existing
  from public.county_visits
  where user_id = v_user_id and county_id = p_county_id
  for update;

  if not found then
    insert into public.county_visits (user_id, county_id, state, entered_at, confirmed_at, pass_count)
    values (
      v_user_id,
      p_county_id,
      p_outcome,
      p_entered_at,
      case when p_outcome = 'explored' then now() else null end,
      1
    );
    return;
  end if;

  if v_existing.state = 'explored' then
    update public.county_visits
      set pass_count = pass_count + 1
      where id = v_existing.id;
    return;
  end if;

  update public.county_visits
    set state = p_outcome,
        entered_at = p_entered_at,
        pass_count = pass_count + 1,
        confirmed_at = case when p_outcome = 'explored' then now() else confirmed_at end
    where id = v_existing.id;
end;
$$;

revoke execute on function public.record_county_visit(smallint, text, timestamptz) from public;
grant execute on function public.record_county_visit(smallint, text, timestamptz) to authenticated;
