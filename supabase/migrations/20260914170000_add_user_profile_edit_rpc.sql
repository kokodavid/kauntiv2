-- Let dashboard moderators fix a reported display name, handle, or
-- avatar on an app user's public profile. This intentionally does not
-- touch auth.users.email (that's the Auth login identity, not a profile
-- field -- editing it from here risks locking the person out) or any
-- app-internal state like home county, location mode, or county-visit
-- progress (that's the physically-verified data the whole app is built
-- on; an admin hand-editing it would undermine the trust mechanic).

create or replace function public.update_user_profile_dashboard(
  p_user_id uuid,
  p_display_name text default null,
  p_handle text default null,
  p_clear_avatar boolean default false
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
  v_display_name text;
  v_handle text;
begin
  if not public.can_moderate_users() then
    raise exception 'Editing users requires owner, admin, or moderator access'
      using errcode = '42501';
  end if;

  if not exists (select 1 from public.quest_public_profiles where user_id = p_user_id) then
    raise exception 'This user has no public profile to edit'
      using errcode = 'P0002';
  end if;

  if p_display_name is not null then
    v_display_name := btrim(p_display_name);

    if char_length(v_display_name) not between 1 and 80 then
      raise exception 'Display name must be 1-80 characters'
        using errcode = '22023';
    end if;
  end if;

  if p_handle is not null then
    v_handle := lower(btrim(p_handle));

    if v_handle !~ '^[a-z0-9][a-z0-9_-]{2,29}$' then
      raise exception 'Handle must be 3-30 characters: lowercase letters, numbers, hyphens, or underscores, starting with a letter or number'
        using errcode = '22023';
    end if;
  end if;

  begin
    update public.quest_public_profiles
    set display_name = coalesce(v_display_name, display_name),
        handle = coalesce(v_handle, handle),
        avatar_url = case when p_clear_avatar then null else avatar_url end
    where user_id = p_user_id;
  exception
    when unique_violation then
      raise exception 'That handle is already taken'
        using errcode = '23505';
  end;

  return query select * from public.get_user_detail_dashboard(p_user_id);
end;
$$;

revoke execute on function public.update_user_profile_dashboard(uuid, text, text, boolean) from public;
grant execute on function public.update_user_profile_dashboard(uuid, text, text, boolean) to authenticated;
