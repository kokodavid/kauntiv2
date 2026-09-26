-- Badge sheet "Places to start with" as place rows: each suggested place
-- now carries its summary, coordinates (the phone sorts by distance from
-- the user and shows the nearest few), first photo, and whether the user
-- saved it. Up to 30 places per county. Otherwise unchanged.
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
  last_visit as (
    select max(e.entered_at) as at
    from public.county_visit_events e
    where e.user_id = auth.uid() and e.county_id = p_county_id
  ),
  journeys as (
    select count(distinct jc.journey_id) as count,
           coalesce(sum(jc.distance_m), 0) as distance
    from public.journey_counties jc
    where jc.user_id = auth.uid() and jc.county_id = p_county_id
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
        jsonb_build_object(
          'id', s.id,
          'name', s.name,
          'type', s.type,
          'summary', s.summary,
          'lat', s.lat,
          'lng', s.lng,
          'thumbnail_url', s.thumbnail_url,
          'saved', s.saved
        )
        order by s.name
      ),
      '[]'::jsonb
    ) as list
    from (
      select
        p.id, p.name, p.type, p.summary, p.lat, p.lng,
        (
          select i.thumbnail_url
          from public.place_images i
          where i.place_id = p.id
          order by i.sort_order
          limit 1
        ) as thumbnail_url,
        exists (
          select 1 from public.wishlist_items w
          where w.user_id = auth.uid() and w.place_id = p.id
        ) as saved
      from public.places p
      where p.county_id = p_county_id and p.lat is not null
      order by p.name
      limit 30
    ) s
  )
  select jsonb_build_object(
    'state', (select state from visit),
    'earned_at', (select confirmed_at from visit),
    'explored_visits', (select visits from explored),
    'explored_months', (select months from explored),
    'last_explored_at', (select last_at from explored),
    'last_visited_at', (select at from last_visit),
    'journeys', (select count from journeys),
    'journey_distance_m', (select distance from journeys),
    'saved_places', (select saved from saved),
    'saved_visited', (select visited from saved),
    'places_total', (select total from county_places),
    'places_visited', (select visited from saved),
    'suggested_places', (select list from suggestions)
  );
$$;

revoke execute on function public.county_badge_detail(smallint) from public;
grant execute on function public.county_badge_detail(smallint) to authenticated;
