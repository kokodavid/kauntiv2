-- User-submitted place photos, published only after an admin approves them.
--
-- Access model
--   * Any signed-in user with a CHOSEN username (not the generated
--     `user-xxxxxxxx` handle) can submit. The username is the public credit.
--   * Photos are uploaded to the PRIVATE bucket `place-photo-submissions`,
--     under the uploader's own folder. Nobody else can read them while they
--     are pending, so unreviewed images are never served publicly.
--   * The client never inserts a row. `submit_place_photo` re-checks the
--     caller, the place, the uploaded objects and the rate limits.
--   * Approving copies the photo into the public `place-images` bucket (done
--     by the `review-place-photo` Edge Function) and adds a `place_images`
--     row via `review_place_photo_dashboard`. The private copies are then
--     deleted by the function, approved or rejected.
--
-- Idempotent: safe to re-run.

create table if not exists public.place_photo_submissions (
  -- Chosen by the app, so the uploaded file name and the row always match.
  id uuid primary key,
  place_id uuid not null references public.places (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  -- `<user_id>/<id>.jpg`, plus a small `<user_id>/<id>_thumb.jpg` beside it.
  storage_path text not null unique,
  thumb_path text not null unique,
  caption text check (caption is null or char_length(caption) <= 140),
  width integer not null check (width > 0),
  height integer not null check (height > 0),
  -- SHA-256 of the uploaded bytes: stops the same photo being sent twice.
  content_hash text check (content_hash is null or char_length(content_hash) = 64),
  status text not null default 'pending'
    check (status in ('pending', 'approved', 'rejected')),
  reject_reason text,
  reviewed_by uuid references auth.users (id) on delete set null,
  reviewed_at timestamptz,
  image_id uuid references public.place_images (id) on delete set null,
  created_at timestamptz not null default now()
);

create index if not exists place_photo_submissions_queue_idx
  on public.place_photo_submissions (status, created_at);
create index if not exists place_photo_submissions_user_idx
  on public.place_photo_submissions (user_id, created_at desc);
create index if not exists place_photo_submissions_place_idx
  on public.place_photo_submissions (place_id);
create unique index if not exists place_photo_submissions_no_repeat_idx
  on public.place_photo_submissions (user_id, place_id, content_hash)
  where content_hash is not null and status in ('pending', 'approved');

alter table public.place_photo_submissions enable row level security;

drop policy if exists "Users read their own photo submissions"
  on public.place_photo_submissions;
create policy "Users read their own photo submissions"
  on public.place_photo_submissions for select to authenticated
  using (user_id = auth.uid());
-- No insert/update/delete policy: writes go through the RPCs below.

-- Private bucket ------------------------------------------------------------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'place-photo-submissions',
  'place-photo-submissions',
  false,
  8388608,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update
  set public = false,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Users upload their own place photos" on storage.objects;
create policy "Users upload their own place photos"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'place-photo-submissions'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "Users read their own place photos" on storage.objects;
create policy "Users read their own place photos"
  on storage.objects for select to authenticated
  using (
    bucket_id = 'place-photo-submissions'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- Lets the app clean up an upload whose submit call failed.
drop policy if exists "Users delete their own place photos" on storage.objects;
create policy "Users delete their own place photos"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'place-photo-submissions'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "Dashboard editors read place photo submissions" on storage.objects;
create policy "Dashboard editors read place photo submissions"
  on storage.objects for select to authenticated
  using (
    bucket_id = 'place-photo-submissions'
    and public.current_admin_role() in ('owner', 'admin', 'editor')
  );

-- Has the user picked their own username? The generated one is
-- `user-` plus eight hex characters (see quest_public_profiles).
create or replace function public.has_chosen_username(p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.quest_public_profiles p
    where p.user_id = p_user_id
      and p.handle !~ '^user-[0-9a-f]{8}$'
  );
$$;

revoke all on function public.has_chosen_username(uuid) from public, anon;
grant execute on function public.has_chosen_username(uuid) to authenticated;

-- Switch ---------------------------------------------------------------------
-- The feature is turned on and off from the dashboard (Feature settings),
-- through the same app_feature_flags table as county news and public trips.
-- Off by default. Checked server-side in submit_place_photo, so a paused
-- feature refuses new photos even from an old app build.
alter table public.app_feature_flags
  drop constraint if exists app_feature_flags_feature_key_check;
alter table public.app_feature_flags add constraint app_feature_flags_feature_key_check
  check (feature_key in (
    'county_news', 'public_trips_read', 'public_trips_publish', 'place_photos'
  ));
insert into public.app_feature_flags (feature_key, enabled)
values ('place_photos', false)
on conflict (feature_key) do nothing;

create or replace function public.set_place_photos_enabled_dashboard(
  p_enabled boolean
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
begin
  if coalesce(public.current_admin_role() in ('owner', 'admin'), false) is not true then
    raise exception 'Owner or admin access required' using errcode = '42501';
  end if;
  if p_enabled is null then
    raise exception 'Enabled value is required' using errcode = '22004';
  end if;
  insert into public.app_feature_flags (feature_key, enabled, updated_at, updated_by)
  values ('place_photos', p_enabled, now(), auth.uid())
  on conflict (feature_key) do update
  set enabled = excluded.enabled,
      updated_at = excluded.updated_at,
      updated_by = excluded.updated_by;
  return p_enabled;
end;
$$;

revoke execute on function public.set_place_photos_enabled_dashboard(boolean)
  from public, anon;
grant execute on function public.set_place_photos_enabled_dashboard(boolean)
  to authenticated;

-- Submit ---------------------------------------------------------------------
-- Errors the app maps to plain messages (the exception text is the code):
--   feature_off, username_required, place_unavailable, upload_missing, image_too_small,
--   too_many_pending, place_limit, daily_limit, duplicate_photo
create or replace function public.submit_place_photo(
  p_submission_id uuid,
  p_place_id uuid,
  p_caption text,
  p_width integer,
  p_height integer,
  p_content_hash text
)
returns public.place_photo_submissions
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_path text;
  v_thumb text;
  v_caption text := nullif(btrim(coalesce(p_caption, '')), '');
  v_row public.place_photo_submissions;
begin
  if v_user is null then
    raise exception 'Sign in to add a photo' using errcode = '42501';
  end if;
  if not exists (
    select 1 from public.app_feature_flags
    where feature_key = 'place_photos' and enabled
  ) then
    raise exception 'feature_off' using errcode = 'P0001';
  end if;
  if not public.has_chosen_username(v_user) then
    raise exception 'username_required' using errcode = 'P0001';
  end if;
  if p_submission_id is null or p_place_id is null then
    raise exception 'Missing submission or place' using errcode = '22004';
  end if;
  if v_caption is not null and char_length(v_caption) > 140 then
    raise exception 'Caption is too long' using errcode = '22001';
  end if;
  if coalesce(p_width, 0) <= 0 or coalesce(p_height, 0) <= 0 then
    raise exception 'Missing image size' using errcode = '22004';
  end if;
  if greatest(p_width, p_height) < 800 then
    raise exception 'image_too_small' using errcode = 'P0001';
  end if;
  if p_content_hash is not null and p_content_hash !~ '^[0-9a-f]{64}$' then
    raise exception 'Bad content hash' using errcode = '22023';
  end if;

  if not exists (
    select 1 from public.places
    where id = p_place_id and status = 'reviewed' and archived_at is null
  ) then
    raise exception 'place_unavailable' using errcode = 'P0001';
  end if;

  v_path := v_user::text || '/' || p_submission_id::text || '.jpg';
  v_thumb := v_user::text || '/' || p_submission_id::text || '_thumb.jpg';
  if (
    select count(*) from storage.objects
    where bucket_id = 'place-photo-submissions' and name in (v_path, v_thumb)
  ) < 2 then
    raise exception 'upload_missing' using errcode = 'P0001';
  end if;

  if (select count(*) from public.place_photo_submissions
      where user_id = v_user and status = 'pending') >= 5 then
    raise exception 'too_many_pending' using errcode = 'P0001';
  end if;
  if (select count(*) from public.place_photo_submissions
      where user_id = v_user and place_id = p_place_id and status = 'pending') >= 2 then
    raise exception 'place_limit' using errcode = 'P0001';
  end if;
  if (select count(*) from public.place_photo_submissions
      where user_id = v_user and created_at > now() - interval '24 hours') >= 10 then
    raise exception 'daily_limit' using errcode = 'P0001';
  end if;

  insert into public.place_photo_submissions (
    id, place_id, user_id, storage_path, thumb_path, caption,
    width, height, content_hash
  )
  values (
    p_submission_id, p_place_id, v_user, v_path, v_thumb, v_caption,
    p_width, p_height, p_content_hash
  )
  returning * into v_row;
  return v_row;
exception
  when unique_violation then
    raise exception 'duplicate_photo' using errcode = 'P0001';
end;
$$;

revoke all on function public.submit_place_photo(uuid, uuid, text, integer, integer, text)
  from public, anon;
grant execute on function public.submit_place_photo(uuid, uuid, text, integer, integer, text)
  to authenticated;

-- The caller's own submissions, newest first, for the "Your photos" strip.
-- A pending photo is previewed from its private path (signed URL, own
-- folder); an approved one from its published thumbnail.
create or replace function public.my_place_photo_submissions(
  p_place_id uuid default null
)
returns table (
  id uuid,
  place_id uuid,
  place_name text,
  status text,
  reject_reason text,
  caption text,
  thumb_path text,
  published_thumbnail_url text,
  created_at timestamptz
)
language sql
stable
security definer
set search_path = public
as $$
  select
    s.id,
    s.place_id,
    p.name,
    s.status,
    s.reject_reason,
    s.caption,
    case when s.status = 'pending' then s.thumb_path else null end,
    i.thumbnail_url,
    s.created_at
  from public.place_photo_submissions s
  join public.places p on p.id = s.place_id
  left join public.place_images i on i.id = s.image_id
  where s.user_id = auth.uid()
    and (p_place_id is null or s.place_id = p_place_id)
  order by s.created_at desc
  limit 50;
$$;

revoke all on function public.my_place_photo_submissions(uuid) from public, anon;
grant execute on function public.my_place_photo_submissions(uuid) to authenticated;

-- Dashboard ------------------------------------------------------------------
create or replace function public.list_place_photo_submissions_dashboard(
  p_status text default 'pending'
)
returns table (
  id uuid,
  place_id uuid,
  place_name text,
  county_name text,
  user_id uuid,
  handle text,
  caption text,
  storage_path text,
  width integer,
  height integer,
  status text,
  reject_reason text,
  created_at timestamptz,
  reviewed_at timestamptz,
  place_photo_count bigint
)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if coalesce(public.current_admin_role() in ('owner', 'admin', 'editor'), false) is not true then
    raise exception 'Dashboard access required' using errcode = '42501';
  end if;
  if p_status is not null and p_status not in ('pending', 'approved', 'rejected') then
    raise exception 'Unknown status %', p_status using errcode = '22023';
  end if;
  return query
    select
      s.id,
      s.place_id,
      p.name,
      c.name,
      s.user_id,
      q.handle,
      s.caption,
      s.storage_path,
      s.width,
      s.height,
      s.status,
      s.reject_reason,
      s.created_at,
      s.reviewed_at,
      (select count(*) from public.place_images i where i.place_id = s.place_id)
    from public.place_photo_submissions s
    join public.places p on p.id = s.place_id
    left join public.counties c on c.id = p.county_id
    left join public.quest_public_profiles q on q.user_id = s.user_id
    where p_status is null or s.status = p_status
    order by
      case when s.status = 'pending' then s.created_at end asc,
      s.created_at desc
    limit 200;
end;
$$;

revoke all on function public.list_place_photo_submissions_dashboard(text) from public, anon;
grant execute on function public.list_place_photo_submissions_dashboard(text) to authenticated;

create or replace function public.pending_place_photo_count_dashboard()
returns bigint
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if coalesce(public.current_admin_role() in ('owner', 'admin', 'editor'), false) is not true then
    return 0;
  end if;
  return (select count(*) from public.place_photo_submissions where status = 'pending');
end;
$$;

revoke all on function public.pending_place_photo_count_dashboard() from public, anon;
grant execute on function public.pending_place_photo_count_dashboard() to authenticated;

-- Approve or reject. Called by the `review-place-photo` Edge Function with the
-- reviewer's own JWT, after it has copied the photo into `place-images` (for
-- an approval). p_image_url / p_thumbnail_url are those public URLs.
create or replace function public.review_place_photo_dashboard(
  p_id uuid,
  p_approve boolean,
  p_reason text default null,
  p_image_url text default null,
  p_thumbnail_url text default null
)
returns public.place_photo_submissions
language plpgsql
security definer
set search_path = public
as $$
declare
  v_row public.place_photo_submissions;
  v_handle text;
  v_image public.place_images;
  v_reason text := nullif(btrim(coalesce(p_reason, '')), '');
begin
  if coalesce(public.current_admin_role() in ('owner', 'admin', 'editor'), false) is not true then
    raise exception 'Dashboard access required' using errcode = '42501';
  end if;

  select * into v_row
  from public.place_photo_submissions
  where id = p_id
  for update;
  if not found then
    raise exception 'Submission not found' using errcode = 'P0002';
  end if;
  if v_row.status <> 'pending' then
    raise exception 'This photo was already reviewed' using errcode = '55000';
  end if;

  if p_approve then
    if btrim(coalesce(p_image_url, '')) = '' or btrim(coalesce(p_thumbnail_url, '')) = '' then
      raise exception 'Published image URLs are required' using errcode = '22004';
    end if;
    select handle into v_handle
    from public.quest_public_profiles
    where user_id = v_row.user_id;

    insert into public.place_images (
      place_id, sort_order, image_url, thumbnail_url, width, height,
      source, source_url, licence, attribution, external_id, last_verified_at
    )
    values (
      v_row.place_id,
      coalesce((select max(sort_order) + 1 from public.place_images
                where place_id = v_row.place_id), 0),
      btrim(p_image_url),
      btrim(p_thumbnail_url),
      v_row.width,
      v_row.height,
      'kaunti47_user',
      'https://kaunti47.com',
      'Contributor grant to Kaunti47',
      case when v_handle is null then null else '@' || v_handle end,
      v_row.id::text,
      current_date
    )
    returning * into v_image;

    update public.place_photo_submissions
    set status = 'approved',
        image_id = v_image.id,
        reject_reason = null,
        reviewed_by = auth.uid(),
        reviewed_at = now()
    where id = p_id
    returning * into v_row;
  else
    if v_reason is null then
      raise exception 'A reason is required to reject a photo' using errcode = '22004';
    end if;
    update public.place_photo_submissions
    set status = 'rejected',
        reject_reason = left(v_reason, 300),
        reviewed_by = auth.uid(),
        reviewed_at = now()
    where id = p_id
    returning * into v_row;
  end if;
  return v_row;
end;
$$;

revoke all on function public.review_place_photo_dashboard(uuid, boolean, text, text, text)
  from public, anon;
grant execute on function public.review_place_photo_dashboard(uuid, boolean, text, text, text)
  to authenticated;
