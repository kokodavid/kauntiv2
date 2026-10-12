-- Share defaults (owner only) and the photo sanitization worker contract
-- (service role only).

create function public.get_public_trip_share_preferences()
returns jsonb language plpgsql stable security definer set search_path = '' as $$
declare v_result jsonb;
begin
  if auth.uid() is null then raise exception 'Sign in required' using errcode = '42501'; end if;
  select to_jsonb(p) - 'user_id' - 'updated_at' into v_result
    from public.public_trip_share_preferences p where p.user_id = auth.uid();
  -- Defaults match the table: places on, anything about the person off.
  return coalesce(v_result, jsonb_build_object('county_crossing', true, 'elevation_peak', true,
    'top_speed', false, 'long_stop', false, 'recording_break', false, 'photos', false, 'trim_m', 500));
end $$;

create function public.set_public_trip_share_preferences(
  p_county_crossing boolean, p_elevation_peak boolean, p_top_speed boolean,
  p_long_stop boolean, p_recording_break boolean, p_photos boolean, p_trim_m integer
) returns jsonb language plpgsql security definer set search_path = '' as $$
begin
  if auth.uid() is null then raise exception 'Sign in required' using errcode = '42501'; end if;
  if p_county_crossing is null or p_elevation_peak is null or p_top_speed is null or p_long_stop is null
    or p_recording_break is null or p_photos is null or p_trim_m is null
    or p_trim_m not in (500, 1000, 2000) then
    raise exception 'Every preference is required; trim must be 500, 1000 or 2000 metres'
      using errcode = '22023';
  end if;
  insert into public.public_trip_share_preferences(user_id,county_crossing,elevation_peak,top_speed,
    long_stop,recording_break,photos,trim_m,updated_at)
  values (auth.uid(),p_county_crossing,p_elevation_peak,p_top_speed,p_long_stop,p_recording_break,
    p_photos,p_trim_m,now())
  on conflict (user_id) do update set county_crossing = excluded.county_crossing,
    elevation_peak = excluded.elevation_peak, top_speed = excluded.top_speed,
    long_stop = excluded.long_stop, recording_break = excluded.recording_break,
    photos = excluded.photos, trim_m = excluded.trim_m, updated_at = now();
  return public.get_public_trip_share_preferences();
end $$;

-- The worker reads the source from journey-media, decodes, applies
-- orientation, re-encodes, strips all metadata, uploads the copy to the
-- private public-trip-media bucket, then reports back with the generation it
-- was given. A withdrawal or source change in the meantime bumps the
-- generation, so the report is refused and the worker deletes its upload.
create function public.list_public_trip_photo_jobs(p_limit integer default 10)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare v_result jsonb;
begin
  if p_limit is null or p_limit not between 1 and 50 then
    raise exception 'Invalid page size' using errcode = '22023';
  end if;
  select coalesce(jsonb_agg(to_jsonb(q) order by q.updated_at, q.id), '[]'::jsonb) into v_result from (
    select ph.id, ph.publication_id, ph.revision, p.generation, m.storage_path as source_path, ph.updated_at
    from public.public_trip_revision_photos ph
    join public.public_trip_revisions r on r.publication_id = ph.publication_id and r.revision = ph.revision
    join public.public_trip_publications p on p.id = ph.publication_id
    join public.journey_media m on m.id = ph.source_media_id
    where ph.status = 'pending' and r.status = 'prepared' and r.generation = p.generation
      and r.expires_at > now() and not p.hidden
    order by ph.updated_at, ph.id limit p_limit
  ) q;
  return v_result;
end $$;

create function public.complete_public_trip_photo(
  p_photo_id uuid, p_generation integer, p_sanitized_path text, p_width integer, p_height integer
) returns boolean language plpgsql security definer set search_path = '' as $$
begin
  if p_photo_id is null or p_generation is null or p_sanitized_path is null
    or length(p_sanitized_path) not between 1 and 300 or p_sanitized_path like '%..%'
    or p_width not between 1 and 4096 or p_height not between 1 and 4096 then
    raise exception 'Valid sanitized photo required' using errcode = '22023';
  end if;
  update public.public_trip_revision_photos ph
    set status = 'ready', sanitized_path = p_sanitized_path, width = p_width, height = p_height,
      failure_reason = null, updated_at = now()
  from public.public_trip_revisions r, public.public_trip_publications p
  where ph.id = p_photo_id and ph.status = 'pending'
    and r.publication_id = ph.publication_id and r.revision = ph.revision and r.status = 'prepared'
    and p.id = ph.publication_id and p.generation = p_generation and r.generation = p.generation;
  return found;
end $$;

create function public.fail_public_trip_photo(p_photo_id uuid, p_generation integer, p_reason text)
returns boolean language plpgsql security definer set search_path = '' as $$
begin
  if p_photo_id is null or p_generation is null or p_reason is null
    or length(p_reason) not between 1 and 200 then
    raise exception 'Valid failure required' using errcode = '22023';
  end if;
  update public.public_trip_revision_photos ph
    set status = 'failed', failure_reason = p_reason, updated_at = now()
  from public.public_trip_revisions r, public.public_trip_publications p
  where ph.id = p_photo_id and ph.status = 'pending'
    and r.publication_id = ph.publication_id and r.revision = ph.revision and r.status = 'prepared'
    and p.id = ph.publication_id and p.generation = p_generation and r.generation = p.generation;
  return found;
end $$;

revoke all on function public.get_public_trip_share_preferences(),
  public.set_public_trip_share_preferences(boolean,boolean,boolean,boolean,boolean,boolean,integer),
  public.list_public_trip_photo_jobs(integer),
  public.complete_public_trip_photo(uuid,integer,text,integer,integer),
  public.fail_public_trip_photo(uuid,integer,text)
  from public, anon, authenticated;
grant execute on function public.get_public_trip_share_preferences(),
  public.set_public_trip_share_preferences(boolean,boolean,boolean,boolean,boolean,boolean,integer)
  to authenticated;
grant execute on function public.list_public_trip_photo_jobs(integer),
  public.complete_public_trip_photo(uuid,integer,text,integer,integer),
  public.fail_public_trip_photo(uuid,integer,text)
  to service_role;
