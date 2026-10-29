-- Trip planner v2 (migrations 20261101100000 to 20261101102000).
-- Run against a local database after all migrations. Seeds its own users
-- and places, and rolls back all data.
begin;

insert into auth.users (id, email) values
  ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'trip-plans-a@example.invalid'),
  ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', 'trip-plans-b@example.invalid'),
  ('cccccccc-cccc-4ccc-8ccc-cccccccccccc', 'trip-plans-c@example.invalid');
insert into public.quest_public_profiles (user_id, handle) values
  ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'amina7')
on conflict (user_id) do update set handle = excluded.handle;

-- 40 reviewed places, one draft and one archived.
create temporary table tp_places on commit drop as
select gen_random_uuid() as id, n from generate_series(1, 40) n;
insert into public.places (id, county_id, name, type, status, archived_at, location, source)
select id, 32, 'Trip plan test place ' || n, 'waterfall', 'reviewed', null,
  'SRID=4326;POINT(36.1 -0.7)', 'test'
from tp_places;
insert into public.places (id, county_id, name, type, status, location, source) values
  ('dddddddd-0000-4000-8000-000000000001', 32, 'Draft place', 'waterfall', 'draft',
   'SRID=4326;POINT(36.1 -0.7)', 'test');
insert into public.places (id, county_id, name, type, status, archived_at, location, source) values
  ('dddddddd-0000-4000-8000-000000000002', 32, 'Archived place', 'waterfall', 'reviewed', now(),
   'SRID=4326;POINT(36.1 -0.7)', 'test');
grant select on tp_places to authenticated;

-- 1. The switch is off by default: nothing can be created.
select set_config('request.jwt.claim.sub', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', true);
set local role authenticated;
do $$
begin
  begin
    perform public.create_trip_plan('Weekend trip');
    raise exception 'A plan was created with the switch off';
  exception when insufficient_privilege then
    if sqlerrm <> 'trip_plans_unavailable' then raise; end if;
  end;
end $$;
reset role;
update public.app_feature_flags set enabled = true where feature_key = 'trip_plans';

-- 2. Free limits for user A.
set local role authenticated;
do $$
declare v_plan uuid; v_day uuid; v_days uuid[]; v_place uuid; i integer;
begin
  -- Days: at most 3 on Free.
  begin
    perform public.create_trip_plan('Too long', 4);
    raise exception 'A 4-day Free plan was created';
  exception when program_limit_exceeded then
    if sqlerrm <> 'trip_plan_limit_days' then raise; end if;
  end;

  v_plan := public.create_trip_plan('Naivasha weekend', 3, 'point', null,
    'Westlands, Nairobi', -1.26, 36.80, current_date + 7);
  if (public.get_trip_plan(v_plan)->'limits'->>'max_days')::int <> 3 then
    raise exception 'Free limits not returned';
  end if;
  if (select count(*) from public.trip_plan_days where plan_id = v_plan) <> 3 then
    raise exception 'Expected 3 days';
  end if;
  begin
    perform public.add_trip_plan_day(v_plan);
    raise exception 'A 4th day was added on Free';
  exception when program_limit_exceeded then null;
  end;

  -- Stops: at most 8 a day on Free.
  select id into v_day from public.trip_plan_days where plan_id = v_plan and position = 1;
  for i in 1..8 loop
    select id into v_place from tp_places where n = i;
    perform public.add_trip_plan_stop(v_day, v_place);
  end loop;
  begin
    perform public.add_trip_plan_stop(v_day, (select id from tp_places where n = 9));
    raise exception 'A 9th stop was added on Free';
  exception when program_limit_exceeded then
    if sqlerrm <> 'trip_plan_limit_stops' then raise; end if;
  end;

  -- Places to visit: at most 30 on Free; adding one twice is a no-op.
  for i in 10..39 loop
    perform public.add_trip_plan_place(v_plan, (select id from tp_places where n = i));
  end loop;
  perform public.add_trip_plan_place(v_plan, (select id from tp_places where n = 10));
  begin
    perform public.add_trip_plan_place(v_plan, (select id from tp_places where n = 40));
    raise exception 'A 31st place was added on Free';
  exception when program_limit_exceeded then null;
  end;

  -- Places users can't see can't be planned.
  begin
    perform public.add_trip_plan_place(v_plan, 'dddddddd-0000-4000-8000-000000000001');
    raise exception 'A draft place was planned';
  exception when invalid_parameter_value then null;
  end;
  begin
    perform public.add_trip_plan_stop(v_day, 'dddddddd-0000-4000-8000-000000000002');
    raise exception 'An archived place was planned';
  exception when invalid_parameter_value then null;
  end;

  -- Upcoming plans: at most 3 on Free, undated ones count too.
  perform public.create_trip_plan('Second');
  perform public.create_trip_plan('Third');
  begin
    perform public.create_trip_plan('Fourth');
    raise exception 'A 4th upcoming plan was created on Free';
  exception when program_limit_exceeded then
    if sqlerrm <> 'trip_plan_limit_plans' then raise; end if;
  end;
  if (public.my_trip_plan_limits()->>'upcoming_plans')::int <> 3 then
    raise exception 'Upcoming count should be 3';
  end if;

  -- Archiving frees a slot; unarchiving at the limit is refused.
  perform public.archive_trip_plan(
    (select id from public.trip_plans where title = 'Third'), true);
  perform public.create_trip_plan('Fourth');
  begin
    perform public.archive_trip_plan(
      (select id from public.trip_plans where title = 'Third'), false);
    raise exception 'Unarchiving past the limit was allowed';
  exception when program_limit_exceeded then null;
  end;

  -- Nobody writes the tables directly.
  begin
    insert into public.trip_plans (owner_id, title)
    values ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'Sneaky');
    raise exception 'A direct insert was allowed';
  exception when insufficient_privilege then null;
  end;
  begin
    update public.trip_plan_stops set note = 'sneaky' where plan_id = v_plan;
    raise exception 'A direct update was allowed';
  exception when insufficient_privilege then null;
  end;
