-- Best order (migration 20261101106000). Run after all migrations; seeds
-- its own data and rolls back.
begin;

insert into auth.users (id, email) values
  ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'order-a@example.invalid'),
  ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', 'order-b@example.invalid');
insert into public.quest_public_profiles (user_id, handle) values
  ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'amina7'),
  ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', 'mwangi_j')
on conflict (user_id) do update set handle = excluded.handle;

create temporary table to_places on commit drop as
select gen_random_uuid() as id, n from generate_series(1, 4) n;
insert into public.places (id, county_id, name, type, status, archived_at, location, source)
select id, 32, 'Order test place ' || n, 'waterfall', 'reviewed', null,
  ('SRID=4326;POINT(36.1 -0.' || n || ')')::geometry, 'test'
from to_places;
grant select on to_places to authenticated;
create temporary table to_state (k text primary key, v text) on commit drop;
grant all on to_state to authenticated;

update public.app_feature_flags set enabled = true where feature_key = 'trip_plans';

-- 1. Free: refused, and nothing changes.
select set_config('request.jwt.claim.sub', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', true);
set local role authenticated;
do $$
declare v_plan uuid; v_day uuid; v_place uuid;
begin
  v_plan := public.create_trip_plan('Order trip', 1);
  v_day := (public.get_trip_plan(v_plan) -> 'days' -> 0 ->> 'id')::uuid;
  insert into to_state values ('plan', v_plan::text), ('day', v_day::text);
  for v_place in select id from to_places order by n loop
    perform public.add_trip_plan_stop(v_day, v_place);
  end loop;
  begin
    perform public.trip_plan_day_order_input(v_day);
    raise exception 'Free got Best order';
  exception when program_limit_exceeded then
    if sqlerrm <> 'trip_plan_limit_best_order' then raise; end if;
  end;
end $$;

-- 2. Pro: gets the stops, then applies a new order.
reset role;
insert into public.pro_entitlement_periods (user_id, starts_at, ends_at)
values ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', now() - interval '1 day', null);
select set_config('request.jwt.claim.sub', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', true);
set local role authenticated;
do $$
declare v_day uuid; v_in jsonb; v_ids uuid[]; v_after jsonb;
begin
  v_day := (select v::uuid from to_state where k = 'day');
  v_in := public.trip_plan_day_order_input(v_day);
  if jsonb_array_length(v_in -> 'stops') <> 4 then raise exception 'Wrong stops: %', v_in; end if;
  if (v_in -> 'stops' -> 0 ->> 'lat') is null then raise exception 'No coordinates'; end if;
  select array_agg((e ->> 'id')::uuid order by ord desc) into v_ids
  from jsonb_array_elements(v_in -> 'stops') with ordinality as t(e, ord);
  perform public.set_trip_plan_day_order(v_day, v_ids);
  v_after := public.trip_plan_day_order_input(v_day);
  if (v_after -> 'stops' -> 0 ->> 'id')::uuid <> v_ids[1] then
    raise exception 'Order not applied';
  end if;
  -- A list missing a stop, or repeating one, is stale.
  begin
    perform public.set_trip_plan_day_order(v_day, v_ids[1:3]);
    raise exception 'A short list was accepted';
  exception when serialization_failure then
    if sqlerrm <> 'trip_plan_order_stale' then raise; end if;
  end;
  begin
    perform public.set_trip_plan_day_order(v_day, array[v_ids[1], v_ids[1], v_ids[2], v_ids[3]]);
    raise exception 'A repeated stop was accepted';
  exception when serialization_failure then
    if sqlerrm <> 'trip_plan_order_stale' then raise; end if;
  end;
end $$;

-- 3. Someone outside the plan sees nothing.
select set_config('request.jwt.claim.sub', 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', true);
do $$
declare v_day uuid;
begin
  v_day := (select v::uuid from to_state where k = 'day');
  begin
    perform public.trip_plan_day_order_input(v_day);
    raise exception 'A non-member read the day';
  exception when no_data_found then
    if sqlerrm <> 'trip_plan_not_found' then raise; end if;
  end;
end $$;

-- 4. The hourly limit: 20 calls, then refused.
select set_config('request.jwt.claim.sub', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', true);
do $$
declare v_day uuid; i integer;
begin
  v_day := (select v::uuid from to_state where k = 'day');
  for i in 1..20 loop
    begin
      perform public.trip_plan_day_order_input(v_day);
    exception when program_limit_exceeded then
      if sqlerrm = 'trip_plan_rate_limited' then return; end if;
      raise;
    end;
  end loop;
  raise exception 'No rate limit after 20 calls';
end $$;

rollback;
