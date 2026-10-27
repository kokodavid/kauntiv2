-- A published release with no store URL now resolves to the tester invite
-- link for its platform: android_opt_in_url or ios_testflight_url from
-- beta_tester_invite_settings. A release's own store_url always wins, so
-- set it once the public store listing exists. Grants are unchanged.

create or replace function public.get_app_update_policy(
  p_platform text,
  p_channel text,
  p_current_version text
) returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_major integer;
  v_minor integer;
  v_patch integer;
  v_latest public.app_version_releases%rowtype;
  v_required public.app_version_releases%rowtype;
  v_fallback text;
begin
  if p_platform is null or p_channel is null or p_current_version is null
     or p_platform not in ('ios', 'android')
     or p_channel not in ('development', 'beta', 'production')
     or p_current_version !~ '^(0|[1-9][0-9]{0,8})\.(0|[1-9][0-9]{0,8})\.(0|[1-9][0-9]{0,8})$' then
    raise exception 'Invalid app update query' using errcode = '22023';
  end if;
  v_major := split_part(p_current_version, '.', 1)::integer;
  v_minor := split_part(p_current_version, '.', 2)::integer;
  v_patch := split_part(p_current_version, '.', 3)::integer;

  select * into v_latest from public.app_version_releases
  where platform = p_platform and channel = p_channel and status = 'live'
  order by major desc, minor desc, patch desc limit 1;
  select * into v_required from public.app_version_releases
  where platform = p_platform and channel = p_channel
    and status = 'live' and update_mode = 'required'
  order by major desc, minor desc, patch desc limit 1;

  if v_latest.id is null then
    return jsonb_build_object('available', false, 'required', false);
  end if;
  -- A release without its own store link falls back to the tester invite
  -- link for the platform (Play opt-in / TestFlight), so beta builds can
  -- update without anyone pasting the same URL into every release.
  if v_latest.store_url is null then
    select case p_platform
             when 'android' then s.android_opt_in_url
             else s.ios_testflight_url
           end
      into v_fallback
    from public.beta_tester_invite_settings s
    where s.singleton;
  end if;
  return jsonb_build_object(
    'latest_version', v_latest.version,
    'required_version', v_required.version,
    'available', (v_major, v_minor, v_patch) < (v_latest.major, v_latest.minor, v_latest.patch),
    'required', v_required.id is not null
      and (v_major, v_minor, v_patch) < (v_required.major, v_required.minor, v_required.patch),
    'store_url', coalesce(v_latest.store_url, v_fallback),
    'release_notes', v_latest.release_notes
  );
end;
$$;
