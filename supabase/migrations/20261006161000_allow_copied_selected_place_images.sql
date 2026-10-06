-- A selected Dev import may reference a Supabase Storage URL only after the
-- importer has copied that object into the target project's place-images
-- bucket. The import RPC is service-role-only, so this marker cannot be set by
-- a browser client to bypass candidate review.

create or replace function public.selected_place_publish_blockers(
  p_place jsonb,
  p_images jsonb
)
returns text[]
language sql
immutable
set search_path = public
as $$
  select array_remove(array[
    case when nullif(btrim(p_place ->> 'source'), '') is null then 'source' end,
    case when exists (
      select 1
      from jsonb_array_elements(coalesce(p_images, '[]'::jsonb)) image
      where (
        coalesce(image.value ->> 'image_url', '') like '%/storage/v1/object/%'
        or coalesce(image.value ->> 'thumbnail_url', '') like '%/storage/v1/object/%'
      ) and coalesce(image.value ->> 'storage_copied', '') <> 'true'
    ) then 'image transfer' end
  ], null);
$$;
