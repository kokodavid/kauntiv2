-- 'read': any signed-in, non-suspended user while the read flag is on.
-- 'publish': additionally active Pro now, and not suspended from publishing.
create function public_trip_private.assert_member(p_operation text)
returns uuid language plpgsql security definer set search_path = '' as $$
declare v_user uuid := auth.uid();
begin
  if v_user is null or p_operation is null or p_operation not in ('read', 'publish')
    or not exists (select 1 from public.app_feature_flags f
      where f.feature_key = 'public_trips_' || p_operation and f.enabled)
    or exists (select 1 from public.user_moderation_status s
      where s.user_id = v_user and s.status = 'suspended') then
    raise exception 'Public trips unavailable' using errcode = '42501';
  end if;
  if p_operation = 'publish' then
    if exists (select 1 from public.public_trip_authors a where a.user_id = v_user and a.suspended) then
      raise exception 'Public trips unavailable' using errcode = '42501';
    end if;
    if not public.has_pro_at(v_user, now()) then
      raise exception 'Pro is required to publish trips' using errcode = '42501';
    end if;
  end if;
  return v_user;
end $$;

create function public_trip_private.assert_admin(p_configuration boolean default false)
returns void language plpgsql security definer set search_path = '' as $$
begin
  if auth.uid() is null or not exists (
    select 1 from public.admin_members m where m.user_id = auth.uid()
      and m.status = 'active' and m.county_scope is null
      and (m.role::text in ('owner', 'admin')
        or (not p_configuration and m.role::text = 'moderator'))
      and not exists (select 1 from public.user_moderation_status s
        where s.user_id = m.user_id and s.status = 'suspended')
  ) then
    raise exception 'Public trip administrator required' using errcode = '42501';
  end if;
end $$;

create function public_trip_private.rate_limit(p_operation text, p_max integer, p_window text)
returns void language plpgsql security definer set search_path = '' as $$
declare v_calls integer;
begin
  insert into public_trip_private.rate_limits(user_id, operation, window_start, calls)
  values (auth.uid(), p_operation, date_trunc(p_window, now() at time zone 'UTC') at time zone 'UTC', 1)
  on conflict (user_id, operation, window_start)
  do update set calls = public_trip_private.rate_limits.calls + 1
  returning calls into v_calls;
  if v_calls > p_max then
    raise exception 'Public trip request limit reached' using errcode = '54000';
  end if;
end $$;

create function public_trip_private.source_hash(p_journey_id uuid)
returns text language sql stable security definer set search_path = '' as $$
  select encode(sha256(convert_to(jsonb_build_array(j.transport_mode, j.started_at, j.ended_at,
    (select jsonb_agg(jsonb_build_array(p.sequence_number, p.segment_number,
      p.latitude, p.longitude, p.recorded_at, p.accuracy_m) order by p.sequence_number)
     from public.journey_points p where p.journey_id = j.id))::text, 'UTF8')), 'hex')
  from public.journeys j where j.id = p_journey_id;
$$;

-- The viewer-facing shape. Author identity is read live from the public
-- profile (display name, handle, avatar). Photos appear only once
-- sanitized, and never with a storage path.
create function public_trip_private.projection(p_id uuid, p_revision integer)
returns jsonb language sql stable security definer set search_path = '' as $$
  select jsonb_build_object('id', p.id, 'revision', r.revision,
    'title', r.title, 'trip_date', r.trip_date,
    'author', jsonb_build_object('id', a.author_id, 'display_name', qp.display_name,
      'handle', qp.handle, 'avatar_url', qp.avatar_url),
    'transport_mode', r.transport_mode, 'route', r.route,
    'distance_m', r.distance_m, 'counties', r.counties, 'playback', 'illustrative',
    'moments', coalesce((select jsonb_agg(jsonb_build_object('kind', mo.kind,
        'latitude', mo.latitude, 'longitude', mo.longitude, 'value', mo.value) order by mo.ordinal)
      from public.public_trip_revision_moments mo
      where mo.publication_id = p.id and mo.revision = r.revision), '[]'::jsonb),
    'photos', coalesce((select jsonb_agg(jsonb_build_object('id', ph.id,
        'latitude', ph.latitude, 'longitude', ph.longitude,
        'width', ph.width, 'height', ph.height) order by ph.ordinal)
      from public.public_trip_revision_photos ph
      where ph.publication_id = p.id and ph.revision = r.revision and ph.status = 'ready'), '[]'::jsonb))
  from public.public_trip_publications p
  join public.public_trip_revisions r on r.publication_id = p.id and r.revision = p_revision
  join public.public_trip_authors a on a.user_id = p.owner_id
  left join public.quest_public_profiles qp on qp.user_id = p.owner_id
  where p.id = p_id;
