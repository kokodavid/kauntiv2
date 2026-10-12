-- Photo worker job claiming. The first version of list_public_trip_photo_jobs()
-- only listed pending photos, so a photo that kills the worker (out of memory
-- or CPU) would be retried forever at the head of the queue, and two
-- overlapping worker runs could process the same photo.
--
-- Listing now claims: each photo gets a 3 minute lease and an attempt count.
-- A photo claimed three times without finishing is marked failed so the owner
-- can pick another photo. Overlapping runs never receive the same photo.
alter table public.public_trip_revision_photos
  add column attempts integer not null default 0 check (attempts between 0 and 10),
  add column claimed_at timestamptz;

create or replace function public.list_public_trip_photo_jobs(p_limit integer default 10)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare v_result jsonb;
begin
  if p_limit is null or p_limit not between 1 and 50 then
    raise exception 'Invalid page size' using errcode = '22023';
  end if;
  update public.public_trip_revision_photos
    set status = 'failed', failure_reason = 'Photo could not be processed', updated_at = now()
  where status = 'pending' and attempts >= 3 and claimed_at < now() - interval '3 minutes';

  with picked as (
    select ph.id
    from public.public_trip_revision_photos ph
    join public.public_trip_revisions r on r.publication_id = ph.publication_id and r.revision = ph.revision
    join public.public_trip_publications p on p.id = ph.publication_id
    where ph.status = 'pending' and ph.attempts < 3
      and (ph.claimed_at is null or ph.claimed_at < now() - interval '3 minutes')
      and r.status = 'prepared' and r.generation = p.generation
      and r.expires_at > now() and not p.hidden
    order by ph.updated_at, ph.id limit p_limit
    for update of ph skip locked
  ), claimed as (
    update public.public_trip_revision_photos ph
      set attempts = ph.attempts + 1, claimed_at = now()
    from picked where ph.id = picked.id
    returning ph.id, ph.publication_id, ph.revision, ph.source_media_id, ph.attempts, ph.updated_at
  )
  select coalesce(jsonb_agg(jsonb_build_object(
      'id', c.id, 'publication_id', c.publication_id, 'revision', c.revision,
      'generation', p.generation, 'source_path', m.storage_path,
      'attempts', c.attempts, 'updated_at', c.updated_at) order by c.updated_at, c.id), '[]'::jsonb)
    into v_result
  from claimed c
  join public.public_trip_publications p on p.id = c.publication_id
  join public.journey_media m on m.id = c.source_media_id;
  return v_result;
end $$;

-- Every storage path a sanitized photo may legitimately occupy. The worker's
-- sweep deletes objects in public-trip-media that are not listed here.
create function public.public_trip_photo_paths_in_use()
returns jsonb language sql stable security definer set search_path = '' as $$
  select coalesce(jsonb_agg(sanitized_path), '[]'::jsonb)
  from public.public_trip_revision_photos where sanitized_path is not null;
$$;

revoke all on function public.list_public_trip_photo_jobs(integer),
  public.public_trip_photo_paths_in_use() from public, anon, authenticated;
grant execute on function public.list_public_trip_photo_jobs(integer),
  public.public_trip_photo_paths_in_use() to service_role;
