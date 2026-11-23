-- Trip plan notifications and Mute plan (migration 20261101107000).
-- Run after all migrations. Seeds its own users; rolls back.
begin;

insert into auth.users (id, email) values
  ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'push-a@example.invalid'),
  ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', 'push-b@example.invalid');
insert into public.quest_public_profiles (user_id, handle) values
  ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'amina7'),
  ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', 'mwangi_j')
on conflict (user_id) do update set handle = excluded.handle;

create temporary table tpn_state (k text primary key, v text) on commit drop;
grant all on tpn_state to authenticated;
create function public.tpn_events(u uuid, k text) returns integer
language sql security definer set search_path = '' as $$
  select count(*)::integer from public.push_events where user_id = u and kind = k $$;
grant execute on function public.tpn_events(uuid, text) to authenticated;

update public.app_feature_flags set enabled = true
where feature_key in ('trip_plans', 'trip_plan_invites');

-- 1. An invitation by username queues a push for the invited person.
select set_config('request.jwt.claim.sub', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', true);
set local role authenticated;
do $$
declare v_plan uuid;
begin
  v_plan := public.create_trip_plan('Push trip', 2);
  insert into tpn_state values ('plan', v_plan::text);
  perform public.invite_trip_plan_user(v_plan, 'mwangi_j');
  if public.tpn_events('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', 'plan_invite') <> 1 then
    raise exception 'No push for the invitation';
  end if;
  if public.tpn_events('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'plan_invite') <> 0 then
    raise exception 'The inviter was notified';
  end if;
end $$;

-- 2. Accepting tells the owner.
select set_config('request.jwt.claim.sub', 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', true);
do $$
declare v_plan uuid;
begin
  v_plan := (select v::uuid from tpn_state where k = 'plan');
  perform public.respond_trip_plan_invitation(v_plan, true);
  if public.tpn_events('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'plan_invite') <> 1 then
    raise exception 'The owner was not told about the join';
  end if;
  if public.my_trip_plan_muted(v_plan) then raise exception 'Muted by default'; end if;
end $$;

-- 3. Changes are batched: nothing while edits are fresh, then one push to
-- the other person, and none to whoever made the change.
do $$
declare v_plan uuid;
begin
  v_plan := (select v::uuid from tpn_state where k = 'plan');
  perform public.update_trip_plan(v_plan, 'Push trip renamed');
end $$;
reset role;
do $$
declare v_plan uuid; v_made integer;
begin
  v_plan := (select v::uuid from tpn_state where k = 'plan');
  if public.enqueue_plan_updates() <> 0 then raise exception 'Notified during the settle time'; end if;
  -- One transaction means one clock: move the plan's times into the past.
  update public.trip_plans
  set created_at = now() - interval '2 hours', updated_at = now() - interval '10 minutes'
  where id = v_plan;
  v_made := public.enqueue_plan_updates();
  if v_made <> 1 then raise exception 'Expected one update push, got %', v_made; end if;
  if public.tpn_events('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'plan_update') <> 1 then
    raise exception 'The owner was not told';
  end if;
  if public.tpn_events('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', 'plan_update') <> 0 then
    raise exception 'The editor was told about their own change';
  end if;
  if public.enqueue_plan_updates() <> 0 then raise exception 'Told twice about one change'; end if;
end $$;

-- 4. Muting stops them.
select set_config('request.jwt.claim.sub', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', true);
set local role authenticated;
do $$
declare v_plan uuid;
begin
  v_plan := (select v::uuid from tpn_state where k = 'plan');
  perform public.set_trip_plan_muted(v_plan, true);
  if not public.my_trip_plan_muted(v_plan) then raise exception 'Mute did not stick'; end if;
end $$;
select set_config('request.jwt.claim.sub', 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', true);
do $$
declare v_plan uuid;
begin
  v_plan := (select v::uuid from tpn_state where k = 'plan');
  perform public.update_trip_plan(v_plan, 'Push trip again');
end $$;
reset role;
do $$
declare v_plan uuid;
begin
  v_plan := (select v::uuid from tpn_state where k = 'plan');
  update public.trip_plan_push_state set notified_at = now() - interval '1 hour' where plan_id = v_plan;
  update public.trip_plans set updated_at = now() - interval '10 minutes' where id = v_plan;
  perform public.enqueue_plan_updates();
  if public.tpn_events('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'plan_update') <> 1 then
    raise exception 'A muted member was notified';
  end if;
end $$;

rollback;
