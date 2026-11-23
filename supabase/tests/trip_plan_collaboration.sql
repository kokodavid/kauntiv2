-- Trip plans with other people (migration 20261101105000).
-- Run against a local database after all migrations. Seeds its own users,
-- and rolls back all data.
begin;

insert into auth.users (id, email) values
  ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'collab-a@example.invalid'),
  ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', 'collab-b@example.invalid'),
  ('cccccccc-cccc-4ccc-8ccc-cccccccccccc', 'collab-c@example.invalid'),
  ('dddddddd-dddd-4ddd-8ddd-dddddddddddd', 'collab-d@example.invalid');
insert into public.quest_public_profiles (user_id, handle) values
  ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'amina7'),
  ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', 'mwangi_j'),
  ('cccccccc-cccc-4ccc-8ccc-cccccccccccc', 'mwangi_k'),
  ('dddddddd-dddd-4ddd-8ddd-dddddddddddd', 'zuri9')
on conflict (user_id) do update set handle = excluded.handle;

-- Test-only readers (rolled back): invites and members are not readable by
-- the signed-in role directly.
create function public.tc_role(p uuid, u uuid) returns text
language sql security definer set search_path = '' as $$
  select role from public.trip_plan_members
  where plan_id = p and user_id = u and status = 'joined' $$;
create function public.tc_count(p uuid) returns integer
language sql security definer set search_path = '' as $$
  select count(*)::integer from public.trip_plan_members where plan_id = p $$;
create function public.tc_invite_uses() returns integer
language sql security definer set search_path = '' as $$
  select max(uses) from public.trip_plan_invites $$;
create function public.tc_token_stored(t text) returns boolean
language sql security definer set search_path = '' as $$
  select exists (select 1 from public.trip_plan_invites where token_hash = t) $$;
grant execute on function public.tc_role(uuid, uuid), public.tc_count(uuid),
  public.tc_invite_uses(), public.tc_token_stored(text) to authenticated;

create temporary table tc_state (k text primary key, v text) on commit drop;
grant all on tc_state to authenticated;

