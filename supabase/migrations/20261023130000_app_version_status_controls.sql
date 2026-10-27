create or replace function public.set_app_version_release_status_dashboard(
  p_release_id uuid,
  p_active boolean
) returns public.app_version_releases
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_release public.app_version_releases%rowtype;
begin
  if coalesce(public.current_admin_role() not in ('owner', 'admin'), true) then
    raise exception 'Owner or admin access required' using errcode = '42501';
  end if;
  if p_active is null then
    raise exception 'Active status is required' using errcode = '22023';
  end if;

  select * into v_release
  from public.app_version_releases
  where id = p_release_id
  for update;

  if v_release.id is null or v_release.status = 'draft' then
    raise exception 'Only a published release can be activated or deactivated' using errcode = '22023';
  end if;

  if p_active and exists (
    select 1
    from public.app_version_releases newer
    where newer.platform = v_release.platform
      and newer.channel = v_release.channel
      and newer.status = 'live'
      and (newer.major, newer.minor, newer.patch) > (v_release.major, v_release.minor, v_release.patch)
  ) then
    raise exception 'Cannot activate an older release while a newer release is active' using errcode = '22023';
  end if;

  update public.app_version_releases
  set status = case when p_active then 'live' else 'withdrawn' end
  where id = p_release_id
  returning * into v_release;
  return v_release;
end;
$$;

revoke all on function public.set_app_version_release_status_dashboard(uuid, boolean) from public;
grant execute on function public.set_app_version_release_status_dashboard(uuid, boolean) to authenticated;
