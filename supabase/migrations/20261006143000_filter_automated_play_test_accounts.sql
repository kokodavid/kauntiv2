-- Play pre-launch testing can create Google accounts whose email local part
-- ends with a dot and five digits (for example, person.49220@gmail.com).
-- Keep those auth records, but do not mix unengaged automated accounts into
-- the normal dashboard audiences. Accounts with genuine Kaunti47 activity
-- remain visible even if their address happens to match this signature.

drop function if exists public.search_users_dashboard(text, text);

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
  has_meaningful_activity boolean,
  is_automated_test_account boolean
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

  if v_audience not in ('engaged', 'unengaged', 'automated', 'hidden') then
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
      public.dashboard_user_has_meaningful_activity(auth_user.id) as has_meaningful_activity,
      auth_user.email ~* '^[^@]+[.][0-9]{5}@[[:alnum:].-]+$' as is_automated_test_account
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
    when 'engaged' then
      candidate.dashboard_visibility <> 'hidden'
      and candidate.has_meaningful_activity
    when 'unengaged' then
      candidate.dashboard_visibility <> 'hidden'
      and not candidate.has_meaningful_activity
      and not candidate.is_automated_test_account
    when 'automated' then
      candidate.dashboard_visibility <> 'hidden'
      and not candidate.has_meaningful_activity
      and candidate.is_automated_test_account
    when 'hidden' then candidate.dashboard_visibility = 'hidden'
  end
  order by candidate.created_at desc
  limit 50;
end;
$$;

revoke execute on function public.search_users_dashboard(text, text) from public;
grant execute on function public.search_users_dashboard(text, text) to authenticated;
