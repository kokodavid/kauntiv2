-- Public places feed for the landing site (kaunti47.com).
--
-- Anonymous visitors cannot read public.places (row-level security is for
-- signed-in users), and that stays true. Instead this adds one narrow doorway,
-- the same pattern as get_beta_seat_status(): a security-definer function that
-- returns a small, curated slice and nothing else.
--
--   * Only places someone has switched on (featured_on_site), that are reviewed
--     and not archived.
--   * No coordinates, no long description, no ids.
--   * A photo is returned only when it lives in the app's own public
--     'place-images' bucket, so the site never hot-links other hosts and every
--     photo's rights are the app's to manage. Its attribution is returned as
--     the credit line.
--   * At most 60 rows, in a shuffle that is stable for a day.
--
-- To feature places (until the dashboard has a toggle):
--   update public.places set featured_on_site = true where id in (...);

alter table public.places
  add column if not exists featured_on_site boolean not null default false;

comment on column public.places.featured_on_site is
  'When true (and the place is reviewed and not archived) the place may appear on the public landing site through get_public_places().';

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
  where p.featured_on_site
    and p.status = 'reviewed'
    and p.archived_at is null
  order by md5(p.id::text || current_date::text)
  limit least(greatest(coalesce(p_limit, 40), 1), 60);
$$;

revoke all on function public.get_public_places(integer) from public;
grant execute on function public.get_public_places(integer) to anon, authenticated;

comment on function public.get_public_places(integer) is
  'Curated, read-only places list for the public landing site. Featured, reviewed, non-archived places only; no coordinates.';
