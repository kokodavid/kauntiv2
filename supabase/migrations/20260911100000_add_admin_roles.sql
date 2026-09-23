-- Admin dashboard access control.
--
-- Supabase Auth owns identity. This table owns dashboard authorization and is
-- intentionally separate from public.profiles, which remains user-facing app
-- profile data.

do $$
begin
  if not exists (
    select 1 from pg_type
    where typnamespace = 'public'::regnamespace
      and typname = 'admin_role'
  ) then
    create type public.admin_role as enum (
      'owner',
      'admin',
      'editor',
      'moderator',
      'viewer'
    );
  end if;
end
$$;

create table if not exists public.admin_members (
  user_id uuid primary key references auth.users (id) on delete cascade,
  role public.admin_role not null,
  status text not null default 'active'
    check (status in ('invited', 'active', 'disabled')),
  county_scope smallint[],
  invited_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (
    county_scope is null
    or county_scope <@ array[
      1, 2, 3, 4, 5, 6, 7, 8, 9, 10,
      11, 12, 13, 14, 15, 16, 17, 18, 19, 20,
      21, 22, 23, 24, 25, 26, 27, 28, 29, 30,
      31, 32, 33, 34, 35, 36, 37, 38, 39, 40,
      41, 42, 43, 44, 45, 46, 47
    ]::smallint[]
  )
);

create index if not exists admin_members_status_role_idx
  on public.admin_members (status, role);

alter table public.admin_members enable row level security;

create or replace function public.admin_role_rank(p_role public.admin_role)
returns integer
language sql
immutable
set search_path = public
as $$
  select case p_role
    when 'owner' then 50
    when 'admin' then 40
    when 'editor' then 30
    when 'moderator' then 20
    when 'viewer' then 10
    else 0
  end;
$$;

create or replace function public.current_admin_role()
returns public.admin_role
language sql
stable
security definer
set search_path = public
as $$
  select admin.role
  from public.admin_members admin
  where admin.user_id = auth.uid()
    and admin.status = 'active'
  limit 1;
$$;

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.current_admin_role() is not null;
$$;

create or replace function public.has_admin_role(p_minimum_role public.admin_role)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    public.admin_role_rank(public.current_admin_role())
      >= public.admin_role_rank(p_minimum_role),
    false
  );
$$;

create or replace function public.can_manage_admins()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.current_admin_role() in ('owner', 'admin');
$$;

create or replace function public.can_manage_admin_member(p_target_role public.admin_role)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select case public.current_admin_role()
    when 'owner' then true
    when 'admin' then p_target_role in ('editor', 'moderator', 'viewer')
    else false
  end;
$$;

create or replace function public.set_admin_members_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists set_admin_members_updated_at
  on public.admin_members;

create trigger set_admin_members_updated_at
  before update on public.admin_members
  for each row
  execute function public.set_admin_members_updated_at();

drop policy if exists "Admins can read their own membership"
  on public.admin_members;

create policy "Admins can read their own membership"
  on public.admin_members
  for select
  to authenticated
  using (user_id = auth.uid());

drop policy if exists "Owners and admins can read admin memberships"
  on public.admin_members;

create policy "Owners and admins can read admin memberships"
  on public.admin_members
  for select
  to authenticated
  using (public.can_manage_admins());

drop policy if exists "Owners and admins can invite manageable members"
  on public.admin_members;

create policy "Owners and admins can invite manageable members"
  on public.admin_members
  for insert
  to authenticated
  with check (
    public.can_manage_admin_member(role)
    and user_id <> auth.uid()
    and (invited_by is null or invited_by = auth.uid())
  );

drop policy if exists "Owners and admins can update manageable members"
  on public.admin_members;

create policy "Owners and admins can update manageable members"
  on public.admin_members
  for update
  to authenticated
  using (
    public.can_manage_admin_member(role)
    and user_id <> auth.uid()
  )
  with check (
    public.can_manage_admin_member(role)
    and user_id <> auth.uid()
  );

-- No delete policy. Dashboard removal should disable access by setting
-- status = 'disabled', preserving an audit-friendly membership record.

revoke execute on function public.admin_role_rank(public.admin_role) from public;
revoke execute on function public.current_admin_role() from public;
revoke execute on function public.is_admin() from public;
revoke execute on function public.has_admin_role(public.admin_role) from public;
revoke execute on function public.can_manage_admins() from public;
revoke execute on function public.can_manage_admin_member(public.admin_role) from public;

grant execute on function public.admin_role_rank(public.admin_role) to authenticated;
grant execute on function public.current_admin_role() to authenticated;
grant execute on function public.is_admin() to authenticated;
grant execute on function public.has_admin_role(public.admin_role) to authenticated;
grant execute on function public.can_manage_admins() to authenticated;
grant execute on function public.can_manage_admin_member(public.admin_role) to authenticated;

grant usage on type public.admin_role to authenticated;
grant select, insert, update on public.admin_members to authenticated;

insert into public.admin_members (user_id, role, status)
select auth_user.id, 'owner', 'active'
from auth.users auth_user
where lower(auth_user.email) = lower('kokodavid78@gmail.com')
on conflict (user_id) do update
set role = 'owner',
    status = 'active',
    updated_at = now();
