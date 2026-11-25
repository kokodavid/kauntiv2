-- A user's stays in one county: how many were timed, the total time and the
-- recent ones. Stays never add up towards the 2 h explored rule; this only
-- reports them. Visits recorded before 11 Oct 2026, and visits from older
-- app builds, have no stay_seconds and are counted separately. A stay over
-- 24 hours is almost always a late exit (the phone only noticed it had left
-- when the app next ran), so those are counted as long_visits and left out
-- of the total.
--
-- Additive: a new function only. Nothing existing changes, so older app
-- builds keep working.
create or replace function public.county_stay_summary(p_county_id smallint)
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  with stays as (
    select e.entered_at, e.outcome, e.stay_seconds
    from public.county_visit_events e
    where e.user_id = auth.uid()
      and e.county_id = p_county_id
  ),
  recent as (
    select entered_at, outcome, stay_seconds
    from stays
    order by entered_at desc
    limit 10
  )
  select jsonb_build_object(
    'visits', (select count(*) from stays),
    'timed_visits', (
      select count(stay_seconds) from stays where stay_seconds <= 86400
    ),
    'long_visits', (
      select count(*) from stays where stay_seconds > 86400
    ),
    'total_stay_seconds', coalesce(
      (select sum(stay_seconds) from stays where stay_seconds <= 86400), 0
    ),
    'recent', coalesce(
      (select jsonb_agg(
         jsonb_build_object(
           'entered_at', entered_at,
           'outcome', outcome,
           'stay_seconds', stay_seconds
         )
         order by entered_at desc
       ) from recent),
      '[]'::jsonb
    )
  );
$$;

revoke execute on function public.county_stay_summary(smallint) from public;
grant execute on function public.county_stay_summary(smallint) to authenticated;
