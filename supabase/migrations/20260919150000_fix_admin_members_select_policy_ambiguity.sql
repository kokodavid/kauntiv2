-- 20260914180000_fix_admin_members_policy_ambiguity.sql qualified the
-- INSERT and UPDATE policies on admin_members, but missed the SELECT
-- policy "Admins can read their own membership", which still references
-- `user_id = auth.uid()` unqualified. Postgres also evaluates SELECT
-- policies during `insert ... on conflict (user_id) do update` (to check
-- visibility of the conflicting row), and at that point both
-- admin_members and the `excluded` pseudo-row are in scope for the same
-- check -- so the unqualified `user_id` is ambiguous there too, and
-- invite_admin_member_dashboard still surfaces "column reference
-- "user_id" is ambiguous" when inviting an admin whose email already has
-- an app account. Qualifying this last unqualified reference fixes it.

drop policy if exists "Admins can read their own membership"
  on public.admin_members;

create policy "Admins can read their own membership"
  on public.admin_members
  for select
  to authenticated
  using (admin_members.user_id = auth.uid());
