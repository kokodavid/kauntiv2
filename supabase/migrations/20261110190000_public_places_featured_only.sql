-- Public places feed: hand-picked places only, a handful at a time.
--
-- Supersedes get_public_places() from 20261110170000 and 20261110180000.
-- Only places with featured_on_site = true that are reviewed and not archived
-- are returned, at most 12 (the site asks for 4). Places with a photo from the
-- public 'place-images' bucket come first, then a shuffle that is stable for a
-- day. No coordinates, no ids, no search.
--
-- To feature places:
--   update public.places set featured_on_site = true where id in (...);

alter table public.places
  add column if not exists featured_on_site boolean not null default false;

create or replace function public.get_public_places(p_limit integer default 4)
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
  where p.featured_on_site
    and p.status = 'reviewed'
    and p.archived_at is null
  order by (img.thumbnail_url is null), md5(p.id::text || current_date::text)
  limit least(greatest(coalesce(p_limit, 4), 1), 12);
$$;

revoke all on function public.get_public_places(integer) from public;
grant execute on function public.get_public_places(integer) to anon, authenticated;
