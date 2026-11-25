-- Public surfaces show a username and avatar, never a real name, and
-- publishing a trip needs a chosen username.
--
-- Staff views still read `display_name` (moderation needs to know who is
-- who); only what other app users can see changes here.

-- The trip author block: id, handle and avatar. `display_name` is gone.
create or replace function public_trip_private.projection(p_id uuid, p_revision integer)
returns jsonb language sql stable security definer set search_path = '' as $$
  select jsonb_build_object('id', p.id, 'revision', r.revision,
    'title', r.title, 'trip_date', r.trip_date,
    'author', jsonb_build_object('id', a.author_id,
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

-- Publishing also needs a chosen username (checked here, not just in the app).
create or replace function public_trip_private.assert_member(p_operation text)
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
    if not public.has_chosen_username(v_user) then
      raise exception 'username_required' using errcode = '42501';
    end if;
  end if;
  return v_user;
end $$;
