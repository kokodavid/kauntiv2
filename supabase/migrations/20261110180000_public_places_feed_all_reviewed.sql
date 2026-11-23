-- Public places feed: show reviewed places without a manual "featured" switch.
--
-- Replaces get_public_places() from 20261110170000. Same shape, same privacy
-- limits (no coordinates, no ids, photos only from the public 'place-images'
-- bucket). Difference: every reviewed, non-archived place is eligible, and
-- places that have a photo come first, then a shuffle that is stable for a day.
--
-- places.featured_on_site (added in the previous migration) is left in place
-- but is not used. If hand-picking is wanted later, add
-- "and p.featured_on_site" back to the where clause.

create or replace function public.get_public_places(p_limit integer default 40)
returns table (
  name text,
  type_key text,
  type_label text,
  county text,
  summary text,
  image_url text,
  credit text
)
language sql
stable
security definer
set search_path = public
as $$
  select
    p.name,
    p.type,
    t.label,
    c.name,
    p.summary,
    img.thumbnail_url,
    nullif(btrim(coalesce(img.attribution, '')), '')
  from public.places p
  join public.counties c on c.id = p.county_id
  join public.place_types t on t.key = p.type
  left join lateral (
    select pi.thumbnail_url, pi.attribution
    from public.place_images pi
    where pi.place_id = p.id
      and pi.thumbnail_url like '%/storage/v1/object/public/place-images/%'
    order by pi.sort_order, pi.created_at
    limit 1
  ) img on true
  where p.status = 'reviewed'
    and p.archived_at is null
  order by (img.thumbnail_url is null), md5(p.id::text || current_date::text)
  limit least(greatest(coalesce(p_limit, 40), 1), 60);
$$;

revoke all on function public.get_public_places(integer) from public;
grant execute on function public.get_public_places(integer) to anon, authenticated;
