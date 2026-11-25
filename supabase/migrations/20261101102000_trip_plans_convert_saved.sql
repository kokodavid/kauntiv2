-- Trip planner v2, part 3: moving the old planner's saved trips across.
--
-- Each saved_trips row becomes a one-day plan: its stops in order, then the
-- destination, starting from the phone's location as before. Converted plans
-- are marked (converted_from_saved_trip) so they never count toward the Free
-- limit (D5), and converting twice does nothing. Places users can no longer
-- see (archived or not reviewed) are left out. saved_trips itself is kept
-- until the new app has spread, then retired in a later migration.

create function public.convert_saved_trips()
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user uuid := auth.uid();
  v_trip record;
  v_plan uuid;
  v_day uuid;
  v_place uuid;
  v_pos integer;
  v_count integer := 0;
begin
  perform trip_plan_private.assert_enabled();
  if v_user is null then
    raise exception 'not_signed_in' using errcode = '42501';
  end if;
  for v_trip in
    select t.* from public.saved_trips t
    where t.user_id = v_user
      and not exists (select 1 from public.trip_plans p
        where p.converted_from_saved_trip = t.id)
    order by t.created_at
  loop
    insert into public.trip_plans (owner_id, title, converted_from_saved_trip,
      created_at, updated_at, updated_by)
    values (v_user, v_trip.name, v_trip.id, v_trip.created_at, now(), v_user)
    returning id into v_plan;
    insert into public.trip_plan_members (plan_id, user_id, role, status, joined_at)
    values (v_plan, v_user, 'owner', 'joined', now());
    insert into public.trip_plan_days (plan_id, position) values (v_plan, 1)
    returning id into v_day;
    v_pos := 0;
    foreach v_place in array (v_trip.stop_place_ids || v_trip.destination_place_id) loop
      if exists (select 1 from public.places pl where pl.id = v_place
          and pl.status = 'reviewed' and pl.archived_at is null) then
        v_pos := v_pos + 1024;
        insert into public.trip_plan_stops (plan_id, day_id, place_id, position, added_by)
        values (v_plan, v_day, v_place, v_pos, v_user);
      end if;
    end loop;
    v_count := v_count + 1;
  end loop;
  return v_count;
end $$;

revoke execute on function public.convert_saved_trips() from public;
grant execute on function public.convert_saved_trips() to authenticated;
