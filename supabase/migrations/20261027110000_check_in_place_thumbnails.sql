set search_path = extensions, public;

-- The county page's "Places discovered" list shows each checked-in place's
-- photo. Same function as before, with the place's first image added.
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
  )
  select jsonb_build_object(
    'enabled', exists (
      select 1 from public.app_feature_flags
      where feature_key = 'place_check_ins' and enabled
    ),
    'visit_days', (select count(distinct visit_day) from mine),
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
