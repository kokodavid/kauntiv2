-- Local/test database only. All fixture changes roll back; no release is published remotely.
begin;
insert into auth.users(id, email) values
  ('e3000000-0000-4000-8000-000000000001', 'release-owner@example.invalid'),
  ('e3000000-0000-4000-8000-000000000002', 'release-viewer@example.invalid');
insert into public.admin_members(user_id, role, status) values
  ('e3000000-0000-4000-8000-000000000001', 'owner', 'active'),
  ('e3000000-0000-4000-8000-000000000002', 'viewer', 'active');
delete from public.app_version_releases where channel = 'development';
select set_config('request.jwt.claim.sub', 'e3000000-0000-4000-8000-000000000001', true);
set local role authenticated;
do $$
declare r public.app_version_releases; p jsonb; forced_id uuid;
begin
  r := public.save_app_version_release_dashboard('android', 'development', '1.6.0', null, 'https://example.invalid/app', '', false);
  if r.update_mode <> 'required' then raise exception 'Initial release must be required'; end if;
  perform public.publish_app_version_release_dashboard(r.id);

  r := public.save_app_version_release_dashboard('android', 'development', '1.6.1', null, null);
  if r.update_mode <> 'optional' then raise exception 'Patch default changed'; end if;
  r := public.save_app_version_release_dashboard('android', 'development', '1.6.1', null, 'https://example.invalid/app', '', true, r.id);
  if r.update_mode <> 'required' then raise exception 'Required patch did not persist'; end if;
  r := public.save_app_version_release_dashboard('android', 'development', '1.6.1', null, 'https://example.invalid/app', '', false, r.id);
  if r.update_mode <> 'optional' then raise exception 'Draft could not return to optional'; end if;
  r := public.save_app_version_release_dashboard('android', 'development', '1.6.1', null, 'https://example.invalid/app', '', true, r.id);
  forced_id := r.id;
  perform public.publish_app_version_release_dashboard(r.id);
  p := public.get_app_update_policy('android', 'development', '1.6.0');
  if not (p->>'required')::boolean then raise exception 'Older mobile app did not require patch'; end if;
  p := public.get_app_update_policy('android', 'development', '1.6.1');
  if (p->>'required')::boolean then raise exception 'Current mobile app was blocked'; end if;

  r := public.save_app_version_release_dashboard('android', 'development', '1.6.2', null, 'https://example.invalid/app', '', false);
  perform public.publish_app_version_release_dashboard(r.id);
  p := public.get_app_update_policy('android', 'development', '1.6.1');
  if not (p->>'available')::boolean or (p->>'required')::boolean then raise exception 'Optional patch became required'; end if;
  p := public.get_app_update_policy('android', 'development', '1.6.0');
  if not (p->>'required')::boolean then raise exception 'Optional patch erased the required floor'; end if;

  r := public.save_app_version_release_dashboard('android', 'development', '1.7.0', null, 'https://example.invalid/app');
  if r.update_mode <> 'required' then raise exception 'Minor default changed'; end if;
  r := public.save_app_version_release_dashboard('android', 'development', '1.7.0', null, 'https://example.invalid/app', '', false, r.id);
  if r.update_mode <> 'optional' then raise exception 'Optional minor failed'; end if;
  r := public.save_app_version_release_dashboard('android', 'development', '1.7.0', null, 'https://example.invalid/app', '', true, r.id);
  if r.update_mode <> 'required' then raise exception 'Required minor failed'; end if;
  r := public.save_app_version_release_dashboard('android', 'development', '2.0.0', null, 'https://example.invalid/app', '', false);
  if r.update_mode <> 'required' then raise exception 'Major release became optional'; end if;
  begin
    perform public.save_app_version_release_dashboard('android', 'development', '1.6.1', null, null, '', false, forced_id);
    raise exception 'Published release was edited';
  exception when sqlstate '22023' then null; end;
end $$;

select set_config('request.jwt.claim.sub', 'e3000000-0000-4000-8000-000000000002', true);
do $$ begin
  begin
    perform public.save_app_version_release_dashboard('ios', 'development', '1.0.0', null, null, '', true);
    raise exception 'Viewer created a release';
  exception when insufficient_privilege then null; end;
end $$;
reset role;
set local role anon;
do $$ begin
  begin
    perform public.save_app_version_release_dashboard('ios', 'development', '1.0.0', null, null, '', true);
    raise exception 'Anonymous user created a release';
  exception when insufficient_privilege then null; end;
end $$;
rollback;
