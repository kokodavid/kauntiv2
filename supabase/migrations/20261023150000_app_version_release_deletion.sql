create or replace function public.delete_app_version_release_dashboard(
  p_release_id uuid
) returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_status text;
begin
  if coalesce(public.current_admin_role() not in ('owner', 'admin'), true) then
    raise exception 'Owner or admin access required' using errcode = '42501';
  end if;

  select status into v_status
  from public.app_version_releases
  where id = p_release_id
  for update;

  if v_status is null then
    raise exception 'Release not found' using errcode = '22023';
  end if;
  if v_status not in ('draft', 'withdrawn') then
    raise exception 'Only draft or withdrawn releases can be deleted' using errcode = '22023';
  end if;

  delete from public.app_version_releases where id = p_release_id;
end;
$$;

revoke all on function public.delete_app_version_release_dashboard(uuid) from public;
grant execute on function public.delete_app_version_release_dashboard(uuid) to authenticated;