end $$;

-- 3. Ordering: inserts before, moves across days, many moves in one gap.
do $$
declare v_plan uuid; v_d1 uuid; v_d2 uuid; v_a uuid; v_b uuid; v_c uuid;
  v_order text; i integer;
begin
  select id into v_plan from public.trip_plans where title = 'Naivasha weekend';
  select id into v_d1 from public.trip_plan_days where plan_id = v_plan and position = 1;
  select id into v_d2 from public.trip_plan_days where plan_id = v_plan and position = 2;
  v_a := public.add_trip_plan_stop(v_d2, (select id from tp_places where n = 9), null, 'Lunch');
  v_c := public.add_trip_plan_stop(v_d2, (select id from tp_places where n = 40));
  v_b := public.add_trip_plan_stop(v_d2, (select id from tp_places where n = 10), v_c);
  -- Scheduling a place takes it off Places to visit.
  if exists (select 1 from public.trip_plan_places tp join tp_places t on t.id = tp.place_id
      where tp.plan_id = v_plan and t.n = 10) then
    raise exception 'A scheduled place stayed on Places to visit';
  end if;
  select string_agg(t.n::text, ',' order by s.position) into v_order
  from public.trip_plan_stops s join tp_places t on t.id = s.place_id where s.day_id = v_d2;
  if v_order <> '9,10,40' then raise exception 'Unexpected order %', v_order; end if;

  -- Squeeze many moves into one gap: positions rebalance, order stays right.
  for i in 1..30 loop
    perform public.move_trip_plan_stop(v_c, v_d2, v_b);
    perform public.move_trip_plan_stop(v_b, v_d2, v_c);
  end loop;
  select string_agg(t.n::text, ',' order by s.position) into v_order
  from public.trip_plan_stops s join tp_places t on t.id = s.place_id where s.day_id = v_d2;
  if v_order <> '9,10,40' then raise exception 'Order after moves %', v_order; end if;

  -- Moving into a full day is refused (Day 1 has 8 stops).
  begin
    perform public.move_trip_plan_stop(v_a, v_d1, null);
    raise exception 'A stop moved into a full day';
  exception when program_limit_exceeded then null;
  end;
  -- Moving within a full day is fine.
  perform public.move_trip_plan_stop(
    (select id from public.trip_plan_stops where day_id = v_d1 order by position desc limit 1),
    v_d1,
    (select id from public.trip_plan_stops where day_id = v_d1 order by position limit 1));

  -- Notes.
  perform public.set_trip_plan_stop_note(v_a, '  ');
  if (select note from public.trip_plan_stops where id = v_a) is not null then
    raise exception 'A blank note was kept';
  end if;
end $$;

