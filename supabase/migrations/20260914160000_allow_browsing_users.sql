-- Let the dashboard browse app users without requiring a search term
-- first. search_users_dashboard previously required a non-blank query;
-- now a blank query returns the most recently joined users instead of
-- erroring, so the Users page can show a list on load.

create or replace function public.search_users_dashboard(p_query text default null)
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
  where v_query = ''
    or auth_user.email ilike '%' || v_query || '%'
    or profile.handle ilike '%' || v_query || '%'
    or profile.display_name ilike '%' || v_query || '%'
  order by auth_user.created_at desc
  limit 50;
end;
$$;

revoke execute on function public.search_users_dashboard(text) from public;
grant execute on function public.search_users_dashboard(text) to authenticated;