$$;

create function public_trip_private.owner_projection(p_id uuid, p_revision integer)
returns jsonb language sql stable security definer set search_path = '' as $$
  select public_trip_private.projection(p_id, p_revision) || jsonb_build_object(
    'status', r.status, 'content_hash', r.content_hash, 'expires_at', r.expires_at,
    'review_reason', r.review_reason, 'terms_version', 'public-trips-v1',
    'start_trim_m', r.start_trim_m, 'end_trim_m', r.end_trim_m, 'excluded', r.excluded,
    'photos_pending', (select count(*) from public.public_trip_revision_photos ph
      where ph.publication_id = p_id and ph.revision = p_revision and ph.status = 'pending'),
    'photos_failed', (select count(*) from public.public_trip_revision_photos ph
      where ph.publication_id = p_id and ph.revision = p_revision and ph.status = 'failed'))
  from public.public_trip_revisions r where r.publication_id = p_id and r.revision = p_revision;
$$;

-- An approved trip stays visible if the owner's Pro later lapses; Pro is
-- checked when preparing and submitting, not on every read.
create function public_trip_private.can_view(p_id uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select auth.uid() is not null and exists (
    select 1 from public.public_trip_publications p
    join public.public_trip_revisions r on r.publication_id = p.id and r.revision = p.active_revision
    join public.public_trip_authors a on a.user_id = p.owner_id
    where p.id = p_id and not p.hidden and r.status = 'approved'
      and r.generation = p.generation and not a.suspended
      and exists (select 1 from public.app_feature_flags f where f.feature_key = 'public_trips_read' and f.enabled)
      and not exists (select 1 from public.user_moderation_status s
        where s.user_id in (auth.uid(), p.owner_id) and s.status = 'suspended')
      and not exists (select 1 from public.public_trip_author_blocks b
        where b.viewer_id = auth.uid() and b.author_id = a.author_id)
  );
$$;

-- Trigger protection also covers administrative edits outside the upload RPC.
-- Revokes every public copy built from any of p_journeys.
create function public_trip_private.revoke_for_journeys(p_journeys uuid[])
returns void language plpgsql security definer set search_path = '' as $$
begin
  with changed as (
    update public.public_trip_publications set generation = generation + 1, active_revision = null
    where journey_id = any(p_journeys)
    returning id
  ) update public.public_trip_revisions set status = 'revoked'
    where publication_id in (select id from changed) and status <> 'revoked';
end $$;

create function public_trip_private.invalidate_journey()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if new.transport_mode is not distinct from old.transport_mode
    and new.started_at = old.started_at and new.ended_at = old.ended_at then return null; end if;
  perform public_trip_private.revoke_for_journeys(array[new.id]);
  return null;
end $$;

-- Statement-level, not per row: upload_journey inserts up to 50,000 points
-- in one statement, and a row trigger ran a publication lookup for every
-- one of them (~2.5x the insert time on every upload, published or not).
-- This runs once per statement over the distinct journeys it touched.
create function public_trip_private.invalidate_points()
returns trigger language plpgsql security definer set search_path = '' as $$
declare v_journeys uuid[];
begin
  if tg_op = 'INSERT' then
    select array_agg(distinct journey_id) into v_journeys from new_points;
  elsif tg_op = 'DELETE' then
    select array_agg(distinct journey_id) into v_journeys from old_points;
  else
    -- An update can move points between journeys; revoke both sides.
    select array_agg(distinct journey_id) into v_journeys from (
      select journey_id from new_points union select journey_id from old_points
    ) changed;
  end if;
  if v_journeys is not null then
    perform public_trip_private.revoke_for_journeys(v_journeys);
  end if;
  return null;
end $$;

-- One trigger per event: a trigger with transition tables can't cover
-- several events at once.
create trigger public_trip_points_inserted after insert on public.journey_points
  referencing new table as new_points
  for each statement execute function public_trip_private.invalidate_points();
create trigger public_trip_points_updated after update on public.journey_points
  referencing old table as old_points new table as new_points
  for each statement execute function public_trip_private.invalidate_points();
create trigger public_trip_points_deleted after delete on public.journey_points
  referencing old table as old_points
  for each statement execute function public_trip_private.invalidate_points();
create trigger public_trip_journey_changed after update on public.journeys
  for each row execute function public_trip_private.invalidate_journey();

revoke all on all functions in schema public_trip_private from public, anon, authenticated;
