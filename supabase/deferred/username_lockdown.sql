-- Lock down direct writes to usernames. Apply this once most people are on an
-- app build that changes usernames through set_username() (the build that
-- ships the username screens): until then, older builds still write `handle`
-- straight to the table from Edit Profile, and this would stop that.
--
-- After this, handles change only through set_username(), and profiles are
-- created only by the signup trigger and ensure_quest_public_profile().
drop policy if exists "Users can create their own quest public profile"
  on public.quest_public_profiles;
revoke insert, update on public.quest_public_profiles from authenticated;
grant update (display_name, avatar_url, updated_at)
  on public.quest_public_profiles to authenticated;
