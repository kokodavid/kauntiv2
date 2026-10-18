create table if not exists public.app_version_releases (
  id uuid primary key default gen_random_uuid(),
  platform text not null check (platform in ('ios', 'android')),
  channel text not null check (channel in ('development', 'beta', 'production')),
  version text not null check (version ~ '^(0|[1-9][0-9]{0,8})\.(0|[1-9][0-9]{0,8})\.(0|[1-9][0-9]{0,8})$'),
  major integer generated always as (split_part(version, '.', 1)::integer) stored,
  minor integer generated always as (split_part(version, '.', 2)::integer) stored,
  patch integer generated always as (split_part(version, '.', 3)::integer) stored,
  build integer not null check (build > 0),
  update_mode text not null check (update_mode in ('required', 'optional')),
  release_notes text not null default '' check (char_length(release_notes) <= 4000),
  store_url text not null check (store_url like 'https://%'),
  status text not null default 'draft' check (status in ('draft', 'live', 'withdrawn')),
  created_by uuid not null default auth.uid() references auth.users(id),
  created_at timestamptz not null default now(),
  published_at timestamptz,
  unique (platform, channel, version),
  unique (platform, channel, build)
);

create index app_version_releases_live_lookup
  on public.app_version_releases (platform, channel, major desc, minor desc, patch desc)
  where status = 'live';

alter table public.app_version_releases enable row level security;
revoke all on public.app_version_releases from anon, authenticated;

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
  return jsonb_build_object(
    'latest_version', v_latest.version,
    'required_version', v_required.version,
    'available', (v_major, v_minor, v_patch) < (v_latest.major, v_latest.minor, v_latest.patch),
    'required', v_required.id is not null
      and (v_major, v_minor, v_patch) < (v_required.major, v_required.minor, v_required.patch),
    'store_url', v_latest.store_url,
    'release_notes', v_latest.release_notes
  );
end;
$$;

create or replace function public.list_app_version_releases_dashboard()
returns setof public.app_version_releases
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if coalesce(public.current_admin_role() not in ('owner', 'admin'), true) then
    raise exception 'Owner or admin access required' using errcode = '42501';
  end if;
  return query select * from public.app_version_releases
    order by created_at desc;
end;
$$;

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
     or p_build is null or p_store_url is null or p_minor_optional is null
     or p_platform not in ('ios', 'android')
     or p_channel not in ('development', 'beta', 'production')
     or p_version !~ '^(0|[1-9][0-9]{0,8})\.(0|[1-9][0-9]{0,8})\.(0|[1-9][0-9]{0,8})$'
     or p_build <= 0
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
  if exists (
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

create or replace function public.publish_app_version_release_dashboard(p_release_id uuid)
returns public.app_version_releases
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_release public.app_version_releases%rowtype;
  v_latest public.app_version_releases%rowtype;
begin
  if coalesce(public.current_admin_role() not in ('owner', 'admin'), true) then
    raise exception 'Owner or admin access required' using errcode = '42501';
  end if;
  select * into v_release from public.app_version_releases where id = p_release_id for update;
  if v_release.id is null or v_release.status <> 'draft' then
    raise exception 'Only an existing draft can be published' using errcode = '22023';
  end if;
  perform pg_advisory_xact_lock(
    hashtextextended('app-version:' || v_release.platform || ':' || v_release.channel, 0)
  );
  select * into v_latest from public.app_version_releases
    where platform = v_release.platform and channel = v_release.channel and status = 'live'
    order by major desc, minor desc, patch desc limit 1;
  if v_latest.id is not null and
     (v_release.major, v_release.minor, v_release.patch) <= (v_latest.major, v_latest.minor, v_latest.patch) then
    raise exception 'Release version must be newer than the latest live version' using errcode = '22023';
  end if;
  update public.app_version_releases set status = 'live', published_at = now()
    where id = p_release_id returning * into v_release;
  return v_release;
end;
$$;

create or replace function public.delete_app_version_release_draft_dashboard(p_release_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if coalesce(public.current_admin_role() not in ('owner', 'admin'), true) then
    raise exception 'Owner or admin access required' using errcode = '42501';
  end if;
  delete from public.app_version_releases where id = p_release_id and status = 'draft';
  if not found then
    raise exception 'Only an existing draft can be deleted' using errcode = '22023';
  end if;
end;
$$;

revoke all on function public.get_app_update_policy(text, text, text) from public;
revoke all on function public.list_app_version_releases_dashboard() from public;
revoke all on function public.create_app_version_release_dashboard(text, text, text, integer, text, text, boolean) from public;
revoke all on function public.publish_app_version_release_dashboard(uuid) from public;
revoke all on function public.delete_app_version_release_draft_dashboard(uuid) from public;
grant execute on function public.get_app_update_policy(text, text, text) to anon, authenticated;
grant execute on function public.list_app_version_releases_dashboard() to authenticated;
grant execute on function public.create_app_version_release_dashboard(text, text, text, integer, text, text, boolean) to authenticated;
grant execute on function public.publish_app_version_release_dashboard(uuid) to authenticated;
grant execute on function public.delete_app_version_release_draft_dashboard(uuid) to authenticated;
