-- Keep authentication records intact while allowing the dashboard to focus on
-- people who have actually used Kaunti47. This is especially useful for
-- automated Play pre-launch Google sign-ins, which create valid auth users but
-- generally never create any app activity.

create table if not exists public.dashboard_user_visibility_overrides (
  user_id uuid primary key references auth.users (id) on delete cascade,
  visibility text not null check (visibility in ('visible', 'hidden')),
  reason text,
  set_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.dashboard_user_visibility_overrides enable row level security;

create or replace function public.set_dashboard_user_visibility_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists set_dashboard_user_visibility_updated_at
  on public.dashboard_user_visibility_overrides;

create trigger set_dashboard_user_visibility_updated_at
  before update on public.dashboard_user_visibility_overrides
  for each row
  execute function public.set_dashboard_user_visibility_updated_at();

-- Do not expose the table directly. Dashboard writes use the audited RPC
-- below so role checks and the required hide reason cannot be bypassed.

create or replace function public.dashboard_user_has_meaningful_activity(p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select
    exists (
      select 1
      from public.profiles profile
      where profile.id = p_user_id
        and profile.home_county_id is not null
    )
    or exists (
      select 1 from public.county_visits visit where visit.user_id = p_user_id
    )
    or exists (
      select 1 from public.wishlist_items item where item.user_id = p_user_id
    )
    or exists (
      select 1 from public.journeys journey where journey.user_id = p_user_id
    );
$$;

revoke execute on function public.dashboard_user_has_meaningful_activity(uuid) from public;

drop function if exists public.search_users_dashboard(text);

create function public.search_users_dashboard(
  p_query text default null,
  p_audience text default 'engaged'
)
returns table (
  user_id uuid,
  email text,
  display_name text,
  handle text,
  avatar_url text,
  status text,
  created_at timestamptz,
  dashboard_visibility text,
  has_meaningful_activity boolean
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_query text := btrim(coalesce(p_query, ''));
  v_audience text := lower(btrim(coalesce(p_audience, 'engaged')));
begin
  if not public.can_moderate_users() then
    raise exception 'Viewing users requires owner, admin, or moderator access'
      using errcode = '42501';
  end if;

  if v_audience not in ('engaged', 'unengaged', 'hidden') then
    raise exception 'Unknown dashboard user audience: %', v_audience
      using errcode = '22023';
  end if;

  return query
  with candidates as (
    select
      auth_user.id,
      auth_user.email::text as email,
      profile.display_name,
      profile.handle,
      profile.avatar_url,
      coalesce(moderation.status, 'active') as status,
      auth_user.created_at,
      coalesce(visibility.visibility, 'visible') as dashboard_visibility,
      public.dashboard_user_has_meaningful_activity(auth_user.id) as has_meaningful_activity
    from auth.users auth_user
    left join public.quest_public_profiles profile on profile.user_id = auth_user.id
    left join public.user_moderation_status moderation on moderation.user_id = auth_user.id
    left join public.dashboard_user_visibility_overrides visibility on visibility.user_id = auth_user.id
    where v_query = ''
      or auth_user.email ilike '%' || v_query || '%'
      or profile.handle ilike '%' || v_query || '%'
      or profile.display_name ilike '%' || v_query || '%'
  )
  select *
  from candidates candidate
  where case v_audience
    when 'engaged' then candidate.dashboard_visibility <> 'hidden' and candidate.has_meaningful_activity
    when 'unengaged' then candidate.dashboard_visibility <> 'hidden' and not candidate.has_meaningful_activity
    when 'hidden' then candidate.dashboard_visibility = 'hidden'
  end
  order by candidate.created_at desc
  limit 50;
end;
$$;

revoke execute on function public.search_users_dashboard(text, text) from public;
grant execute on function public.search_users_dashboard(text, text) to authenticated;

create function public.get_dashboard_user_visibility(p_user_id uuid)
returns table (
  dashboard_visibility text,
  dashboard_visibility_reason text,
  dashboard_visibility_set_by_email text,
  dashboard_visibility_updated_at timestamptz,
  has_meaningful_activity boolean
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
    coalesce(visibility.visibility, 'visible'),
    visibility.reason,
    visibility_set_by_user.email::text,
    visibility.updated_at,
    public.dashboard_user_has_meaningful_activity(auth_user.id)
  from auth.users auth_user
  left join public.dashboard_user_visibility_overrides visibility on visibility.user_id = auth_user.id
  left join auth.users visibility_set_by_user on visibility_set_by_user.id = visibility.set_by
  where auth_user.id = p_user_id;

  if not found then
    raise exception 'User was not found'
      using errcode = 'P0002';
  end if;
end;
$$;

revoke execute on function public.get_dashboard_user_visibility(uuid) from public;
grant execute on function public.get_dashboard_user_visibility(uuid) to authenticated;

create or replace function public.set_user_dashboard_visibility(
  p_user_id uuid,
  p_visibility text,
  p_reason text default null
)
returns table (
  dashboard_visibility text,
  dashboard_visibility_reason text,
  dashboard_visibility_set_by_email text,
  dashboard_visibility_updated_at timestamptz,
  has_meaningful_activity boolean
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_visibility text := lower(btrim(coalesce(p_visibility, '')));
  v_reason text := nullif(btrim(p_reason), '');
  v_caller uuid := auth.uid();
begin
  if not public.can_moderate_users() then
    raise exception 'Changing dashboard visibility requires owner, admin, or moderator access'
      using errcode = '42501';
  end if;

  if v_visibility not in ('visible', 'hidden') then
    raise exception 'Visibility must be visible or hidden'
      using errcode = '22023';
  end if;

  if v_visibility = 'hidden' and v_reason is null then
    raise exception 'A reason is required when hiding an account from the dashboard'
      using errcode = '22023';
  end if;

  if not exists (select 1 from auth.users where id = p_user_id) then
    raise exception 'User was not found'
      using errcode = 'P0002';
  end if;

  insert into public.dashboard_user_visibility_overrides (user_id, visibility, reason, set_by)
  values (p_user_id, v_visibility, v_reason, v_caller)
  on conflict (user_id) do update
    set visibility = excluded.visibility,
        reason = excluded.reason,
        set_by = excluded.set_by;

  return query
  select * from public.get_dashboard_user_visibility(p_user_id);
end;
$$;

revoke execute on function public.set_user_dashboard_visibility(uuid, text, text) from public;
grant execute on function public.set_user_dashboard_visibility(uuid, text, text) to authenticated;
