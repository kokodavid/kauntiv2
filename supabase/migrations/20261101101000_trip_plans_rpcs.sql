-- Trip planner v2, part 2: the functions the app calls.
--
-- Every change checks the planner switch, membership and role, and the
-- owner's limits (trip_plan_private.limits). Error messages are stable
-- codes the app maps to copy:
--   trip_plans_unavailable, not_signed_in, trip_plan_not_found,
--   trip_plan_view_only, trip_plan_owner_only, trip_plan_place_unavailable,
--   trip_plan_limit_plans, trip_plan_limit_days, trip_plan_limit_stops,
--   trip_plan_limit_places, trip_plan_last_day, trip_plan_bad_input,
--   trip_plan_route_stale.

-- Positions -----------------------------------------------------------------

-- Renumbers a day's stops to 1024, 2048... keeping their order.
create function trip_plan_private.rebalance_day(p_day uuid)
returns void
language sql
security definer
set search_path = ''
as $$
  update public.trip_plan_stops s set position = r.n * 1024
  from (
    select id, row_number() over (order by position, created_at, id) as n
    from public.trip_plan_stops where day_id = p_day
  ) r
  where s.id = r.id;
$$;

-- The position for a stop placed before p_before on p_day (or at the end
-- when p_before is null). Rebalances the day once if the gap has run out.
create function trip_plan_private.position_before(p_day uuid, p_before uuid, p_moving uuid)
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare v_next integer; v_prev integer; v_try integer := 0;
begin
  loop
    if p_before is null then
      select coalesce(max(position), 0) + 1024 into v_next
      from public.trip_plan_stops
      where day_id = p_day and id is distinct from p_moving;
      return v_next;
    end if;
    select position into v_next from public.trip_plan_stops
    where id = p_before and day_id = p_day;
    if v_next is null then
      raise exception 'trip_plan_bad_input' using errcode = '22023';
    end if;
    select coalesce(max(position), 0) into v_prev from public.trip_plan_stops
    where day_id = p_day and position < v_next and id is distinct from p_moving;
    if v_next - v_prev >= 2 then
      return v_prev + (v_next - v_prev) / 2;
    end if;
    if v_try > 0 then
      raise exception 'trip_plan_bad_input' using errcode = '22023';
    end if;
    perform trip_plan_private.rebalance_day(p_day);
    v_try := v_try + 1;
  end loop;
end $$;

-- Renumbers a plan's days 1, 2, 3... keeping their order.
create function trip_plan_private.renumber_days(p_plan uuid)
returns void
language sql
security definer
set search_path = ''
as $$
  update public.trip_plan_days d set position = r.n, updated_at = now()
  from (
    select id, row_number() over (order by position, created_at, id) as n
    from public.trip_plan_days where plan_id = p_plan
  ) r
  where d.id = r.id and d.position <> r.n;
$$;

