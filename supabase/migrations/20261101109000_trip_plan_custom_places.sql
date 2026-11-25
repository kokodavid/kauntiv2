-- Trip planner: places outside the Kaunti47 list.
--
-- A stop or a Places to visit item can be a custom place: a name and a
-- point the user searched for (Geoapify / OpenStreetMap) or dropped on the
-- map. Custom places belong to one plan and are visible to its members only.
-- When a matching Kaunti47 place is reviewed later, custom places that
-- match it are upgraded to the real place (see upgrade_custom_places).

create table public.trip_plan_custom_places (
  id uuid primary key default gen_random_uuid(),
  plan_id uuid not null references public.trip_plans (id) on delete cascade,
  name text not null check (length(btrim(name)) between 1 and 80),
  address text check (address is null or length(address) <= 200),
  lat double precision not null check (lat between -90 and 90),
  lng double precision not null check (lng between -180 and 180),
  county_code integer check (county_code is null or county_code between 1 and 47),
  source text not null check (source in ('search', 'pin')),
  created_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now()
);
create index trip_plan_custom_places_plan_idx on public.trip_plan_custom_places (plan_id);

alter table public.trip_plan_custom_places enable row level security;
create policy "Members read custom places" on public.trip_plan_custom_places
  for select to authenticated using (trip_plan_private.is_member(plan_id));
revoke all on public.trip_plan_custom_places from anon, authenticated;
grant select on public.trip_plan_custom_places to authenticated;

do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    alter publication supabase_realtime add table public.trip_plan_custom_places;
  end if;
end $$;

alter table public.trip_plan_stops
  alter column place_id drop not null,
  add column custom_id uuid references public.trip_plan_custom_places (id) on delete cascade,
  add constraint trip_plan_stops_one_place check ((place_id is null) <> (custom_id is null));

alter table public.trip_plan_places
  alter column place_id drop not null,
  add column custom_id uuid references public.trip_plan_custom_places (id) on delete cascade,
  add constraint trip_plan_places_one_place check ((place_id is null) <> (custom_id is null)),
  add constraint trip_plan_places_plan_custom_key unique (plan_id, custom_id);

create index trip_plan_stops_custom_idx on public.trip_plan_stops (custom_id)
  where custom_id is not null;

-- Helpers -------------------------------------------------------------------

create function trip_plan_private.custom_place_json(p_custom uuid)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select jsonb_build_object('id', c.id, 'name', c.name, 'type', 'custom',
    'county_code', coalesce(c.county_code, 0), 'lat', c.lat, 'lng', c.lng,
    'thumbnail_url', null, 'custom', true, 'address', c.address,
    'source', c.source)
  from public.trip_plan_custom_places c where c.id = p_custom;
$$;

-- A stop or idea's place as the app shows it: the Kaunti47 place, or the
-- custom one. Null when the Kaunti47 place is no longer visible.
create function trip_plan_private.item_json(p_place uuid, p_custom uuid)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select case when p_custom is not null
    then trip_plan_private.custom_place_json(p_custom)
    else trip_plan_private.place_json(p_place) end;
$$;

