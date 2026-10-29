-- Trip plans with other people (S9): invite links, invite by username,
-- roles, leaving and handing over. Behind the `trip_plan_invites` switch
-- (on top of `trip_plans`). Limits always come from the plan's owner (D1):
-- Free is the owner and one buddy, owner invites only, editors only;
-- Pro is up to 6 people, owner and editors invite, view-only roles.

-- Invite links (D10: Free links last 7 days and one use; Pro links 30 days).
create table public.trip_plan_invites (
  id uuid primary key default gen_random_uuid(),
  plan_id uuid not null references public.trip_plans (id) on delete cascade,
  token_hash text not null unique,
  role text not null default 'editor' check (role in ('editor', 'viewer')),
  created_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null,
  max_uses integer check (max_uses is null or max_uses > 0),
  uses integer not null default 0,
  revoked_at timestamptz
);
create index trip_plan_invites_plan_idx on public.trip_plan_invites (plan_id);
alter table public.trip_plan_invites enable row level security;
-- No policies: only the functions below read or write invites.

-- Username searches in the last minute, for the rate limit (D7).
create table public.trip_plan_search_log (
  user_id uuid not null references auth.users (id) on delete cascade,
  at timestamptz not null default now()
);
create index trip_plan_search_log_idx on public.trip_plan_search_log (user_id, at);
alter table public.trip_plan_search_log enable row level security;

-- Helpers -------------------------------------------------------------------

-- Both switches must be on for anything to do with other people.
create function trip_plan_private.assert_invites_enabled()
returns void
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  perform trip_plan_private.assert_enabled();
  if auth.uid() is null then
    raise exception 'not_signed_in' using errcode = '42501';
  end if;
  if not exists (select 1 from public.app_feature_flags f
      where f.feature_key = 'trip_plan_invites' and f.enabled) then
    raise exception 'trip_plans_unavailable' using errcode = '42501';
  end if;
end $$;

-- People on a plan, counting those still invited (they hold a seat).
create function trip_plan_private.member_count(p_plan uuid)
returns integer
language sql
stable
security definer
set search_path = ''
as $$
  select count(*)::integer from public.trip_plan_members where plan_id = p_plan;
$$;

create function trip_plan_private.invite_hash(p_token text)
returns text
language sql
immutable
set search_path = ''
as $$
  select encode(sha256(convert_to(coalesce(p_token, ''), 'utf8')), 'hex');
$$;

