-- Public Trips viewer photos. The viewer projection lists a photo's id, place
-- and size but never a storage path or URL. The app loads each image with a
-- short-lived signed URL for <publication>/<revision>/<photo id>.jpg, which
-- needs a read policy on the private bucket.
--
-- The policy allows exactly the sanitized copies of the live revision of a
-- trip the caller may currently view (read flag on, not hidden, author and
-- viewer not suspended, author not blocked). Withdrawing, hiding, blocking or
-- switching the flag off therefore stops new signed URLs immediately.
create function public.can_view_public_trip_photo(p_path text)
returns boolean language sql stable security definer set search_path = '' as $$
  select p_path is not null and exists (
    select 1 from public.public_trip_revision_photos ph
    join public.public_trip_publications p on p.id = ph.publication_id
    where ph.sanitized_path = p_path and ph.status = 'ready'
      and ph.revision = p.active_revision
      and public_trip_private.can_view(p.id));
$$;
revoke all on function public.can_view_public_trip_photo(text) from public, anon;
grant execute on function public.can_view_public_trip_photo(text) to authenticated;

do $$
begin
  if to_regclass('storage.objects') is not null then
    execute $p$create policy "Viewers read live public trip photos"
      on storage.objects for select to authenticated
      using (bucket_id = 'public-trip-media' and public.can_view_public_trip_photo(name))$p$;
  end if;
end $$;