-- 4. Removing a day: stops go back to the list, days renumber, one day stays.
do $$
declare v_plan uuid; v_d2 uuid; v_positions text; v_plan2 uuid;
begin
  select id into v_plan from public.trip_plans where title = 'Naivasha weekend';
  select id into v_d2 from public.trip_plan_days where plan_id = v_plan and position = 2;
  perform public.remove_trip_plan_place(v_plan,
    (select id from tp_places where n = 11));
  perform public.remove_trip_plan_day(v_d2);
  select string_agg(position::text, ',' order by position) into v_positions
  from public.trip_plan_days where plan_id = v_plan;
  if v_positions <> '1,2' then raise exception 'Days not renumbered: %', v_positions; end if;
  if not exists (select 1 from public.trip_plan_places tp join tp_places t on t.id = tp.place_id
      where tp.plan_id = v_plan and t.n = 9) then
    raise exception 'A removed day lost its stops';
  end if;
  -- Above 30 is allowed here: removing never loses a place.
  if (select count(*) from public.trip_plan_places where plan_id = v_plan) <> 31 then
    raise exception 'Expected 31 places after the day went back to the list';
  end if;

  v_plan2 := (select id from public.trip_plans where title = 'Second');
  begin
    perform public.remove_trip_plan_day(
      (select id from public.trip_plan_days where plan_id = v_plan2));
    raise exception 'The last day was removed';
  exception when invalid_parameter_value then
    if sqlerrm <> 'trip_plan_last_day' then raise; end if;
  end;

  -- Adding a day in the middle shifts the later ones.
  perform public.add_trip_plan_day(v_plan,
    (select id from public.trip_plan_days where plan_id = v_plan and position = 1));
  select string_agg(position::text, ',' order by position) into v_positions
  from public.trip_plan_days where plan_id = v_plan;
  if v_positions <> '1,2,3' then raise exception 'Day insert broke numbering: %', v_positions; end if;
end $$;

-- 5. Route cache: only a matching stops key is saved.
do $$
declare v_plan uuid; v_d1 uuid; v_key text;
begin
  select id into v_plan from public.trip_plans where title = 'Naivasha weekend';
  select id into v_d1 from public.trip_plan_days where plan_id = v_plan and position = 1;
  select string_agg(id::text, ',' order by position, created_at, id) into v_key
  from public.trip_plan_stops where day_id = v_d1;
  perform public.set_trip_plan_day_route(v_d1, v_key, 117000, 8700, '{47,22,32}');
  begin
    perform public.set_trip_plan_day_route(v_d1, 'stale', 1, 1, '{}');
    raise exception 'A stale route was saved';
  exception when serialization_failure then null;
  end;
  if (select route_distance_m from public.trip_plan_days where id = v_d1) <> 117000 then
    raise exception 'Route not saved';
  end if;
  -- A change clears the cached route.
  perform public.set_trip_plan_stop_note(
    (select id from public.trip_plan_stops where day_id = v_d1 limit 1), 'Gate opens 6am');
  perform public.remove_trip_plan_stop(
    (select id from public.trip_plan_stops where day_id = v_d1 order by position limit 1), true);
  if (select route_stops_key from public.trip_plan_days where id = v_d1) is not null then
    raise exception 'A changed day kept its old route';
  end if;
  if jsonb_array_length(public.list_trip_plans()) <> 4 then
    raise exception 'List should show 4 plans';
  end if;
end $$;

