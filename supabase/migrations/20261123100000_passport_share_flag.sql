-- Passport share switch ------------------------------------------------------
-- One dashboard-controlled flag decides whether the app offers "Share your
-- Passport" at all. Off by default, read by the app on start-up and when the
-- Passport opens, and switched from Feature settings.
--
-- The allowed keys are the union of every flag so far, including 'billing'
-- (feature/billing, not merged yet) so applying this in any order never drops
-- a key another migration added.

alter table public.app_feature_flags
  drop constraint if exists app_feature_flags_feature_key_check;
alter table public.app_feature_flags add constraint app_feature_flags_feature_key_check
  check (feature_key in (
    'county_news', 'public_trips_read', 'public_trips_publish',
    'place_photos', 'push_broadcasts', 'place_check_ins', 'ads', 'billing',
    'trip_plans', 'trip_plan_invites', 'trip_plan_links', 'passport_share'
  ));
insert into public.app_feature_flags (feature_key, enabled)
values ('passport_share', false)
on conflict (feature_key) do nothing;

create or replace function public.set_passport_share_enabled_dashboard(
  p_enabled boolean
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
begin
  if coalesce(public.current_admin_role() in ('owner', 'admin'), false) is not true then
    raise exception 'Owner or admin access required' using errcode = '42501';
  end if;
  if p_enabled is null then
    raise exception 'Enabled value is required' using errcode = '22004';
  end if;
  insert into public.app_feature_flags (feature_key, enabled, updated_at, updated_by)
  values ('passport_share', p_enabled, now(), auth.uid())
  on conflict (feature_key) do update
  set enabled = excluded.enabled,
      updated_at = excluded.updated_at,
      updated_by = excluded.updated_by;
  return p_enabled;
end;
$$;

revoke execute on function public.set_passport_share_enabled_dashboard(boolean)
  from public, anon;
grant execute on function public.set_passport_share_enabled_dashboard(boolean)
  to authenticated;
