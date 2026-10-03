-- Self-service account deletion (security plan §2, gap #2: "No
-- account-deletion path found"). Every user-owned table already
-- references auth.users(id) on delete cascade (journeys, journey_points,
-- journey_media, profiles, quest_public_profiles, county_visits,
-- friendships, quest_members, ...), so one delete from auth.users clears
-- all of it in a single transaction. Nothing-to-build there; the actual
-- gap was that no caller was ever allowed to trigger it.
--
-- `security definer`, not `security invoker`: an authenticated client has
-- no privilege to delete from auth.users directly (it's owned by
-- supabase_auth_admin, not postgres), so this has to run as this
-- function's owner. This is the standard self-service-deletion pattern
-- for Supabase projects, but it assumes the migration role (normally
-- `postgres`) has DELETE on auth.users -- true for most Supabase
-- projects, but verify it against this project's actual role grants
-- before relying on it in production. If it isn't, the fallback is a
-- server-side Edge Function calling `auth.admin.deleteUser()` with the
-- service-role key instead of a direct SQL delete.
--
-- Known gap this migration does NOT close: Storage objects (journey-media,
-- avatars) are not foreign-keyed to auth.users, so a deleted account's
-- uploaded files are orphaned, not deleted, by this RPC. A follow-up
-- (storage.objects cleanup by owner prefix, run before the auth.users
-- delete) is needed before this is a complete right-to-erasure path.
create or replace function public.delete_account()
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then
    raise exception 'Not signed in' using errcode = '28000';
  end if;

  delete from auth.users where id = v_user_id;
end;
$$;

revoke execute on function public.delete_account() from public;
grant execute on function public.delete_account() to authenticated;