create function trip_plan_private.assert_stop_room(p_owner uuid, p_day uuid, p_moving uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare v_max integer;
begin
  v_max := (trip_plan_private.limits(p_owner)->>'max_stops_per_day')::integer;
  if (select count(*) from public.trip_plan_stops
      where day_id = p_day and id is distinct from p_moving) >= v_max then
    raise exception 'trip_plan_limit_stops' using errcode = '54000';
  end if;
end $$;

-- A start or overnight point: a place, a picked point, or nothing.
create function trip_plan_private.check_point(
  p_place uuid, p_lat double precision, p_lng double precision
)
returns void
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if p_place is not null then
    perform trip_plan_private.assert_place(p_place);
  end if;
  if (p_lat is null) <> (p_lng is null)
    or (p_lat is not null and (p_lat not between -90 and 90 or p_lng not between -180 and 180)) then
    raise exception 'trip_plan_bad_input' using errcode = '22023';
  end if;
end $$;

-- Plans ---------------------------------------------------------------------

-- Creates a plan with p_days empty days. p_first_place puts a place on
-- Day 1 ("New plan with this place" from Place Detail).
create function public.create_trip_plan(
  p_title text,
  p_days integer default 1,
  p_start_kind text default 'current_location',
  p_start_place_id uuid default null,
  p_start_label text default null,
  p_start_lat double precision default null,
  p_start_lng double precision default null,
  p_start_date date default null,
  p_first_place_id uuid default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare v_user uuid := auth.uid(); v_limits jsonb; v_plan uuid; v_day uuid; i integer;
begin
  perform trip_plan_private.assert_enabled();
  if v_user is null then
    raise exception 'not_signed_in' using errcode = '42501';
  end if;
  if p_title is null or length(btrim(p_title)) not between 1 and 80
    or p_start_kind is null or p_start_kind not in ('current_location', 'place', 'point')
    or p_days is null or p_days < 1
    or (p_start_kind = 'place' and p_start_place_id is null and p_start_lat is null)
    or (p_start_kind = 'point' and p_start_lat is null) then
    raise exception 'trip_plan_bad_input' using errcode = '22023';
  end if;
  perform trip_plan_private.check_point(p_start_place_id, p_start_lat, p_start_lng);
  v_limits := trip_plan_private.limits(v_user);
  if p_days > (v_limits->>'max_days')::integer then
    raise exception 'trip_plan_limit_days' using errcode = '54000';
  end if;
  if v_limits->>'max_upcoming_plans' is not null
    and trip_plan_private.upcoming_count(v_user) >= (v_limits->>'max_upcoming_plans')::integer then
    raise exception 'trip_plan_limit_plans' using errcode = '54000';
  end if;

  insert into public.trip_plans (owner_id, title, start_kind, start_place_id,
    start_label, start_lat, start_lng, start_date, updated_by)
  values (v_user, btrim(p_title), p_start_kind,
    case when p_start_kind = 'place' then p_start_place_id end,
    case when p_start_kind = 'current_location' then null else nullif(btrim(p_start_label), '') end,
    case when p_start_kind = 'current_location' then null else p_start_lat end,
    case when p_start_kind = 'current_location' then null else p_start_lng end,
    p_start_date, v_user)
  returning id into v_plan;

  insert into public.trip_plan_members (plan_id, user_id, role, status, joined_at)
  values (v_plan, v_user, 'owner', 'joined', now());

  for i in 1..p_days loop
    insert into public.trip_plan_days (plan_id, position) values (v_plan, i)
    returning id into v_day;
    if i = 1 and p_first_place_id is not null then
      perform trip_plan_private.assert_place(p_first_place_id);
      insert into public.trip_plan_stops (plan_id, day_id, place_id, position, added_by)
      values (v_plan, v_day, p_first_place_id, 1024, v_user);
    end if;
  end loop;
  return v_plan;
end $$;

-- Renames a plan and/or changes its start date. p_clear_start_date removes
-- the date (a null p_start_date alone leaves it as it is).
create function public.update_trip_plan(
  p_plan uuid,
  p_title text default null,
  p_start_date date default null,
  p_clear_start_date boolean default false
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform trip_plan_private.assert_editor(p_plan);
  if p_title is not null and length(btrim(p_title)) not between 1 and 80 then
    raise exception 'trip_plan_bad_input' using errcode = '22023';
  end if;
  update public.trip_plans set
    title = coalesce(btrim(p_title), title),
    start_date = case when p_clear_start_date then null else coalesce(p_start_date, start_date) end
  where id = p_plan;
  perform trip_plan_private.touch(p_plan);
end $$;

create function public.set_trip_plan_start(
  p_plan uuid,
  p_start_kind text,
  p_start_place_id uuid default null,
  p_start_label text default null,
  p_start_lat double precision default null,
  p_start_lng double precision default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform trip_plan_private.assert_editor(p_plan);
  if p_start_kind is null or p_start_kind not in ('current_location', 'place', 'point')
    or (p_start_kind = 'place' and p_start_place_id is null and p_start_lat is null)
    or (p_start_kind = 'point' and p_start_lat is null) then
    raise exception 'trip_plan_bad_input' using errcode = '22023';
  end if;
  perform trip_plan_private.check_point(p_start_place_id, p_start_lat, p_start_lng);
  update public.trip_plans set
    start_kind = p_start_kind,
    start_place_id = case when p_start_kind = 'place' then p_start_place_id end,
    start_label = case when p_start_kind = 'current_location' then null else nullif(btrim(p_start_label), '') end,
    start_lat = case when p_start_kind = 'current_location' then null else p_start_lat end,
    start_lng = case when p_start_kind = 'current_location' then null else p_start_lng end
  where id = p_plan;
  update public.trip_plan_days set route_stops_key = null
  where plan_id = p_plan and position = 1;
  perform trip_plan_private.touch(p_plan);
end $$;

-- Archives or unarchives a plan (owner). Unarchiving counts toward the
-- Free limit like a new plan.
create function public.archive_trip_plan(p_plan uuid, p_archived boolean)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare v_limits jsonb;
begin
  perform trip_plan_private.assert_owner(p_plan);
  if p_archived is null then
    raise exception 'trip_plan_bad_input' using errcode = '22023';
  end if;
  if not p_archived and exists (select 1 from public.trip_plans
      where id = p_plan and archived_at is not null) then
    v_limits := trip_plan_private.limits(auth.uid());
    if v_limits->>'max_upcoming_plans' is not null
      and exists (select 1 from public.trip_plans where id = p_plan
        and converted_from_saved_trip is null)
      and not coalesce(trip_plan_private.is_past(p_plan), false)
      and trip_plan_private.upcoming_count(auth.uid()) >= (v_limits->>'max_upcoming_plans')::integer then
      raise exception 'trip_plan_limit_plans' using errcode = '54000';
    end if;
  end if;
  update public.trip_plans
  set archived_at = case when p_archived then coalesce(archived_at, now()) else null end
  where id = p_plan;
  perform trip_plan_private.touch(p_plan);
end $$;

create function public.delete_trip_plan(p_plan uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform trip_plan_private.assert_owner(p_plan);
  delete from public.trip_plans where id = p_plan;
end $$;

-- Days ----------------------------------------------------------------------

-- Adds a day after p_after_day (or at the end). Returns the new day's id.
create function public.add_trip_plan_day(p_plan uuid, p_after_day uuid default null)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare v_owner uuid; v_pos integer; v_day uuid;
begin
  v_owner := trip_plan_private.assert_editor(p_plan);
  if (select count(*) from public.trip_plan_days where plan_id = p_plan)
      >= (trip_plan_private.limits(v_owner)->>'max_days')::integer then
    raise exception 'trip_plan_limit_days' using errcode = '54000';
  end if;
  if p_after_day is null then
    select coalesce(max(position), 0) + 1 into v_pos
    from public.trip_plan_days where plan_id = p_plan;
  else
    select position + 1 into v_pos from public.trip_plan_days
    where id = p_after_day and plan_id = p_plan;
    if v_pos is null then
      raise exception 'trip_plan_bad_input' using errcode = '22023';
    end if;
    update public.trip_plan_days set position = position + 1, updated_at = now()
    where plan_id = p_plan and position >= v_pos;
  end if;
  insert into public.trip_plan_days (plan_id, position) values (p_plan, v_pos)
  returning id into v_day;
  -- The day after the new one now starts from a different place.
  update public.trip_plan_days set route_stops_key = null
  where plan_id = p_plan and position = v_pos + 1;
  perform trip_plan_private.touch(p_plan);
  return v_day;
end $$;

-- Removes a day. Its stops go back to Places to visit, so nothing is lost;
-- later days move up one. A plan always keeps at least one day.
create function public.remove_trip_plan_day(p_day uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare v_plan uuid; v_pos integer;
begin
  select plan_id, position into v_plan, v_pos from public.trip_plan_days where id = p_day;
  if v_plan is null then
    raise exception 'trip_plan_not_found' using errcode = 'P0002';
  end if;
  perform trip_plan_private.assert_editor(v_plan);
  if (select count(*) from public.trip_plan_days where plan_id = v_plan) <= 1 then
    raise exception 'trip_plan_last_day' using errcode = '22023';
  end if;
  -- Moved back even past the places limit: removing never loses a place.
  insert into public.trip_plan_places (plan_id, place_id, note, added_by)
  select v_plan, s.place_id, s.note, s.added_by from public.trip_plan_stops s
  where s.day_id = p_day
  order by s.position
  on conflict (plan_id, place_id) do nothing;
  delete from public.trip_plan_days where id = p_day;
  perform trip_plan_private.renumber_days(v_plan);
  update public.trip_plan_days set route_stops_key = null
  where plan_id = v_plan and position = v_pos;
  perform trip_plan_private.touch(v_plan);
end $$;

-- Renames a day and/or sets its overnight place or point.
create function public.update_trip_plan_day(
  p_day uuid,
  p_title text default null,
  p_clear_title boolean default false,
  p_overnight_place_id uuid default null,
  p_overnight_label text default null,
  p_overnight_lat double precision default null,
  p_overnight_lng double precision default null,
  p_set_overnight boolean default false
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare v_plan uuid; v_pos integer;
begin
  select plan_id, position into v_plan, v_pos from public.trip_plan_days where id = p_day;
  if v_plan is null then
    raise exception 'trip_plan_not_found' using errcode = 'P0002';
  end if;
  perform trip_plan_private.assert_editor(v_plan);
  if p_title is not null and length(btrim(p_title)) not between 1 and 60 then
    raise exception 'trip_plan_bad_input' using errcode = '22023';
  end if;
  if p_set_overnight then
    perform trip_plan_private.check_point(p_overnight_place_id, p_overnight_lat, p_overnight_lng);
  end if;
  update public.trip_plan_days set
    title = case when p_clear_title then null else coalesce(btrim(p_title), title) end,
    overnight_place_id = case when p_set_overnight then p_overnight_place_id else overnight_place_id end,
    overnight_label = case when p_set_overnight then nullif(btrim(p_overnight_label), '') else overnight_label end,
    overnight_lat = case when p_set_overnight then p_overnight_lat else overnight_lat end,
    overnight_lng = case when p_set_overnight then p_overnight_lng else overnight_lng end,
    route_stops_key = case when p_set_overnight then null else route_stops_key end,
    updated_at = now()
  where id = p_day;
  if p_set_overnight then
    update public.trip_plan_days set route_stops_key = null
    where plan_id = v_plan and position = v_pos + 1;
  end if;
  perform trip_plan_private.touch(v_plan);
end $$;

-- Stops ---------------------------------------------------------------------

-- Adds a place to a day, before p_before_stop or at the end. If the place
-- was on Places to visit it leaves the list. Returns the stop's id.
create function public.add_trip_plan_stop(
  p_day uuid,
  p_place uuid,
  p_before_stop uuid default null,
  p_note text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare v_plan uuid; v_owner uuid; v_stop uuid; v_pos integer;
begin
  select plan_id into v_plan from public.trip_plan_days where id = p_day;
  if v_plan is null then
    raise exception 'trip_plan_not_found' using errcode = 'P0002';
  end if;
  v_owner := trip_plan_private.assert_editor(v_plan);
  perform trip_plan_private.assert_place(p_place);
  if p_note is not null and length(btrim(p_note)) > 200 then
    raise exception 'trip_plan_bad_input' using errcode = '22023';
  end if;
  perform trip_plan_private.assert_stop_room(v_owner, p_day, null);
  v_pos := trip_plan_private.position_before(p_day, p_before_stop, null);
  insert into public.trip_plan_stops (plan_id, day_id, place_id, position, note, added_by)
  values (v_plan, p_day, p_place, v_pos, nullif(btrim(p_note), ''), auth.uid())
  returning id into v_stop;
  delete from public.trip_plan_places where plan_id = v_plan and place_id = p_place;
  update public.trip_plan_days set route_stops_key = null, updated_at = now() where id = p_day;
  perform trip_plan_private.touch(v_plan);
  return v_stop;
end $$;

-- Moves a stop within its day or to another day of the same plan, before
-- p_before_stop or at the end. Only the moved row changes (unless the day
-- needs rebalancing).
create function public.move_trip_plan_stop(
  p_stop uuid,
  p_day uuid,
  p_before_stop uuid default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare v_plan uuid; v_from_day uuid; v_owner uuid; v_pos integer;
begin
  select plan_id, day_id into v_plan, v_from_day from public.trip_plan_stops where id = p_stop;
  if v_plan is null then
    raise exception 'trip_plan_not_found' using errcode = 'P0002';
  end if;
  v_owner := trip_plan_private.assert_editor(v_plan);
  if not exists (select 1 from public.trip_plan_days where id = p_day and plan_id = v_plan)
    or p_before_stop = p_stop then
    raise exception 'trip_plan_bad_input' using errcode = '22023';
  end if;
  if p_day <> v_from_day then
    perform trip_plan_private.assert_stop_room(v_owner, p_day, p_stop);
  end if;
  v_pos := trip_plan_private.position_before(p_day, p_before_stop, p_stop);
  update public.trip_plan_stops set day_id = p_day, position = v_pos, updated_at = now()
  where id = p_stop;
  update public.trip_plan_days set route_stops_key = null, updated_at = now()
  where id in (p_day, v_from_day);
  perform trip_plan_private.touch(v_plan);
end $$;

-- Removes a stop. p_to_list puts the place back on Places to visit.
create function public.remove_trip_plan_stop(p_stop uuid, p_to_list boolean default false)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare v_plan uuid; v_day uuid;
begin
  select plan_id, day_id into v_plan, v_day from public.trip_plan_stops where id = p_stop;
  if v_plan is null then
    raise exception 'trip_plan_not_found' using errcode = 'P0002';
  end if;
  perform trip_plan_private.assert_editor(v_plan);
  if p_to_list then
    insert into public.trip_plan_places (plan_id, place_id, note, added_by)
    select plan_id, place_id, note, added_by from public.trip_plan_stops where id = p_stop
    on conflict (plan_id, place_id) do nothing;
  end if;
  delete from public.trip_plan_stops where id = p_stop;
  update public.trip_plan_days set route_stops_key = null, updated_at = now() where id = v_day;
  perform trip_plan_private.touch(v_plan);
end $$;

-- Sets or clears a stop's note (empty or null clears it).
create function public.set_trip_plan_stop_note(p_stop uuid, p_note text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare v_plan uuid;
begin
  select plan_id into v_plan from public.trip_plan_stops where id = p_stop;
  if v_plan is null then
    raise exception 'trip_plan_not_found' using errcode = 'P0002';
  end if;
  perform trip_plan_private.assert_editor(v_plan);
  if p_note is not null and length(btrim(p_note)) > 200 then
    raise exception 'trip_plan_bad_input' using errcode = '22023';
  end if;
  update public.trip_plan_stops set note = nullif(btrim(p_note), ''), updated_at = now()
  where id = p_stop;
  perform trip_plan_private.touch(v_plan);
end $$;

-- Places to visit -----------------------------------------------------------

-- Adds a place to the list. Adding one already there is a no-op.
create function public.add_trip_plan_place(p_plan uuid, p_place uuid, p_note text default null)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare v_owner uuid;
begin
  v_owner := trip_plan_private.assert_editor(p_plan);
  perform trip_plan_private.assert_place(p_place);
  if p_note is not null and length(btrim(p_note)) > 200 then
    raise exception 'trip_plan_bad_input' using errcode = '22023';
  end if;
  if exists (select 1 from public.trip_plan_places where plan_id = p_plan and place_id = p_place) then
    return;
  end if;
  if (select count(*) from public.trip_plan_places where plan_id = p_plan)
      >= (trip_plan_private.limits(v_owner)->>'max_places')::integer then
    raise exception 'trip_plan_limit_places' using errcode = '54000';
  end if;
  insert into public.trip_plan_places (plan_id, place_id, note, added_by)
  values (p_plan, p_place, nullif(btrim(p_note), ''), auth.uid());
  perform trip_plan_private.touch(p_plan);
end $$;

create function public.remove_trip_plan_place(p_plan uuid, p_place uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform trip_plan_private.assert_editor(p_plan);
  delete from public.trip_plan_places where plan_id = p_plan and place_id = p_place;
  perform trip_plan_private.touch(p_plan);
end $$;

-- Route cache ---------------------------------------------------------------

-- Saves the route the app worked out for a day. p_stops_key is the day's
-- stop ids in order, joined with commas; a key that no longer matches the
-- day (someone changed it meanwhile) is refused. Any member may save it.
create function public.set_trip_plan_day_route(
  p_day uuid,
  p_stops_key text,
  p_distance_m integer,
  p_duration_s integer,
  p_county_codes smallint[]
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare v_plan uuid; v_key text;
begin
  perform trip_plan_private.assert_enabled();
  select plan_id into v_plan from public.trip_plan_days where id = p_day;
  if v_plan is null or not trip_plan_private.is_member(v_plan) then
    raise exception 'trip_plan_not_found' using errcode = 'P0002';
  end if;
  if p_distance_m is null or p_distance_m < 0 or p_duration_s is null or p_duration_s < 0
    or coalesce(cardinality(p_county_codes), 0) > 47 then
    raise exception 'trip_plan_bad_input' using errcode = '22023';
  end if;
  select coalesce(string_agg(id::text, ',' order by position, created_at, id), '')
  into v_key from public.trip_plan_stops where day_id = p_day;
  if p_stops_key is distinct from v_key then
    raise exception 'trip_plan_route_stale' using errcode = '40001';
  end if;
  update public.trip_plan_days set route_stops_key = p_stops_key,
    route_distance_m = p_distance_m, route_duration_s = p_duration_s,
    route_county_codes = coalesce(p_county_codes, '{}'), route_updated_at = now()
  where id = p_day;
end $$;

-- Reads ---------------------------------------------------------------------

-- A plan's places as the app shows them (only places app users can see).
create function trip_plan_private.place_json(p_place uuid)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select jsonb_build_object('id', pl.id, 'name', pl.name, 'type', pl.type,
    'county_code', pl.county_id, 'lat', pl.lat, 'lng', pl.lng,
    'thumbnail_url', (select i.thumbnail_url from public.place_images i
      where i.place_id = pl.id order by i.sort_order, i.id limit 1))
  from public.places pl
  where pl.id = p_place and pl.status = 'reviewed' and pl.archived_at is null;
$$;

-- The caller's plans for the Planned list, newest change first, with what a
-- plan card shows. Upcoming, Shared with you and Past are split in the app.
create function public.list_trip_plans()
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(jsonb_agg(row_json order by updated_at desc), '[]'::jsonb)
  from (
    select p.updated_at, jsonb_build_object(
      'id', p.id, 'title', p.title, 'owner_id', p.owner_id, 'role', m.role,
      'start_date', p.start_date, 'archived', p.archived_at is not null,
      'converted', p.converted_from_saved_trip is not null,
      'muted', m.muted, 'updated_at', p.updated_at,
      'is_past', coalesce(trip_plan_private.is_past(p.id), false),
      'start', case when p.start_lat is not null
        then jsonb_build_object('lat', p.start_lat, 'lng', p.start_lng) end,
      'members', (select coalesce(jsonb_agg(jsonb_build_object(
          'user_id', mm.user_id, 'role', mm.role,
          'handle', qp.handle, 'avatar_url', qp.avatar_url)
          order by mm.role = 'owner' desc, mm.created_at), '[]'::jsonb)
        from public.trip_plan_members mm
        left join public.quest_public_profiles qp on qp.user_id = mm.user_id
        where mm.plan_id = p.id and mm.status = 'joined'),
      'days', (select coalesce(jsonb_agg(jsonb_build_object(
          'id', d.id, 'position', d.position,
          'distance_m', d.route_distance_m, 'duration_s', d.route_duration_s,
          'county_codes', d.route_county_codes,
          'route_fresh', d.route_stops_key is not null,
          'points', (select coalesce(jsonb_agg(jsonb_build_array(pl.lat, pl.lng)
              order by s.position, s.created_at, s.id), '[]'::jsonb)
            from public.trip_plan_stops s join public.places pl on pl.id = s.place_id
            where s.day_id = d.id and pl.status = 'reviewed' and pl.archived_at is null))
          order by d.position), '[]'::jsonb)
        from public.trip_plan_days d where d.plan_id = p.id)
    ) as row_json
    from public.trip_plans p
    join public.trip_plan_members m on m.plan_id = p.id
      and m.user_id = auth.uid() and m.status = 'joined'
  ) plans;
$$;

-- One plan with its days, stops, places to visit, members and limits.
create function public.get_trip_plan(p_plan uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare v_role text; v_result jsonb;
begin
  v_role := trip_plan_private.role_of(p_plan, auth.uid());
  if v_role is null then
    raise exception 'trip_plan_not_found' using errcode = 'P0002';
  end if;
  select jsonb_build_object(
    'id', p.id, 'title', p.title, 'owner_id', p.owner_id, 'role', v_role,
    'start_kind', p.start_kind, 'start_label', p.start_label,
    'start_lat', p.start_lat, 'start_lng', p.start_lng,
    'start_place', trip_plan_private.place_json(p.start_place_id),
    'start_date', p.start_date, 'archived', p.archived_at is not null,
    'converted', p.converted_from_saved_trip is not null,
    'updated_at', p.updated_at, 'updated_by', p.updated_by,
    'updated_by_handle', (select qp.handle from public.quest_public_profiles qp
      where qp.user_id = p.updated_by),
    'limits', trip_plan_private.limits(p.owner_id),
    'days', (select coalesce(jsonb_agg(jsonb_build_object(
        'id', d.id, 'position', d.position, 'title', d.title,
        'overnight_label', d.overnight_label,
        'overnight_lat', d.overnight_lat, 'overnight_lng', d.overnight_lng,
        'overnight_place', trip_plan_private.place_json(d.overnight_place_id),
        'route_stops_key', d.route_stops_key,
        'distance_m', d.route_distance_m, 'duration_s', d.route_duration_s,
        'county_codes', d.route_county_codes,
        'stops', (select coalesce(jsonb_agg(jsonb_build_object(
            'id', s.id, 'note', s.note, 'added_by', s.added_by,
            'added_by_handle', qp.handle, 'updated_at', s.updated_at,
            'place', trip_plan_private.place_json(s.place_id))
            order by s.position, s.created_at, s.id), '[]'::jsonb)
          from public.trip_plan_stops s
          left join public.quest_public_profiles qp on qp.user_id = s.added_by
          where s.day_id = d.id
            and trip_plan_private.place_json(s.place_id) is not null))
        order by d.position), '[]'::jsonb)
      from public.trip_plan_days d where d.plan_id = p.id),
    'places', (select coalesce(jsonb_agg(jsonb_build_object(
        'note', tp.note, 'added_by', tp.added_by, 'added_by_handle', qp.handle,
        'place', trip_plan_private.place_json(tp.place_id))
        order by tp.created_at, tp.id), '[]'::jsonb)
      from public.trip_plan_places tp
      left join public.quest_public_profiles qp on qp.user_id = tp.added_by
      where tp.plan_id = p.id and trip_plan_private.place_json(tp.place_id) is not null),
    'members', (select coalesce(jsonb_agg(jsonb_build_object(
        'user_id', m.user_id, 'role', m.role, 'status', m.status,
        'handle', qp.handle, 'avatar_url', qp.avatar_url)
        order by m.role = 'owner' desc, m.created_at), '[]'::jsonb)
      from public.trip_plan_members m
      left join public.quest_public_profiles qp on qp.user_id = m.user_id
      where m.plan_id = p.id)
  ) into v_result
  from public.trip_plans p where p.id = p_plan;
  return v_result;
end $$;

-- The caller's own limits and how many upcoming plans they have, for the
-- create sheet and the "2 of 3 upcoming plans" line.
create function public.my_trip_plan_limits()
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select trip_plan_private.limits(auth.uid())
    || jsonb_build_object('upcoming_plans', trip_plan_private.upcoming_count(auth.uid()))
  where auth.uid() is not null;
$$;

-- Grants --------------------------------------------------------------------

revoke all on all functions in schema trip_plan_private from public;
grant execute on function trip_plan_private.is_member(uuid) to authenticated;

do $$
declare f text;
begin
  foreach f in array array[
    'create_trip_plan(text, integer, text, uuid, text, double precision, double precision, date, uuid)',
    'update_trip_plan(uuid, text, date, boolean)',
    'set_trip_plan_start(uuid, text, uuid, text, double precision, double precision)',
    'archive_trip_plan(uuid, boolean)',
    'delete_trip_plan(uuid)',
    'add_trip_plan_day(uuid, uuid)',
    'remove_trip_plan_day(uuid)',
    'update_trip_plan_day(uuid, text, boolean, uuid, text, double precision, double precision, boolean)',
    'add_trip_plan_stop(uuid, uuid, uuid, text)',
    'move_trip_plan_stop(uuid, uuid, uuid)',
    'remove_trip_plan_stop(uuid, boolean)',
    'set_trip_plan_stop_note(uuid, text)',
    'add_trip_plan_place(uuid, uuid, text)',
    'remove_trip_plan_place(uuid, uuid)',
    'set_trip_plan_day_route(uuid, text, integer, integer, smallint[])',
    'list_trip_plans()',
    'get_trip_plan(uuid)',
    'my_trip_plan_limits()'
  ] loop
    execute format('revoke execute on function public.%s from public', f);
    execute format('grant execute on function public.%s to authenticated', f);
  end loop;
end $$;
