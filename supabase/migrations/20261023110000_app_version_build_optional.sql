alter table public.app_version_releases
  alter column build drop not null;

create or replace function public.create_app_version_release_dashboard(
  p_platform text,
  p_channel text,
  p_version text,
  p_build integer,
  p_store_url text,
  p_release_notes text default '',
  p_minor_optional boolean default false
) returns public.app_version_releases
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_major integer;
  v_minor integer;
  v_patch integer;
  v_latest public.app_version_releases%rowtype;
  v_mode text;
  v_result public.app_version_releases%rowtype;
begin
  if coalesce(public.current_admin_role() not in ('owner', 'admin'), true) then
    raise exception 'Owner or admin access required' using errcode = '42501';
  end if;
  if p_platform is null or p_channel is null or p_version is null
     or p_store_url is null or p_minor_optional is null
     or p_platform not in ('ios', 'android')
     or p_channel not in ('development', 'beta', 'production')
     or p_version !~ '^(0|[1-9][0-9]{0,8})\.(0|[1-9][0-9]{0,8})\.(0|[1-9][0-9]{0,8})$'
     or (p_build is not null and p_build <= 0)
     or p_store_url !~ '^https://[^/[:space:]]+([/?#][^[:space:]]*)?$'
     or char_length(coalesce(p_release_notes, '')) > 4000 then
    raise exception 'Invalid release details' using errcode = '22023';
  end if;
  v_major := split_part(p_version, '.', 1)::integer;
  v_minor := split_part(p_version, '.', 2)::integer;
  v_patch := split_part(p_version, '.', 3)::integer;
  perform pg_advisory_xact_lock(
    hashtextextended('app-version:' || p_platform || ':' || p_channel, 0)
  );
  select * into v_latest from public.app_version_releases
    where platform = p_platform and channel = p_channel and status = 'live'
    order by major desc, minor desc, patch desc limit 1;
  if v_latest.id is not null and
     (v_major, v_minor, v_patch) <= (v_latest.major, v_latest.minor, v_latest.patch) then
    raise exception 'Release version must be newer than the latest live version' using errcode = '22023';
  end if;
  if p_build is not null and exists (
    select 1 from public.app_version_releases
    where platform = p_platform and channel = p_channel and build >= p_build
  ) then
    raise exception 'Build number must increase for this platform and channel' using errcode = '22023';
  end if;
  v_mode := case
    when v_latest.id is null or v_major > v_latest.major then 'required'
    when v_minor > v_latest.minor and not p_minor_optional then 'required'
    else 'optional'
  end;
  insert into public.app_version_releases (
    platform, channel, version, build, update_mode, release_notes, store_url
  ) values (
    p_platform, p_channel, p_version, p_build, v_mode,
    coalesce(p_release_notes, ''), p_store_url
  ) returning * into v_result;
  return v_result;
end;
$$;
