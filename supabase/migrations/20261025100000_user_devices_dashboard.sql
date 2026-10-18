-- Dashboard: which app build and phone each user is on. Read from the push
-- device registry, so it covers users whose app has registered for push.
-- The token itself is never returned.

create or replace function public.get_user_devices_dashboard(p_user_id uuid)
returns table (
  platform text,
  flavor text,
  app_version text,
  os_permission text,
  last_seen_at timestamptz,
  created_at timestamptz
)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not public.can_moderate_users() then
    raise exception 'Viewing users requires owner, admin, or moderator access'
      using errcode = '42501';
  end if;

  return query
  select d.platform, d.flavor, d.app_version, d.os_permission,
         d.last_seen_at, d.created_at
  from public.push_devices d
  where d.user_id = p_user_id
  order by d.last_seen_at desc;
end;
$$;

revoke execute on function public.get_user_devices_dashboard(uuid) from public, anon;
grant execute on function public.get_user_devices_dashboard(uuid) to authenticated;
