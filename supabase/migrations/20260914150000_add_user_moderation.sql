-- App user management (Phase A): lookup, view, suspend/disable.
--
-- Scope: dashboard-and-backend only. There is intentionally no delete
-- policy and no destructive action here -- moderation is "suspend", which
-- blocks nothing on its own yet but records intent and gives the app a
-- status to check later. Deletion/export requests are a separate Phase B
-- that requires changes to the Flutter app (data_privacy_screen.dart) and
-- a request-submission flow that does not exist yet; do not build that
-- here without separate sign-off.

create table if not exists public.user_moderation_status (
  user_id uuid primary key references auth.users (id) on delete cascade,
  status text not null default 'active'
    check (status in ('active', 'suspended')),
  reason text,
  set_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.user_moderation_status enable row level security;

create or replace function public.can_moderate_users()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.current_admin_role() in ('owner', 'admin', 'moderator');
$$;

create or replace function public.set_user_moderation_status_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists set_user_moderation_status_updated_at
  on public.user_moderation_status;

create trigger set_user_moderation_status_updated_at
  before update on public.user_moderation_status
  for each row
  execute function public.set_user_moderation_status_updated_at();

drop policy if exists "Moderators can read user moderation status"
  on public.user_moderation_status;

create policy "Moderators can read user moderation status"
  on public.user_moderation_status
  for select
  to authenticated
  using (public.can_moderate_users());

-- No insert/update/delete policy. Every write goes through
-- set_user_status_dashboard so the self-targeting and role checks below
-- are always enforced, and so status changes stay auditable via `set_by`.

revoke execute on function public.can_moderate_users() from public;
grant execute on function public.can_moderate_users() to authenticated;

grant select on public.user_moderation_status to authenticated;

-- search_users_dashboard: find app users by email, handle, or display name.

create or replace function public.search_users_dashboard(p_query text)
returns table (
  user_id uuid,
  email text,
  display_name text,
  handle text,
  avatar_url text,
  status text,
  created_at timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_query text := btrim(coalesce(p_query, ''));
begin
  if not public.can_moderate_users() then
    raise exception 'Viewing users requires owner, admin, or moderator access'
      using errcode = '42501';
  end if;

  if v_query = '' then
    raise exception 'Search query is required'
      using errcode = '22023';
  end if;

  return query
  select
    auth_user.id,
    auth_user.email::text,
    profile.display_name,
    profile.handle,
    profile.avatar_url,
    coalesce(moderation.status, 'active'),
    auth_user.created_at
  from auth.users auth_user
  left join public.quest_public_profiles profile on profile.user_id = auth_user.id
  left join public.user_moderation_status moderation on moderation.user_id = auth_user.id
  where auth_user.email ilike '%' || v_query || '%'
    or profile.handle ilike '%' || v_query || '%'
    or profile.display_name ilike '%' || v_query || '%'
  order by auth_user.created_at desc
  limit 25;
end;
$$;

-- get_user_detail_dashboard: full profile + county-progress stats for one user.

create or replace function public.get_user_detail_dashboard(p_user_id uuid)
returns table (
  user_id uuid,
  email text,
  display_name text,
  handle text,
  avatar_url text,
  home_county_id smallint,
  home_county_slug text,
  location_mode text,
  status text,
  status_reason text,
  status_set_by_email text,
  status_updated_at timestamptz,
  created_at timestamptz,
  counties_explored bigint,
  counties_passed_through bigint
)
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.can_moderate_users() then
    raise exception 'Viewing users requires owner, admin, or moderator access'
      using errcode = '42501';
  end if;

  return query
  select
    auth_user.id,
    auth_user.email::text,
    profile.display_name,
    profile.handle,
    profile.avatar_url,
    user_profile.home_county_id,
    user_profile.home_county_slug,
    user_profile.location_mode,
    coalesce(moderation.status, 'active'),
    moderation.reason,
    set_by_user.email::text,
    moderation.updated_at,
    auth_user.created_at,
    coalesce((
      select count(*) from public.county_visits visit
      where visit.user_id = auth_user.id and visit.state = 'explored'
    ), 0),
    coalesce((
      select count(*) from public.county_visits visit
      where visit.user_id = auth_user.id and visit.state = 'passed_through'
    ), 0)
  from auth.users auth_user
  left join public.quest_public_profiles profile on profile.user_id = auth_user.id
  left join public.profiles user_profile on user_profile.id = auth_user.id
  left join public.user_moderation_status moderation on moderation.user_id = auth_user.id
  left join auth.users set_by_user on set_by_user.id = moderation.set_by
  where auth_user.id = p_user_id;

  if not found then
    raise exception 'User was not found'
      using errcode = 'P0002';
  end if;
end;
$$;

-- set_user_status_dashboard: suspend or reactivate an app user's account.

create or replace function public.set_user_status_dashboard(
  p_user_id uuid,
  p_status text,
  p_reason text default null
)
returns table (
  user_id uuid,
  email text,
  display_name text,
  handle text,
  avatar_url text,
  home_county_id smallint,
  home_county_slug text,
  location_mode text,
  status text,
  status_reason text,
  status_set_by_email text,
  status_updated_at timestamptz,
  created_at timestamptz,
  counties_explored bigint,
  counties_passed_through bigint
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_caller uuid := auth.uid();
begin
  if not public.can_moderate_users() then
    raise exception 'Managing users requires owner, admin, or moderator access'
      using errcode = '42501';
  end if;

  if p_user_id = v_caller then
    raise exception 'You cannot change your own account status'
      using errcode = '42501';
  end if;

  if p_status not in ('active', 'suspended') then
    raise exception 'Status must be active or suspended'
      using errcode = '22023';
  end if;

  if not exists (select 1 from auth.users where id = p_user_id) then
    raise exception 'User was not found'
      using errcode = 'P0002';
  end if;

  insert into public.user_moderation_status (user_id, status, reason, set_by)
  values (p_user_id, p_status, p_reason, v_caller)
  on conflict (user_id) do update
  set status = excluded.status,
      reason = excluded.reason,
      set_by = excluded.set_by;

  return query select * from public.get_user_detail_dashboard(p_user_id);
end;
$$;

revoke execute on function public.search_users_dashboard(text) from public;
revoke execute on function public.get_user_detail_dashboard(uuid) from public;
revoke execute on function public.set_user_status_dashboard(uuid, text, text) from public;

grant execute on function public.search_users_dashboard(text) to authenticated;
grant execute on function public.get_user_detail_dashboard(uuid) to authenticated;
grant execute on function public.set_user_status_dashboard(uuid, text, text) to authenticated;