-- 6. Another user sees nothing and can change nothing.
select set_config('request.jwt.claim.sub', 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', true);
do $$
declare v_plan uuid;
begin
  if exists (select 1 from public.trip_plans) or exists (select 1 from public.trip_plan_stops) then
    raise exception 'A plan leaked to another user';
  end if;
  if jsonb_array_length(public.list_trip_plans()) <> 0 then
    raise exception 'list_trip_plans leaked';
  end if;
  reset role;
  select id into v_plan from public.trip_plans where title = 'Naivasha weekend';
  set local role authenticated;
  begin
    perform public.get_trip_plan(v_plan);
    raise exception 'get_trip_plan leaked';
  exception when no_data_found then null;
  end;
  begin
    perform public.add_trip_plan_day(v_plan);
    raise exception 'A non-member changed a plan';
  exception when no_data_found then null;
  end;
end $$;

-- 7. A viewer can read but not change; an editor can change.
reset role;
insert into public.trip_plan_members (plan_id, user_id, role, status, joined_at)
select id, 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', 'viewer', 'joined', now()
from public.trip_plans where title = 'Naivasha weekend';
insert into public.trip_plan_members (plan_id, user_id, role, status, joined_at)
select id, 'cccccccc-cccc-4ccc-8ccc-cccccccccccc', 'editor', 'joined', now()
from public.trip_plans where title = 'Naivasha weekend';
set local role authenticated;
do $$
declare v_plan uuid;
begin
  select id into v_plan from public.trip_plans where title = 'Naivasha weekend';
  if v_plan is null then raise exception 'The viewer cannot read the plan'; end if;
  if public.get_trip_plan(v_plan)->>'role' <> 'viewer' then
    raise exception 'Wrong role returned';
  end if;
  begin
    perform public.update_trip_plan(v_plan, 'Renamed by viewer');
    raise exception 'A viewer renamed the plan';
  exception when insufficient_privilege then
    if sqlerrm <> 'trip_plan_view_only' then raise; end if;
  end;
  -- Joined plans never count toward your own limit (D6).
  if (public.my_trip_plan_limits()->>'upcoming_plans')::int <> 0 then
    raise exception 'A joined plan counted toward the viewer''s limit';
  end if;
end $$;
select set_config('request.jwt.claim.sub', 'cccccccc-cccc-4ccc-8ccc-cccccccccccc', true);
do $$
declare v_plan uuid;
begin
  select id into v_plan from public.trip_plans where title = 'Naivasha weekend';
  perform public.update_trip_plan(v_plan, 'Naivasha & Nakuru weekend');
  if public.get_trip_plan(v_plan)->>'updated_by' <> 'cccccccc-cccc-4ccc-8ccc-cccccccccccc' then
    raise exception 'updated_by not set';
  end if;
  -- Only the owner archives or deletes.
  begin
    perform public.delete_trip_plan(v_plan);
    raise exception 'An editor deleted the plan';
  exception when insufficient_privilege then null;
  end;
  -- The editor's limits are the owner's (Free): no 4th day.
  begin
    perform public.add_trip_plan_day(v_plan);
    raise exception 'An editor went past the owner''s day limit';
  exception when program_limit_exceeded then null;
  end;
end $$;

-- 8. Pro owner: higher limits; a downgrade keeps everything.
reset role;
insert into public.pro_entitlement_periods (user_id, starts_at, ends_at)
values ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', now() - interval '1 day', null);
select set_config('request.jwt.claim.sub', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', true);
set local role authenticated;
do $$
declare v_plan uuid;
begin
  v_plan := public.create_trip_plan('Northern circuit', 14);
  perform public.create_trip_plan('Sixth');
  if (public.my_trip_plan_limits()->>'pro')::boolean is not true then
    raise exception 'Pro limits not applied';
  end if;
  begin
    perform public.add_trip_plan_day(v_plan);
    raise exception 'A 15th day was added';
  exception when program_limit_exceeded then null;
  end;
end $$;
reset role;
update public.pro_entitlement_periods set ends_at = now() - interval '1 second'
where user_id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
set local role authenticated;
do $$
declare v_plan uuid;
begin
  select id into v_plan from public.trip_plans where title = 'Northern circuit';
  if (select count(*) from public.trip_plan_days where plan_id = v_plan) <> 14 then
    raise exception 'A downgrade removed days';
  end if;
  if (public.get_trip_plan(v_plan)->'limits'->>'max_days')::int <> 3 then
    raise exception 'Limits did not follow the downgrade';
  end if;
  -- Removing a locked day still works.
  perform public.remove_trip_plan_day(
    (select id from public.trip_plan_days where plan_id = v_plan and position = 14));
end $$;

-- 9. Past plans don't count; converted saved trips don't count and convert once.
reset role;
update public.trip_plans set start_date = current_date - 10 where title = 'Sixth';
insert into public.saved_trips (user_id, name, destination_place_id, stop_place_ids)
select 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'Old plan', (select id from tp_places where n = 1),
  array[(select id from tp_places where n = 2), 'dddddddd-0000-4000-8000-000000000001'::uuid];
set local role authenticated;
do $$
declare v_before int; v_plan uuid; v_order text;
begin
  v_before := (public.my_trip_plan_limits()->>'upcoming_plans')::int;
  if public.convert_saved_trips() <> 1 then raise exception 'Expected one conversion'; end if;
  if public.convert_saved_trips() <> 0 then raise exception 'Converted twice'; end if;
  if (public.my_trip_plan_limits()->>'upcoming_plans')::int <> v_before then
    raise exception 'A converted plan counted toward the limit';
  end if;
  select id into v_plan from public.trip_plans where title = 'Old plan';
  -- The stop first, then the destination; the draft place is left out.
  select string_agg(t.n::text, ',' order by s.position) into v_order
  from public.trip_plan_stops s join tp_places t on t.id = s.place_id where s.plan_id = v_plan;
  if v_order <> '2,1' then raise exception 'Converted stops in wrong order: %', v_order; end if;
  if exists (select 1 from jsonb_array_elements(public.list_trip_plans()) p
      where p->>'title' = 'Sixth' and (p->>'is_past')::boolean is not true) then
    raise exception 'A past plan was not marked past';
  end if;
end $$;

rollback;