-- D8: the owner goes (leaves, or the account is deleted). The plan passes to
-- the longest-standing editor, else the longest-standing other member; with
-- nobody else on it, it is deleted. Limits follow the new owner.
create function trip_plan_private.pass_on(p_plan uuid, p_leaving uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare v_next uuid;
begin
  select user_id into v_next from public.trip_plan_members
  where plan_id = p_plan and user_id <> p_leaving and status = 'joined'
  order by (role = 'editor') desc, joined_at nulls last, created_at
  limit 1;
  if v_next is null then
    delete from public.trip_plans where id = p_plan;
    return;
  end if;
  delete from public.trip_plan_members where plan_id = p_plan and user_id = p_leaving;
  update public.trip_plan_members set role = 'owner'
  where plan_id = p_plan and user_id = v_next;
  update public.trip_plans set owner_id = v_next, updated_at = now()
  where id = p_plan;
end $$;

create function trip_plan_private.on_user_deleted()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare r record;
begin
  for r in select plan_id from public.trip_plan_members
      where user_id = old.id and role = 'owner' loop
    perform trip_plan_private.pass_on(r.plan_id, old.id);
  end loop;
  return old;
end $$;

-- Runs before the cascade, so plans others are on survive the account.
create trigger trip_plans_pass_on_before_user_delete
  before delete on auth.users
  for each row execute function trip_plan_private.on_user_deleted();

-- Who may invite, and as what (D2). Raises unless allowed; returns the limits.
create function trip_plan_private.assert_may_invite(p_plan uuid, p_role text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare v_owner uuid; v_limits jsonb; v_roles boolean;
begin
  perform trip_plan_private.assert_invites_enabled();
  v_owner := trip_plan_private.assert_editor(p_plan);
  if p_role not in ('editor', 'viewer') then
    raise exception 'trip_plan_bad_input' using errcode = '22023';
  end if;
  v_limits := trip_plan_private.limits(v_owner);
  v_roles := (v_limits ->> 'roles')::boolean;
  if not v_roles then
    if auth.uid() <> v_owner then
      raise exception 'trip_plan_owner_only' using errcode = '42501';
    end if;
    if p_role = 'viewer' then
      raise exception 'trip_plan_limit_roles' using errcode = '54000';
    end if;
  end if;
  if trip_plan_private.member_count(p_plan) >= (v_limits ->> 'max_members')::integer then
    raise exception 'trip_plan_limit_members' using errcode = '54000';
  end if;
  return v_limits;
end $$;

revoke all on all functions in schema trip_plan_private from public;

-- Invite links --------------------------------------------------------------

-- Returns the link's token once; only its hash is kept. A Free plan has one
-- live link at a time (making a new one ends the old).
create function public.create_trip_plan_invite(p_plan uuid, p_role text default 'editor')
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare v_limits jsonb; v_pro boolean; v_token text; v_expires timestamptz; v_id uuid;
begin
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

create function public.revoke_trip_plan_invite(p_invite uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare v_plan uuid; v_by uuid;
begin
  select plan_id, created_by into v_plan, v_by
  from public.trip_plan_invites where id = p_invite;
  if v_plan is null then
    raise exception 'trip_plan_not_found' using errcode = 'P0002';
  end if;
  perform trip_plan_private.assert_invites_enabled();
  perform trip_plan_private.assert_editor(v_plan);
  if auth.uid() is distinct from v_by
     and trip_plan_private.role_of(v_plan, auth.uid()) <> 'owner' then
    raise exception 'trip_plan_owner_only' using errcode = '42501';
  end if;
  update public.trip_plan_invites set revoked_at = now()
  where id = p_invite and revoked_at is null;
end $$;

-- The live links of a plan, for the invite sheet.
create function public.list_trip_plan_invites(p_plan uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  perform trip_plan_private.assert_invites_enabled();
  perform trip_plan_private.assert_editor(p_plan);
  return (
    select coalesce(jsonb_agg(jsonb_build_object(
      'id', i.id, 'role', i.role, 'expires_at', i.expires_at,
      'uses', i.uses, 'max_uses', i.max_uses,
      'created_by_handle', qp.handle) order by i.created_at desc), '[]'::jsonb)
    from public.trip_plan_invites i
    left join public.quest_public_profiles qp on qp.user_id = i.created_by
    where i.plan_id = p_plan and i.revoked_at is null and i.expires_at > now()
      and (i.max_uses is null or i.uses < i.max_uses)
  );
end $$;

-- What a link says before the person joins: ok, already_member, expired,
-- revoked, full or invalid. The plan's name only shows for links that work.
create function public.preview_trip_plan_invite(p_token text)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare i public.trip_plan_invites; v_plan public.trip_plans; v_state text; v_handle text;
begin
  perform trip_plan_private.assert_invites_enabled();
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

-- Joins through a link. Joining a plan you are already on just returns it.
-- Joined plans never count toward your own limit (D6).
create function public.join_trip_plan(p_token text)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare i public.trip_plan_invites; v_owner uuid; v_limits jsonb; v_role text;
begin
  perform trip_plan_private.assert_invites_enabled();
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

-- Invite by username --------------------------------------------------------

-- Prefix search from 3 letters, 30 a minute (D7). Never yourself, never
-- suspended accounts, and nothing about what anyone does in the app.
create function public.search_usernames(p_prefix text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare v_prefix text; v_like text;
begin
  perform trip_plan_private.assert_invites_enabled();
  v_prefix := lower(btrim(coalesce(p_prefix, '')));
  if length(v_prefix) < 3 then
    return '[]'::jsonb;
  end if;
  delete from public.trip_plan_search_log
  where user_id = auth.uid() and at < now() - interval '1 minute';
  if (select count(*) from public.trip_plan_search_log where user_id = auth.uid()) >= 30 then
    raise exception 'trip_plan_rate_limited' using errcode = '54000';
  end if;
  insert into public.trip_plan_search_log (user_id) values (auth.uid());
  v_like := replace(replace(replace(v_prefix, '\', '\\'), '%', '\%'), '_', '\_') || '%';
  return (
    select coalesce(jsonb_agg(jsonb_build_object(
      'handle', t.handle, 'avatar_url', t.avatar_url) order by t.handle), '[]'::jsonb)
    from (
      select qp.handle, qp.avatar_url from public.quest_public_profiles qp
      where qp.user_id <> auth.uid() and qp.handle like v_like escape '\'
        and not exists (select 1 from public.user_moderation_status m
          where m.user_id = qp.user_id and m.status = 'suspended')
      order by qp.handle limit 8
    ) t
  );
end $$;

-- Holds a seat as `invited` until they accept or decline.
create function public.invite_trip_plan_user(p_plan uuid, p_handle text, p_role text default 'editor')
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare v_user uuid;
begin
  perform trip_plan_private.assert_may_invite(p_plan, p_role);
  select qp.user_id into v_user from public.quest_public_profiles qp
  where qp.handle = lower(btrim(p_handle))
    and not exists (select 1 from public.user_moderation_status m
      where m.user_id = qp.user_id and m.status = 'suspended');
  if v_user is null then
    raise exception 'trip_plan_user_not_found' using errcode = 'P0002';
  end if;
  if exists (select 1 from public.trip_plan_members
      where plan_id = p_plan and user_id = v_user) then
    raise exception 'trip_plan_already_member' using errcode = '23505';
  end if;
  insert into public.trip_plan_members (plan_id, user_id, role, status, invited_by)
  values (p_plan, v_user, p_role, 'invited', auth.uid());
  perform trip_plan_private.touch(p_plan);
end $$;

create function public.my_trip_plan_invitations()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  perform trip_plan_private.assert_invites_enabled();
  return (
    select coalesce(jsonb_agg(jsonb_build_object(
      'plan_id', m.plan_id, 'title', p.title, 'role', m.role,
      'inviter_handle', qp.handle, 'invited_at', m.created_at)
      order by m.created_at desc), '[]'::jsonb)
    from public.trip_plan_members m
    join public.trip_plans p on p.id = m.plan_id
    left join public.quest_public_profiles qp on qp.user_id = m.invited_by
    where m.user_id = auth.uid() and m.status = 'invited'
  );
end $$;

create function public.respond_trip_plan_invitation(p_plan uuid, p_accept boolean)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform trip_plan_private.assert_invites_enabled();
  if not exists (select 1 from public.trip_plan_members
      where plan_id = p_plan and user_id = auth.uid() and status = 'invited') then
    raise exception 'trip_plan_not_found' using errcode = 'P0002';
  end if;
  if p_accept then
    update public.trip_plan_members set status = 'joined', joined_at = now()
    where plan_id = p_plan and user_id = auth.uid();
    perform trip_plan_private.touch(p_plan);
  else
    delete from public.trip_plan_members
    where plan_id = p_plan and user_id = auth.uid();
  end if;
end $$;

-- People ----------------------------------------------------------------------

-- Only Pro plans have view-only members (roles).
create function public.set_trip_plan_member_role(p_plan uuid, p_user uuid, p_role text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform trip_plan_private.assert_invites_enabled();
  perform trip_plan_private.assert_owner(p_plan);
  if p_role not in ('editor', 'viewer') then
    raise exception 'trip_plan_bad_input' using errcode = '22023';
  end if;
  if not (trip_plan_private.limits(auth.uid()) ->> 'roles')::boolean then
    raise exception 'trip_plan_limit_roles' using errcode = '54000';
  end if;
  update public.trip_plan_members set role = p_role
  where plan_id = p_plan and user_id = p_user and role <> 'owner';
  if not found then
    raise exception 'trip_plan_not_found' using errcode = 'P0002';
  end if;
  perform trip_plan_private.touch(p_plan);
end $$;

create function public.remove_trip_plan_member(p_plan uuid, p_user uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform trip_plan_private.assert_invites_enabled();
  perform trip_plan_private.assert_owner(p_plan);
  delete from public.trip_plan_members
  where plan_id = p_plan and user_id = p_user and role <> 'owner';
  if not found then
    raise exception 'trip_plan_not_found' using errcode = 'P0002';
  end if;
  perform trip_plan_private.touch(p_plan);
end $$;

-- Anyone may leave. The owner leaving passes the plan on (D8).
create function public.leave_trip_plan(p_plan uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare v_role text;
begin
  perform trip_plan_private.assert_enabled();
  v_role := trip_plan_private.role_of(p_plan, auth.uid());
  if v_role is null then
    raise exception 'trip_plan_not_found' using errcode = 'P0002';
  end if;
  if v_role = 'owner' then
    perform trip_plan_private.pass_on(p_plan, auth.uid());
  else
    delete from public.trip_plan_members where plan_id = p_plan and user_id = auth.uid();
  end if;
end $$;

-- The owner hands the plan to someone on it; they become the owner and the
-- old owner an editor. A plan that counts toward the new owner's limit is
-- refused if they are full.
create function public.hand_over_trip_plan(p_plan uuid, p_user uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare v_max integer;
begin
  perform trip_plan_private.assert_invites_enabled();
  perform trip_plan_private.assert_owner(p_plan);
  if p_user = auth.uid() or not exists (select 1 from public.trip_plan_members
      where plan_id = p_plan and user_id = p_user and status = 'joined') then
    raise exception 'trip_plan_not_found' using errcode = 'P0002';
  end if;
  v_max := (trip_plan_private.limits(p_user) ->> 'max_upcoming_plans')::integer;
  if v_max is not null
     and exists (select 1 from public.trip_plans p where p.id = p_plan
       and p.archived_at is null and p.converted_from_saved_trip is null
       and not coalesce(trip_plan_private.is_past(p.id), false))
     and trip_plan_private.upcoming_count(p_user) >= v_max then
    raise exception 'trip_plan_limit_plans' using errcode = '54000';
  end if;
  update public.trip_plan_members set role = 'editor'
  where plan_id = p_plan and user_id = auth.uid();
  update public.trip_plan_members set role = 'owner'
  where plan_id = p_plan and user_id = p_user;
  update public.trip_plans set owner_id = p_user where id = p_plan;
  perform trip_plan_private.touch(p_plan);
end $$;

-- D9: mute a plan's change notifications.
create function public.set_trip_plan_muted(p_plan uuid, p_muted boolean)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform trip_plan_private.assert_enabled();
  update public.trip_plan_members set muted = coalesce(p_muted, false)
  where plan_id = p_plan and user_id = auth.uid() and status = 'joined';
  if not found then
    raise exception 'trip_plan_not_found' using errcode = 'P0002';
  end if;
end $$;

do $$
declare f text;
begin
  foreach f in array array[
    'create_trip_plan_invite(uuid, text)',
    'revoke_trip_plan_invite(uuid)',
    'list_trip_plan_invites(uuid)',
    'preview_trip_plan_invite(text)',
    'join_trip_plan(text)',
    'search_usernames(text)',
    'invite_trip_plan_user(uuid, text, text)',
    'my_trip_plan_invitations()',
    'respond_trip_plan_invitation(uuid, boolean)',
    'set_trip_plan_member_role(uuid, uuid, text)',
    'remove_trip_plan_member(uuid, uuid)',
    'leave_trip_plan(uuid)',
    'hand_over_trip_plan(uuid, uuid)',
    'set_trip_plan_muted(uuid, boolean)'
  ] loop
    execute format('revoke execute on function public.%s from public', f);
    execute format('grant execute on function public.%s to authenticated', f);
  end loop;
end $$;