create function trip_plan_private.create_custom_place(
  p_plan uuid, p_name text, p_address text,
  p_lat double precision, p_lng double precision,
  p_county_code integer, p_source text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare v_id uuid;
begin
  if p_name is null or length(btrim(p_name)) not between 1 and 80
    or p_lat is null or p_lng is null
    or p_lat not between -90 and 90 or p_lng not between -180 and 180
    or p_source not in ('search', 'pin')
    or (p_county_code is not null and p_county_code not between 1 and 47)
    or (p_address is not null and length(p_address) > 200) then
    raise exception 'trip_plan_bad_input' using errcode = '22023';
  end if;
  insert into public.trip_plan_custom_places
    (plan_id, name, address, lat, lng, county_code, source, created_by)
  values (p_plan, btrim(p_name), nullif(btrim(p_address), ''), p_lat, p_lng,
    p_county_code, p_source, auth.uid())
  returning id into v_id;
  return v_id;
end $$;

create function trip_plan_private.drop_custom_if_unused(p_custom uuid)
returns void
language sql
security definer
set search_path = ''
as $$
  delete from public.trip_plan_custom_places c
  where c.id = p_custom
    and not exists (select 1 from public.trip_plan_stops s where s.custom_id = c.id)
    and not exists (select 1 from public.trip_plan_places p where p.custom_id = c.id);
$$;

-- Custom stops and ideas ----------------------------------------------------

create function public.add_trip_plan_custom_stop(
  p_day uuid, p_name text, p_address text,
  p_lat double precision, p_lng double precision,
  p_county_code integer, p_source text,
  p_before_stop uuid default null, p_note text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare v_plan uuid; v_owner uuid; v_stop uuid; v_pos integer; v_custom uuid;
begin
  select plan_id into v_plan from public.trip_plan_days where id = p_day;
  if v_plan is null then
    raise exception 'trip_plan_not_found' using errcode = 'P0002';
  end if;
  v_owner := trip_plan_private.assert_editor(v_plan);
  if p_note is not null and length(btrim(p_note)) > 200 then
    raise exception 'trip_plan_bad_input' using errcode = '22023';
  end if;
  perform trip_plan_private.assert_stop_room(v_owner, p_day, null);
  v_custom := trip_plan_private.create_custom_place(
    v_plan, p_name, p_address, p_lat, p_lng, p_county_code, p_source);
  v_pos := trip_plan_private.position_before(p_day, p_before_stop, null);
  insert into public.trip_plan_stops (plan_id, day_id, custom_id, position, note, added_by)
  values (v_plan, p_day, v_custom, v_pos, nullif(btrim(p_note), ''), auth.uid())
  returning id into v_stop;
  update public.trip_plan_days set route_stops_key = null, updated_at = now() where id = p_day;
  perform trip_plan_private.touch(v_plan);
  return v_stop;
end $$;

create function public.add_trip_plan_custom_place(
  p_plan uuid, p_name text, p_address text,
  p_lat double precision, p_lng double precision,
  p_county_code integer, p_source text, p_note text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare v_owner uuid; v_custom uuid;
begin
  v_owner := trip_plan_private.assert_editor(p_plan);
  if p_note is not null and length(btrim(p_note)) > 200 then
    raise exception 'trip_plan_bad_input' using errcode = '22023';
  end if;
  if (select count(*) from public.trip_plan_places where plan_id = p_plan)
      >= (trip_plan_private.limits(v_owner)->>'max_places')::integer then
    raise exception 'trip_plan_limit_places' using errcode = '54000';
  end if;
  v_custom := trip_plan_private.create_custom_place(
    p_plan, p_name, p_address, p_lat, p_lng, p_county_code, p_source);
  insert into public.trip_plan_places (plan_id, custom_id, note, added_by)
  values (p_plan, v_custom, nullif(btrim(p_note), ''), auth.uid());
  perform trip_plan_private.touch(p_plan);
end $$;

-- Takes a custom place off Places to visit.
create function public.remove_trip_plan_custom_place(p_plan uuid, p_custom uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform trip_plan_private.assert_editor(p_plan);
  delete from public.trip_plan_places where plan_id = p_plan and custom_id = p_custom;
  perform trip_plan_private.drop_custom_if_unused(p_custom);
  perform trip_plan_private.touch(p_plan);
end $$;

-- Moves a custom place from Places to visit onto a day.
create function public.add_trip_plan_custom_idea_to_day(
  p_day uuid, p_custom uuid, p_before_stop uuid default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare v_plan uuid; v_owner uuid; v_stop uuid; v_pos integer; v_note text;
begin
  select plan_id into v_plan from public.trip_plan_days where id = p_day;
  if v_plan is null then
    raise exception 'trip_plan_not_found' using errcode = 'P0002';
  end if;
  v_owner := trip_plan_private.assert_editor(v_plan);
  select note into v_note from public.trip_plan_places
  where plan_id = v_plan and custom_id = p_custom;
  if not found then
    raise exception 'trip_plan_not_found' using errcode = 'P0002';
  end if;
  perform trip_plan_private.assert_stop_room(v_owner, p_day, null);
  v_pos := trip_plan_private.position_before(p_day, p_before_stop, null);
  insert into public.trip_plan_stops (plan_id, day_id, custom_id, position, note, added_by)
  values (v_plan, p_day, p_custom, v_pos, v_note, auth.uid())
  returning id into v_stop;
  delete from public.trip_plan_places where plan_id = v_plan and custom_id = p_custom;
  update public.trip_plan_days set route_stops_key = null, updated_at = now() where id = p_day;
  perform trip_plan_private.touch(v_plan);
  return v_stop;
end $$;

-- Removing a stop: Kaunti47 places can go back to Places to visit; a custom
-- place goes back to the list too, or is forgotten.
create or replace function public.remove_trip_plan_stop(p_stop uuid, p_to_list boolean default false)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare v_plan uuid; v_day uuid; v_custom uuid;
begin
  select plan_id, day_id, custom_id into v_plan, v_day, v_custom
  from public.trip_plan_stops where id = p_stop;
  if v_plan is null then
    raise exception 'trip_plan_not_found' using errcode = 'P0002';
  end if;
  perform trip_plan_private.assert_editor(v_plan);
  if p_to_list and v_custom is not null then
    insert into public.trip_plan_places (plan_id, custom_id, note, added_by)
    select plan_id, custom_id, note, added_by from public.trip_plan_stops where id = p_stop
    on conflict (plan_id, custom_id) do nothing;
  elsif p_to_list then
    insert into public.trip_plan_places (plan_id, place_id, note, added_by)
    select plan_id, place_id, note, added_by from public.trip_plan_stops where id = p_stop
    on conflict (plan_id, place_id) do nothing;
  end if;
  delete from public.trip_plan_stops where id = p_stop;
  if v_custom is not null then
    perform trip_plan_private.drop_custom_if_unused(v_custom);
  end if;
  update public.trip_plan_days set route_stops_key = null, updated_at = now() where id = v_day;
  perform trip_plan_private.touch(v_plan);
end $$;

-- Reads ---------------------------------------------------------------------

create or replace function public.list_trip_plans()
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
          'points', (select coalesce(jsonb_agg(jsonb_build_array(x.lat, x.lng)
              order by x.position, x.created_at, x.id), '[]'::jsonb)
            from (
              select s.position, s.created_at, s.id,
                coalesce(pl.lat, c.lat) as lat, coalesce(pl.lng, c.lng) as lng
              from public.trip_plan_stops s
              left join public.places pl on pl.id = s.place_id
                and pl.status = 'reviewed' and pl.archived_at is null
              left join public.trip_plan_custom_places c on c.id = s.custom_id
              where s.day_id = d.id and (pl.id is not null or c.id is not null)
            ) x))
          order by d.position), '[]'::jsonb)
        from public.trip_plan_days d where d.plan_id = p.id)
    ) as row_json
    from public.trip_plans p
    join public.trip_plan_members m on m.plan_id = p.id
      and m.user_id = auth.uid() and m.status = 'joined'
  ) plans;
