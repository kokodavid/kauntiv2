-- County highlight images back profile/explored-county cards and any
-- future county-level suggestion card that needs a representative visual.
--
-- This intentionally stores the selected image on `counties`, not only
-- through `places`, because a county card is not always about one place.
-- The initial seed derives each county's highlight from the first
-- licensed `place_images` row already on file, preserving attribution
-- metadata and leaving counties with no sourced image as null.

alter table public.counties
  add column if not exists highlight_image_url text,
  add column if not exists highlight_image_source text,
  add column if not exists highlight_image_source_url text,
  add column if not exists highlight_image_licence text,
  add column if not exists highlight_image_licence_url text,
  add column if not exists highlight_image_attribution text,
  add column if not exists highlight_image_last_verified_at date;

with ranked_images as (
  select
    places.county_id,
    place_images.thumbnail_url,
    place_images.source,
    place_images.source_url,
    place_images.licence,
    place_images.licence_url,
    place_images.attribution,
    place_images.last_verified_at,
    row_number() over (
      partition by places.county_id
      order by place_images.sort_order, places.name, place_images.created_at
    ) as row_number
  from public.places
  join public.place_images
    on place_images.place_id = places.id
)
update public.counties
set
  highlight_image_url = ranked_images.thumbnail_url,
  highlight_image_source = ranked_images.source,
  highlight_image_source_url = ranked_images.source_url,
  highlight_image_licence = ranked_images.licence,
  highlight_image_licence_url = ranked_images.licence_url,
  highlight_image_attribution = ranked_images.attribution,
  highlight_image_last_verified_at = ranked_images.last_verified_at
from ranked_images
where counties.id = ranked_images.county_id
  and ranked_images.row_number = 1
  and counties.highlight_image_url is null;
