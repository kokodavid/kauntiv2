set search_path = extensions, public;

-- Bronze, Silver and Gold ask for the same thing in every county (3, 6 and 10
-- places; 2, 3 and 4 categories; 1, 2 and 3 days). A county that doesn't have
-- that many reviewed places yet can't offer the stamp, and the Passport says
-- so. To show that, the county read-back also reports how many reviewed
-- places the county has and how many place types they cover.
--
-- Same function as before with 'places_total' and 'categories_total' added.
create or replace function public.my_county_check_ins(p_county_id smallint)
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  with mine as (
    select c.place_id, c.visit_day, c.checked_in_at
    from public.place_check_ins c
    where c.user_id = auth.uid() and c.county_id = p_county_id
  ),
  firsts as (
    select distinct on (m.place_id) m.place_id, m.checked_in_at
    from mine m
    order by m.place_id, m.checked_in_at
  ),
  available as (
    select count(*) as places, count(distinct p.type) as categories
    from public.places p
    where p.county_id = p_county_id
      and p.status = 'reviewed' and p.archived_at is null
  )
  select jsonb_build_object(
    'enabled', exists (
      select 1 from public.app_feature_flags
      where feature_key = 'place_check_ins' and enabled
    ),
    'visit_days', (select count(distinct visit_day) from mine),
    'places_total', (select places from available),
    'categories_total', (select categories from available),
    'places', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', p.id,
        'name', p.name,
        'category', p.type,
        'visited_at', f.checked_in_at,
        'thumbnail_url', (
          select i.thumbnail_url
          from public.place_images i
          where i.place_id = p.id
          order by i.sort_order
          limit 1
        )
      ) order by f.checked_in_at)
      from firsts f
      join public.places p on p.id = f.place_id
    ), '[]'::jsonb)
  );
$$;

revoke execute on function public.my_county_check_ins(smallint)
  from public, anon;
grant execute on function public.my_county_check_ins(smallint)
  to authenticated;
