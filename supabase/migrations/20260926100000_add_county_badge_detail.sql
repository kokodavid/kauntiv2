-- Badge detail for one county, for the signed-in user (the Badges tab's
-- badge sheet): when the badge was earned, the explored visits and
-- distinct months behind its depth (same counting as
-- county_depth_ranks()), saved places visited, how many of the county's
-- places the user has ticked, and a few places to suggest.
--
-- security definer + auth.uid(): only ever the caller's own rows.
create or replace function public.county_badge_detail(p_county_id smallint)
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  with visit as (
    select v.state, v.confirmed_at
    from public.county_visits v
    where v.user_id = auth.uid() and v.county_id = p_county_id
  ),
  explored as (
    select
      count(*) as visits,
      count(distinct date_trunc('month', e.entered_at)) as months,
      max(e.entered_at) as last_at
    from public.county_visit_events e
    where e.user_id = auth.uid()
      and e.county_id = p_county_id
      and e.outcome = 'explored'
  ),
  saved as (
    select
      count(distinct w.place_id) as saved,
      count(distinct w.place_id) filter (where w.ticked_at is not null)
        as visited
    from public.wishlist_items w
    where w.user_id = auth.uid()
      and w.county_id = p_county_id
      and w.place_id is not null
  ),
  county_places as (
    select count(*) as total
    from public.places p
    where p.county_id = p_county_id
  ),
  suggestions as (
    select coalesce(
      jsonb_agg(
        jsonb_build_object('id', s.id, 'name', s.name, 'type', s.type)
        order by s.name
      ),
      '[]'::jsonb
    ) as list
    from (
      select p.id, p.name, p.type
      from public.places p
      where p.county_id = p_county_id and p.lat is not null
      order by p.name
      limit 5
    ) s
  )
  select jsonb_build_object(
    'state', (select state from visit),
    'earned_at', (select confirmed_at from visit),
    'explored_visits', (select visits from explored),
    'explored_months', (select months from explored),
    'last_explored_at', (select last_at from explored),
    'saved_places', (select saved from saved),
    'saved_visited', (select visited from saved),
    'places_total', (select total from county_places),
    'places_visited', (select visited from saved),
    'suggested_places', (select list from suggestions)
  );
$$;

revoke execute on function public.county_badge_detail(smallint) from public;
grant execute on function public.county_badge_detail(smallint) to authenticated;