-- 1. The invites switch is off by default.
update public.app_feature_flags set enabled = true where feature_key = 'trip_plans';
select set_config('request.jwt.claim.sub', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', true);
set local role authenticated;
do $$
declare v_plan uuid;
begin
  v_plan := public.create_trip_plan('Group trip', 2);
  insert into tc_state values ('plan', v_plan::text);
  begin
    perform public.create_trip_plan_invite(v_plan);
    raise exception 'An invite was made with the switch off';
  exception when insufficient_privilege then
    if sqlerrm <> 'trip_plans_unavailable' then raise; end if;
  end;
end $$;
reset role;
update public.app_feature_flags set enabled = true where feature_key = 'trip_plan_invites';

-- 2. Free: owner invites one buddy, as an editor.
select set_config('request.jwt.claim.sub', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', true);
set local role authenticated;
do $$
declare v_plan uuid; v_invite jsonb;
begin
  v_plan := (select v::uuid from tc_state where k = 'plan');
  begin
    perform public.create_trip_plan_invite(v_plan, 'viewer');
    raise exception 'A Free plan made a view-only invite';
  exception when program_limit_exceeded then
    if sqlerrm <> 'trip_plan_limit_roles' then raise; end if;
  end;
  v_invite := public.create_trip_plan_invite(v_plan);
  insert into tc_state values ('token1', v_invite ->> 'token');
  if length(v_invite ->> 'token') < 30 then raise exception 'Token too short'; end if;
  if public.tc_token_stored(v_invite ->> 'token') then
    raise exception 'The token itself was stored';
  end if;
end $$;

select set_config('request.jwt.claim.sub', 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', true);
do $$
declare v_token text; v_plan uuid; v_pre jsonb;
begin
  v_token := (select v from tc_state where k = 'token1');
  v_plan := (select v::uuid from tc_state where k = 'plan');
  v_pre := public.preview_trip_plan_invite(v_token);
  if v_pre ->> 'state' <> 'ok' or v_pre ->> 'title' <> 'Group trip' then
    raise exception 'Preview wrong: %', v_pre;
  end if;
  if public.join_trip_plan(v_token) <> v_plan then raise exception 'Joined the wrong plan'; end if;
  if public.tc_role(v_plan, auth.uid()) <> 'editor' then
    raise exception 'The buddy is not an editor';
  end if;
  -- Joining again changes nothing.
  perform public.join_trip_plan(v_token);
  if public.tc_invite_uses() <> 1 then
    raise exception 'A second join used the link again';
  end if;
  if public.preview_trip_plan_invite(v_token) ->> 'state' <> 'already_member' then
    raise exception 'Expected already_member';
  end if;
  -- A Free editor cannot invite.
  begin
    perform public.create_trip_plan_invite(v_plan);
    raise exception 'A Free editor made an invite';
  exception when insufficient_privilege then
    if sqlerrm <> 'trip_plan_owner_only' then raise; end if;
  end;
end $$;

-- The slot is taken: the same link is full for anyone else, and no more
-- links can be made.
select set_config('request.jwt.claim.sub', 'cccccccc-cccc-4ccc-8ccc-cccccccccccc', true);
do $$
declare v_token text;
begin
  v_token := (select v from tc_state where k = 'token1');
  if public.preview_trip_plan_invite(v_token) ->> 'state' <> 'full' then
    raise exception 'Expected a full link';
  end if;
  begin
    perform public.join_trip_plan(v_token);
    raise exception 'A third person joined a Free plan';
  exception when program_limit_exceeded then
    if sqlerrm <> 'trip_plan_invite_full' then raise; end if;
  end;
  if public.preview_trip_plan_invite('nonsense') ->> 'state' <> 'invalid' then
    raise exception 'Expected invalid';
  end if;
end $$;

select set_config('request.jwt.claim.sub', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', true);
do $$
declare v_plan uuid;
begin
  v_plan := (select v::uuid from tc_state where k = 'plan');
  begin
    perform public.create_trip_plan_invite(v_plan);
    raise exception 'An invite was made for a full plan';
  exception when program_limit_exceeded then
    if sqlerrm <> 'trip_plan_limit_members' then raise; end if;
  end;
  -- Only the owner removes people.
  perform public.remove_trip_plan_member(v_plan, 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb');
  if public.tc_count(v_plan) <> 1 then raise exception 'B was not removed'; end if;
end $$;

-- 3. A new link ends the old one; expiry.
do $$
declare v_plan uuid; v_new jsonb;
begin
  v_plan := (select v::uuid from tc_state where k = 'plan');
  v_new := public.create_trip_plan_invite(v_plan);
  insert into tc_state values ('token2', v_new ->> 'token');
end $$;
select set_config('request.jwt.claim.sub', 'cccccccc-cccc-4ccc-8ccc-cccccccccccc', true);
do $$
begin
  if public.preview_trip_plan_invite((select v from tc_state where k = 'token1')) ->> 'state' <> 'revoked' then
    raise exception 'The old link was not ended';
  end if;
  begin
    perform public.join_trip_plan((select v from tc_state where k = 'token1'));
    raise exception 'Joined with an ended link';
  exception when no_data_found then null;
  end;
end $$;
reset role;
update public.trip_plan_invites set expires_at = now() - interval '1 minute'
where revoked_at is null;
select set_config('request.jwt.claim.sub', 'cccccccc-cccc-4ccc-8ccc-cccccccccccc', true);
set local role authenticated;
do $$
begin
  if public.preview_trip_plan_invite((select v from tc_state where k = 'token2')) ->> 'state' <> 'expired' then
    raise exception 'Expected an expired link';
  end if;
  begin
    perform public.join_trip_plan((select v from tc_state where k = 'token2'));
    raise exception 'Joined with an expired link';
  exception when insufficient_privilege then
    if sqlerrm <> 'trip_plan_invite_expired' then raise; end if;
  end;
end $$;

-- 4. Pro: roles, groups, editors invite, username search and invites.
reset role;
insert into public.pro_entitlement_periods (user_id, starts_at, ends_at)
values ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', now() - interval '1 day', null);
select set_config('request.jwt.claim.sub', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', true);
set local role authenticated;
do $$
declare v_plan uuid; v_view jsonb; v_edit jsonb;
begin
  v_plan := (select v::uuid from tc_state where k = 'plan');
  v_view := public.create_trip_plan_invite(v_plan, 'viewer');
  v_edit := public.create_trip_plan_invite(v_plan, 'editor');
  insert into tc_state values ('view', v_view ->> 'token'), ('edit', v_edit ->> 'token');
end $$;
select set_config('request.jwt.claim.sub', 'cccccccc-cccc-4ccc-8ccc-cccccccccccc', true);
do $$
declare v_plan uuid;
begin
  v_plan := (select v::uuid from tc_state where k = 'plan');
  perform public.join_trip_plan((select v from tc_state where k = 'view'));
  if public.tc_role(v_plan, auth.uid()) <> 'viewer' then
    raise exception 'Expected a viewer';
  end if;
  begin
    perform public.create_trip_plan_invite(v_plan);
    raise exception 'A viewer made an invite';
  exception when insufficient_privilege then
    if sqlerrm <> 'trip_plan_view_only' then raise; end if;
  end;
end $$;
select set_config('request.jwt.claim.sub', 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', true);
do $$
declare v_plan uuid; v_invite jsonb;
begin
  v_plan := (select v::uuid from tc_state where k = 'plan');
  perform public.join_trip_plan((select v from tc_state where k = 'edit'));
  -- On Pro an editor may invite.
  v_invite := public.create_trip_plan_invite(v_plan);
  if v_invite ->> 'token' is null then raise exception 'No invite from a Pro editor'; end if;
end $$;

-- Search: 3 letters, never yourself, never suspended accounts, rate limited.
select set_config('request.jwt.claim.sub', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', true);
do $$
declare i integer; v_found boolean := false;
begin
  if jsonb_array_length(public.search_usernames('mw')) <> 0 then
    raise exception 'A 2 letter search returned people';
  end if;
  if jsonb_array_length(public.search_usernames('mwa')) <> 2 then
    raise exception 'Expected both mwangi handles';
  end if;
  if jsonb_array_length(public.search_usernames('ami')) <> 0 then
    raise exception 'Found myself';
  end if;
  begin
    for i in 1..40 loop
      perform public.search_usernames('mwa');
    end loop;
  exception when program_limit_exceeded then
    if sqlerrm <> 'trip_plan_rate_limited' then raise; end if;
    v_found := true;
  end;
  if not v_found then raise exception 'Searches were not limited'; end if;
end $$;
reset role;
insert into public.user_moderation_status (user_id, status)
values ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', 'suspended');
delete from public.trip_plan_search_log;
select set_config('request.jwt.claim.sub', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', true);
set local role authenticated;
do $$
declare v_plan uuid;
begin
  v_plan := (select v::uuid from tc_state where k = 'plan');
  if jsonb_array_length(public.search_usernames('mwa')) <> 1 then
    raise exception 'A suspended account was found';
  end if;
  -- Invite by name: holds a seat until accepted.
  perform public.invite_trip_plan_user(v_plan, 'Zuri9');
  begin
    perform public.invite_trip_plan_user(v_plan, 'zuri9');
    raise exception 'Invited twice';
  exception when unique_violation then null;
  end;
  begin
    perform public.invite_trip_plan_user(v_plan, 'nobody_here');
    raise exception 'Invited someone who does not exist';
  exception when no_data_found then null;
  end;
  perform public.set_trip_plan_member_role(v_plan, 'cccccccc-cccc-4ccc-8ccc-cccccccccccc', 'editor');
  if public.tc_role(v_plan, 'cccccccc-cccc-4ccc-8ccc-cccccccccccc') <> 'editor' then
    raise exception 'Role not changed';
  end if;
end $$;
select set_config('request.jwt.claim.sub', 'dddddddd-dddd-4ddd-8ddd-dddddddddddd', true);
do $$
declare v_plan uuid;
begin
  v_plan := (select v::uuid from tc_state where k = 'plan');
  if jsonb_array_length(public.my_trip_plan_invitations()) <> 1 then
    raise exception 'The invitation is missing';
  end if;
  if public.tc_role(v_plan, auth.uid()) is not null then
    raise exception 'Invited people can read the plan';
  end if;
  perform public.respond_trip_plan_invitation(v_plan, true);
  if public.tc_role(v_plan, auth.uid()) <> 'editor' then
    raise exception 'Accepting did not join';
  end if;
end $$;

-- 5. Leaving and handing over (D8).
select set_config('request.jwt.claim.sub', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', true);
do $$
declare v_plan uuid;
begin
  v_plan := (select v::uuid from tc_state where k = 'plan');
  -- Hand over to the buddy D; A becomes an editor.
  perform public.hand_over_trip_plan(v_plan, 'dddddddd-dddd-4ddd-8ddd-dddddddddddd');
  if public.tc_role(v_plan, 'dddddddd-dddd-4ddd-8ddd-dddddddddddd') <> 'owner' then
    raise exception 'Owner not changed';
  end if;
  if public.tc_role(v_plan, auth.uid()) <> 'editor' then
    raise exception 'The old owner is not an editor';
  end if;
  begin
    perform public.remove_trip_plan_member(v_plan, 'cccccccc-cccc-4ccc-8ccc-cccccccccccc');
    raise exception 'A former owner removed someone';
  exception when insufficient_privilege then null;
  end;
end $$;
-- One transaction means one clock: set who has been on the plan longest.
reset role;
update public.trip_plan_members set joined_at = now() - interval '3 days'
where user_id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
update public.trip_plan_members set joined_at = now() - interval '2 days'
where user_id = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';
select set_config('request.jwt.claim.sub', 'dddddddd-dddd-4ddd-8ddd-dddddddddddd', true);
set local role authenticated;
do $$
declare v_plan uuid;
begin
  v_plan := (select v::uuid from tc_state where k = 'plan');
  -- The owner leaves: the plan goes to the longest-standing editor.
  perform public.leave_trip_plan(v_plan);
  if public.tc_role(v_plan, 'dddddddd-dddd-4ddd-8ddd-dddddddddddd') is not null then
    raise exception 'The owner did not leave';
  end if;
  if public.tc_role(v_plan, 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa') <> 'owner' then
    raise exception 'The longest-standing editor did not get the plan';
  end if;
end $$;

-- Deleting an account hands its plans on; a plan with nobody else goes.
reset role;
do $$
declare v_plan uuid; v_owner uuid; v_solo uuid;
begin
  v_plan := (select v::uuid from tc_state where k = 'plan');
  v_owner := (select owner_id from public.trip_plans where id = v_plan);
  insert into public.trip_plans (owner_id, title) values (v_owner, 'Solo') returning id into v_solo;
  insert into public.trip_plan_members (plan_id, user_id, role, joined_at)
  values (v_solo, v_owner, 'owner', now());
  delete from auth.users where id = v_owner;
  if not exists (select 1 from public.trip_plans where id = v_plan) then
    raise exception 'A shared plan was deleted with its owner';
  end if;
  if (select owner_id from public.trip_plans where id = v_plan) = v_owner then
    raise exception 'The plan still belongs to the deleted account';
  end if;
  if exists (select 1 from public.trip_plans where id = v_solo) then
    raise exception 'A plan with nobody else stayed behind';
  end if;
end $$;

rollback;
