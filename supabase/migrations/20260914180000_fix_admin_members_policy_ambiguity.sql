-- The insert/update RLS policies on admin_members added in
-- 20260911100000_add_admin_roles.sql reference `role` and `user_id`
-- unqualified. That's fine for a plain insert or update, but
-- invite_admin_member_dashboard's `insert ... on conflict (user_id) do
-- update` puts both the proposed row (exposed as `excluded`) and the
-- existing target row in scope for the same policy check at once, so the
-- unqualified column names become genuinely ambiguous between
-- `admin_members.role`/`user_id` and `excluded.role`/`user_id` --
-- surfacing to the dashboard as "column reference "user_id" is
-- ambiguous" when inviting an admin. Qualifying every reference to the
-- target table fixes it without changing the authorization logic.

drop policy if exists "Owners and admins can invite manageable members"
  on public.admin_members;

create policy "Owners and admins can invite manageable members"
  on public.admin_members
  for insert
  to authenticated
  with check (
    public.can_manage_admin_member(admin_members.role)
    and admin_members.user_id <> auth.uid()
    and (admin_members.invited_by is null or admin_members.invited_by = auth.uid())
  );

drop policy if exists "Owners and admins can update manageable members"
  on public.admin_members;

create policy "Owners and admins can update manageable members"
  on public.admin_members
  for update
  to authenticated
  using (
    public.can_manage_admin_member(admin_members.role)
    and admin_members.user_id <> auth.uid()
  )
  with check (
    public.can_manage_admin_member(admin_members.role)
    and admin_members.user_id <> auth.uid()
  );
