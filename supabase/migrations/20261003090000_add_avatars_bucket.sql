-- Self-service profile photos (Settings "Change photo"). Unlike
-- journey-media (private, owner-only read), an avatar is shown to other
-- people -- Ranks, Friends, and the "Shown on Ranks and to Friends" copy
-- in Edit Profile all assume it's publicly viewable, and the OAuth
-- avatar_url it replaces was already a public Google/Apple URL. So this
-- bucket is public read, with the same folder-owner write RLS pattern as
-- journey-media for everything else.
--
-- Objects are stored at `<user_id>/<file>`, so the folder-owner check is
-- just "the first path segment is auth.uid()".
insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do update set public = true;

create policy "Anyone can view avatars"
  on storage.objects
  for select
  to authenticated, anon
  using (bucket_id = 'avatars');

create policy "Users manage their own avatar objects"
  on storage.objects
  for insert
  to authenticated
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "Users update their own avatar objects"
  on storage.objects
  for update
  to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  )
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "Users delete their own avatar objects"
  on storage.objects
  for delete
  to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
