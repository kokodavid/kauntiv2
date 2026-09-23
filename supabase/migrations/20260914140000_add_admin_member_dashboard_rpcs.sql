-- Admin member management for the dashboard.
--
-- auth.users is never queryable from the client, so the dashboard cannot
-- resolve an invite email to a user id, or show member emails, on its own.
-- These SECURITY DEFINER RPCs close that gap while re-enforcing the same
-- authorization rules already codified in admin_members' RLS policies
-- (can_manage_admin_member), since SECURITY DEFINER bypasses RLS.

create or replace function public.list_admin_members_dashboard()
returns table (
  user_id uuid,
  email text,
  role public.admin_role,
  status text,
  county_scope smallint[],
  invited_by uuid,
  invited_by_email text,
  created_at timestamptz,
  updated_at timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.can_manage_admins() then
    raise exception 'Viewing admin members requires owner or admin access'
      using errcode = '42501';
  end if;

  return query
  select
    member.user_id,
    member_user.email::text,
    member.role,
    member.status,
    member.county_scope,
    member.invited_by,
    inviter_user.email::text,
    member.created_at,
    member.updated_at
  from public.admin_members member
  join auth.users member_user on member_user.id = member.user_id
  left join auth.users inviter_user on inviter_user.id = member.invited_by
  order by public.admin_role_rank(member.role) desc, member.created_at asc;
end;
$$;

create or replace function public.invite_admin_member_dashboard(
  p_email text,
  p_role public.admin_role,
  p_county_scope smallint[] default null
)
returns table (
  user_id uuid,
  email text,
  role public.admin_role,
  status text,
  county_scope smallint[],
  invited_by uuid,
  invited_by_email text,
  created_at timestamptz,
  updated_at timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_target_user auth.users;
  v_caller uuid := auth.uid();
begin
  if not public.can_manage_admin_member(p_role) then
    raise exception 'You are not permitted to invite a member with that role'
      using errcode = '42501';
  end if;

  if p_email is null or btrim(p_email) = '' then
    raise exception 'Email is required'
      using errcode = '22023';
  end if;

  select auth_user.* into v_target_user
  from auth.users auth_user
  where lower(auth_user.email) = lower(btrim(p_email))
  limit 1;

  if v_target_user.id is null then
    raise exception 'No account was found for that email. The person must sign in to the app at least once before they can be invited.'
      using errcode = 'P0002';
  end if;

  if v_target_user.id = v_caller then
    raise exception 'You cannot invite yourself'
      using errcode = '42501';
  end if;

  insert into public.admin_members (user_id, role, status, county_scope, invited_by)
  values (v_target_user.id, p_role, 'invited', p_county_scope, v_caller)
  on conflict (user_id) do update
  set role = excluded.role,
      status = 'invited',
      county_scope = excluded.county_scope,
      invited_by = excluded.invited_by
  where public.can_manage_admin_member(public.admin_members.role)
    and public.admin_members.user_id <> v_caller;

  return query
  select
    member.user_id,
    member_user.email::text,
    member.role,
    member.status,
    member.county_scope,
    member.invited_by,
    inviter_user.email::text,
    member.created_at,
    member.updated_at
  from public.admin_members member
  join auth.users member_user on member_user.id = member.user_id
  left join auth.users inviter_user on inviter_user.id = member.invited_by
  where member.user_id = v_target_user.id;
end;
$$;

create or replace function public.update_admin_member_dashboard(
  p_user_id uuid,
  p_role public.admin_role,
  p_status text
)
returns table (
  user_id uuid,
  email text,
  role public.admin_role,
  status text,
  county_scope smallint[],
  invited_by uuid,
  invited_by_email text,
  created_at timestamptz,
  updated_at timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_caller uuid := auth.uid();
  v_existing_role public.admin_role;
begin
  if p_user_id = v_caller then
    raise exception 'You cannot change your own admin membership'
      using errcode = '42501';
  end if;

  if p_status not in ('invited', 'active', 'disabled') then
    raise exception 'Status must be invited, active, or disabled'
      using errcode = '22023';
  end if;

  select member.role into v_existing_role
  from public.admin_members member
  where member.user_id = p_user_id;

  if v_existing_role is null then
    raise exception 'Admin member was not found'
      using errcode = 'P0002';
  end if;

  if not public.can_manage_admin_member(v_existing_role) then
    raise exception 'You are not permitted to manage this member'
      using errcode = '42501';
  end if;

  if not public.can_manage_admin_member(p_role) then
    raise exception 'You are not permitted to assign that role'
      using errcode = '42501';
  end if;

  update public.admin_members member
  set role = p_role,
      status = p_status
  where member.user_id = p_user_id;

  return query
  select
    member.user_id,
    member_user.email::text,
    member.role,
    member.status,
    member.county_scope,
    member.invited_by,
    inviter_user.email::text,
    member.created_at,
    member.updated_at
  from public.admin_members member
  join auth.users member_user on member_user.id = member.user_id
  left join auth.users inviter_user on inviter_user.id = member.invited_by
  where member.user_id = p_user_id;
end;
$$;

revoke execute on function public.list_admin_members_dashboard() from public;
revoke execute on function public.invite_admin_member_dashboard(text, public.admin_role, smallint[]) from public;
revoke execute on function public.update_admin_member_dashboard(uuid, public.admin_role, text) from public;

grant execute on function public.list_admin_members_dashboard() to authenticated;
grant execute on function public.invite_admin_member_dashboard(text, public.admin_role, smallint[]) to authenticated;
grant execute on function public.update_admin_member_dashboard(uuid, public.admin_role, text) to authenticated;
