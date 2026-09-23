-- Companion to dev_seed_user_progress(): removes exactly what that
-- function inserts, for a user identified the same way (uid or email),
-- without touching anything a real signup/onboarding/detection run
-- would have written under its own logic (there's nothing to
-- distinguish "real" rows from "seeded" ones at the schema level, so
-- this clears the same tables/rows dev_seed_user_progress owns -- if
-- real geofence crossings have landed county_visits rows for this user
-- since seeding, this removes those too. Confirm that's what's wanted
-- before running it against an account with real detection history.)
--
-- Same security posture as dev_seed_user_progress: `security definer`,
-- service_role-only grant, never callable from the app's anon/
-- publishable key.
--
-- Usage (Supabase Dashboard -> SQL Editor):
--   select public.dev_clear_user_progress('someone@example.com');
--   select public.dev_clear_user_progress('someone@example.com', true); -- also clears home_county_id
create or replace function public.dev_clear_user_progress(
  p_identifier text,
  p_clear_home_county boolean default false
)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid;
  v_visits_deleted int;
  v_depth_deleted int;
begin
  if p_identifier ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' then
    select id into v_user_id from auth.users where id = p_identifier::uuid;
  else
    select id into v_user_id from auth.users where lower(email) = lower(p_identifier);
  end if;

  if v_user_id is null then
    raise exception 'dev_clear_user_progress: no auth.users row for %', p_identifier;
  end if;

  with deleted as (
    delete from public.county_visits where user_id = v_user_id returning 1
  )
  select count(*) into v_visits_deleted from deleted;

  with deleted as (
    delete from public.county_depth_progress where user_id = v_user_id returning 1
  )
  select count(*) into v_depth_deleted from deleted;

  if p_clear_home_county then
    update public.profiles set home_county_id = null where id = v_user_id;
  end if;

  return format(
    'Cleared %s county_visits + %s county_depth_progress row(s) for user %s.%s',
    v_visits_deleted,
    v_depth_deleted,
    v_user_id,
    case when p_clear_home_county then ' Home county also cleared.' else '' end
  );
end;
$$;

revoke execute on function public.dev_clear_user_progress(text, boolean) from public;
revoke execute on function public.dev_clear_user_progress(text, boolean) from authenticated;
grant execute on function public.dev_clear_user_progress(text, boolean) to service_role;
