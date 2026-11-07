-- Preserve existing RPC contracts while allowing required patch releases.
-- Only drafts are changed; published versions remain immutable.
create or replace function public.save_app_version_release_dashboard(
  p_platform text,
  p_channel text,
  p_version text,
  p_build integer,
  p_store_url text,
  p_release_notes text default '',
  p_require_update boolean default null,
  p_release_id uuid default null
) returns public.app_version_releases
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_release public.app_version_releases%rowtype;
begin
  if coalesce(public.current_admin_role() not in ('owner', 'admin'), true) then
    raise exception 'Owner or admin access required' using errcode = '42501';
  end if;

  -- Existing functions validate metadata, take track/row locks, and keep
  -- first/major releases required even if an optional policy is requested.
  if p_release_id is null then
    v_release := public.create_app_version_release_dashboard(
      p_platform, p_channel, p_version, p_build, p_store_url,
      p_release_notes, p_require_update is false
    );
  else
    v_release := public.update_app_version_release_draft_dashboard(
      p_release_id, p_platform, p_channel, p_version, p_build, p_store_url,
      p_release_notes, p_require_update is false
    );
  end if;

  if p_require_update is true and v_release.update_mode <> 'required' then
    update public.app_version_releases
      set update_mode = 'required'
      where id = v_release.id and status = 'draft'
      returning * into v_release;
  end if;
  return v_release;
end;
$$;

revoke all on function public.save_app_version_release_dashboard(text, text, text, integer, text, text, boolean, uuid)
  from public, anon;
grant execute on function public.save_app_version_release_dashboard(text, text, text, integer, text, text, boolean, uuid)
  to authenticated;
