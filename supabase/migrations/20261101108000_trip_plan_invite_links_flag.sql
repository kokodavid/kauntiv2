-- Invite links behind their own switch (`trip_plan_links`), off by default.
--
-- Plan sharing (`trip_plan_invites`) covers inviting people by username. Links
-- are a second, separate switch so the planner can launch with usernames only:
-- with it off, no link can be made, previewed or used (links already made stop
-- working), and the app hides the link section. Turn it on later with no
-- release.

alter table public.app_feature_flags
  drop constraint if exists app_feature_flags_feature_key_check;
alter table public.app_feature_flags add constraint app_feature_flags_feature_key_check
  check (feature_key in (
    'county_news', 'public_trips_read', 'public_trips_publish',
    'place_photos', 'push_broadcasts', 'place_check_ins', 'ads',
    'trip_plans', 'trip_plan_invites', 'trip_plan_links'
  ));
insert into public.app_feature_flags (feature_key, enabled)
values ('trip_plan_links', false)
on conflict (feature_key) do nothing;

create or replace function public.set_trip_plans_flag_dashboard(
  p_feature_key text,
  p_enabled boolean
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
begin
  if coalesce(public.current_admin_role() in ('owner', 'admin'), false) is not true then
    raise exception 'Owner or admin access required' using errcode = '42501';
  end if;
  if p_feature_key is null
     or p_feature_key not in ('trip_plans', 'trip_plan_invites', 'trip_plan_links') then
    raise exception 'Unknown planner switch' using errcode = '22023';
  end if;
  if p_enabled is null then
    raise exception 'Enabled value is required' using errcode = '22004';
  end if;
  insert into public.app_feature_flags (feature_key, enabled, updated_at, updated_by)
  values (p_feature_key, p_enabled, now(), auth.uid())
  on conflict (feature_key) do update
  set enabled = excluded.enabled,
      updated_at = excluded.updated_at,
      updated_by = excluded.updated_by;
  return p_enabled;
end;
$$;

-- Sharing must be on, and so must links, for anything that uses a link.
create function trip_plan_private.assert_links_enabled()
returns void
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  perform trip_plan_private.assert_invites_enabled();
  if not exists (select 1 from public.app_feature_flags f
      where f.feature_key = 'trip_plan_links' and f.enabled) then
    raise exception 'trip_plans_unavailable' using errcode = '42501';
  end if;
end $$;
revoke execute on function trip_plan_private.assert_links_enabled() from public;

-- Making a link ----------------------------------------------------------------
create or replace function public.create_trip_plan_invite(p_plan uuid, p_role text default 'editor')
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare v_limits jsonb; v_pro boolean; v_token text; v_expires timestamptz; v_id uuid;
begin
  perform trip_plan_private.assert_links_enabled();
  v_limits := trip_plan_private.assert_may_invite(p_plan, p_role);
  v_pro := (v_limits ->> 'roles')::boolean;
  if not v_pro then
    update public.trip_plan_invites set revoked_at = now()
    where plan_id = p_plan and revoked_at is null;
  end if;
  v_token := replace(gen_random_uuid()::text, '-', '');
  v_expires := now() + case when v_pro then interval '30 days' else interval '7 days' end;
  insert into public.trip_plan_invites (plan_id, token_hash, role, created_by, expires_at, max_uses)
  values (p_plan, trip_plan_private.invite_hash(v_token), p_role, auth.uid(), v_expires,
    case when v_pro then null else 1 end)
  returning id into v_id;
  return jsonb_build_object('id', v_id, 'token', v_token, 'role', p_role,
    'expires_at', v_expires);
end $$;

-- Opening a link ---------------------------------------------------------------
create or replace function public.preview_trip_plan_invite(p_token text)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare i public.trip_plan_invites; v_plan public.trip_plans; v_state text; v_handle text;
begin
  perform trip_plan_private.assert_links_enabled();
  select * into i from public.trip_plan_invites
  where token_hash = trip_plan_private.invite_hash(p_token);
  if not found then
    return jsonb_build_object('state', 'invalid');
  end if;
  select * into v_plan from public.trip_plans where id = i.plan_id;
  select handle into v_handle from public.quest_public_profiles where user_id = i.created_by;
  v_state := case
    when trip_plan_private.role_of(i.plan_id, auth.uid()) is not null then 'already_member'
    when i.revoked_at is not null then 'revoked'
    when i.expires_at <= now() then 'expired'
    when i.max_uses is not null and i.uses >= i.max_uses then 'full'
    when trip_plan_private.member_count(i.plan_id)
      >= (trip_plan_private.limits(v_plan.owner_id) ->> 'max_members')::integer then 'full'
    else 'ok' end;
  return jsonb_build_object('state', v_state,
    'plan_id', case when v_state in ('ok', 'already_member') then i.plan_id end,
    'title', case when v_state in ('ok', 'already_member') then v_plan.title end,
    'role', i.role, 'inviter_handle', v_handle);
end $$;

create or replace function public.join_trip_plan(p_token text)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare i public.trip_plan_invites; v_owner uuid; v_limits jsonb; v_role text;
begin
  perform trip_plan_private.assert_links_enabled();
  select * into i from public.trip_plan_invites
  where token_hash = trip_plan_private.invite_hash(p_token) for update;
  if not found or i.revoked_at is not null then
    raise exception 'trip_plan_invite_invalid' using errcode = 'P0002';
  end if;
  if trip_plan_private.role_of(i.plan_id, auth.uid()) is not null then
    return i.plan_id;
  end if;
  if i.expires_at <= now() then
    raise exception 'trip_plan_invite_expired' using errcode = '42501';
  end if;
  select owner_id into v_owner from public.trip_plans where id = i.plan_id;
  v_limits := trip_plan_private.limits(v_owner);
  -- A person already invited by name holds their seat; anyone else needs one.
  if not exists (select 1 from public.trip_plan_members
        where plan_id = i.plan_id and user_id = auth.uid())
     and (trip_plan_private.member_count(i.plan_id) >= (v_limits ->> 'max_members')::integer
       or (i.max_uses is not null and i.uses >= i.max_uses)) then
    raise exception 'trip_plan_invite_full' using errcode = '54000';
  end if;
  v_role := case when (v_limits ->> 'roles')::boolean then i.role else 'editor' end;
  insert into public.trip_plan_members (plan_id, user_id, role, status, invited_by, joined_at)
  values (i.plan_id, auth.uid(), v_role, 'joined', i.created_by, now())
  on conflict (plan_id, user_id) do update
    set status = 'joined', joined_at = now(), role = excluded.role;
  update public.trip_plan_invites set uses = uses + 1 where id = i.id;
  perform trip_plan_private.touch(i.plan_id);
  return i.plan_id;
end $$;