$$;

create or replace function public.get_trip_plan(p_plan uuid)
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
            'place', trip_plan_private.item_json(s.place_id, s.custom_id))
            order by s.position, s.created_at, s.id), '[]'::jsonb)
          from public.trip_plan_stops s
          left join public.quest_public_profiles qp on qp.user_id = s.added_by
          where s.day_id = d.id
            and trip_plan_private.item_json(s.place_id, s.custom_id) is not null))
        order by d.position), '[]'::jsonb)
      from public.trip_plan_days d where d.plan_id = p.id),
    'places', (select coalesce(jsonb_agg(jsonb_build_object(
        'note', tp.note, 'added_by', tp.added_by, 'added_by_handle', qp.handle,
        'place', trip_plan_private.item_json(tp.place_id, tp.custom_id))
        order by tp.created_at, tp.id), '[]'::jsonb)
      from public.trip_plan_places tp
      left join public.quest_public_profiles qp on qp.user_id = tp.added_by
      where tp.plan_id = p.id
        and trip_plan_private.item_json(tp.place_id, tp.custom_id) is not null),
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

-- Best order reads custom stops too.
create or replace function public.trip_plan_day_order_input(p_day uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare v_plan uuid; v_owner uuid; v_stops jsonb;
begin
  select plan_id into v_plan from public.trip_plan_days where id = p_day;
  if v_plan is null then
    raise exception 'trip_plan_not_found' using errcode = 'P0002';
  end if;
  v_owner := trip_plan_private.assert_editor(v_plan);
  if not coalesce((trip_plan_private.limits(v_owner) ->> 'best_order')::boolean, false) then
    raise exception 'trip_plan_limit_best_order' using errcode = '54000';
  end if;
  delete from public.trip_plan_order_log
  where user_id = auth.uid() and at < now() - interval '1 hour';
  if (select count(*) from public.trip_plan_order_log where user_id = auth.uid()) >= 20 then
    raise exception 'trip_plan_rate_limited' using errcode = '54000';
  end if;
  select coalesce(jsonb_agg(jsonb_build_object('id', s.id,
      'lat', coalesce(pl.lat, c.lat), 'lng', coalesce(pl.lng, c.lng))
    order by s.position, s.created_at, s.id), '[]'::jsonb)
  into v_stops
  from public.trip_plan_stops s
  left join public.places pl on pl.id = s.place_id
  left join public.trip_plan_custom_places c on c.id = s.custom_id
  where s.day_id = p_day;
  if jsonb_array_length(v_stops) < 2 then
    raise exception 'trip_plan_bad_input' using errcode = '22023';
  end if;
  insert into public.trip_plan_order_log (user_id) values (auth.uid());
  return jsonb_build_object('plan_id', v_plan, 'stops', v_stops);
end $$;

-- Grants --------------------------------------------------------------------

do $$
declare f text;
begin
  foreach f in array array[
    'add_trip_plan_custom_stop(uuid, text, text, double precision, double precision, integer, text, uuid, text)',
    'add_trip_plan_custom_place(uuid, text, text, double precision, double precision, integer, text, text)',
    'remove_trip_plan_custom_place(uuid, uuid)',
    'add_trip_plan_custom_idea_to_day(uuid, uuid, uuid)'
  ] loop
    execute format('revoke execute on function public.%s from public', f);
    execute format('grant execute on function public.%s to authenticated', f);
  end loop;
end $$;
