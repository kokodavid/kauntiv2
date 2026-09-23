-- Storage bucket for place images uploaded directly through the admin
-- dashboard (as opposed to the existing image_url/thumbnail_url text
-- fields, which point at external sources like Wikimedia Commons).
-- Mirrors the existing quest-images bucket pattern
-- (20260904025000_add_side_quest_images.sql): a public bucket, with
-- write access gated in SQL rather than by folder ownership, since this
-- bucket is a shared dashboard tool rather than per-user data.

insert into storage.buckets (id, name, public)
values ('place-images', 'place-images', true)
on conflict (id) do update set public = true;

create policy "Dashboard editors can upload place images"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'place-images'
    and public.current_admin_role() in ('owner', 'admin', 'editor')
  );

create policy "Dashboard editors can update place image objects"
  on storage.objects for update to authenticated
  using (
    bucket_id = 'place-images'
    and public.current_admin_role() in ('owner', 'admin', 'editor')
  );

create policy "Dashboard editors can delete place image objects"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'place-images'
    and public.current_admin_role() in ('owner', 'admin', 'editor')
  );
