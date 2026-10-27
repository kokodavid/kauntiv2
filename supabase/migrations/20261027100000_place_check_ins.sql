set search_path = extensions, public;

-- Place check-ins: the evidence behind Bronze, Silver and Gold.
--
-- A user taps "I'm here" at a place. The app sends one GPS reading and the
-- server decides whether it counts: close enough to the place, accurate
-- enough, and not repeated. Free for everyone (no recording needed).
--
-- Switched on and off from Feature settings through app_feature_flags
-- ('place_check_ins'), off by default, and checked here so a paused feature
-- refuses check-ins even from an old app build.
--
-- Passport thresholds (places, categories, visit days) live in the app's
-- PassportRules; this migration only records and reads evidence.

-- Radius ------------------------------------------------------------------
-- How close counts as "at the place". Large areas get a wide circle, small
-- sights a tight one. places.check_in_radius_m overrides the default for one
-- place (set it from the dashboard or SQL when a place needs it).
alter table public.places
  add column if not exists check_in_radius_m integer
  check (check_in_radius_m is null or check_in_radius_m between 25 and 5000);

create or replace function public.place_check_in_radius(
  p_type text,
  p_override integer
)
returns integer
language sql
immutable
as $$
  select coalesce(
    p_override,
    case
      when p_type in (
        'park', 'conservancy', 'forest', 'desert', 'lake', 'marine_park',
        'island', 'mountain'
      ) then 800
      when p_type in ('beach', 'hike', 'river') then 500
      when p_type in (
        'waterfall', 'cave', 'hot_spring', 'viewpoint', 'garden'
      ) then 250
      else 150
    end
  );
$$;

-- Evidence ----------------------------------------------------------------
create table if not exists public.place_check_ins (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  place_id uuid not null references public.places (id) on delete cascade,
  -- The place's county, copied so progress reads need no join.
  county_id smallint not null references public.counties (id),
  checked_in_at timestamptz not null default now(),
  -- The Nairobi calendar day: one check-in per place per day, and the
  -- "visit days" a milestone counts.
  visit_day date not null,
  distance_m integer not null check (distance_m >= 0),
  accuracy_m integer check (accuracy_m is null or accuracy_m >= 0),
  unique (user_id, place_id, visit_day)
);

create index if not exists place_check_ins_user_county_idx
  on public.place_check_ins (user_id, county_id);
create index if not exists place_check_ins_place_idx
  on public.place_check_ins (place_id);

alter table public.place_check_ins enable row level security;

drop policy if exists "Users read their own check-ins" on public.place_check_ins;
create policy "Users read their own check-ins"
  on public.place_check_ins
  for select
  to authenticated
  using (user_id = auth.uid());
-- No insert/update/delete policies: check_in_to_place() is the only write.

-- Switch ------------------------------------------------------------------
alter table public.app_feature_flags
  drop constraint if exists app_feature_flags_feature_key_check;
alter table public.app_feature_flags add constraint app_feature_flags_feature_key_check
  check (feature_key in (
    'county_news', 'public_trips_read', 'public_trips_publish',
    'place_photos', 'push_broadcasts', 'place_check_ins'
  ));
insert into public.app_feature_flags (feature_key, enabled)
values ('place_check_ins', false)
on conflict (feature_key) do nothing;

create or replace function public.set_place_check_ins_enabled_dashboard(
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
  if p_enabled is null then
    raise exception 'Enabled value is required' using errcode = '22004';
  end if;
  insert into public.app_feature_flags (feature_key, enabled, updated_at, updated_by)
  values ('place_check_ins', p_enabled, now(), auth.uid())
  on conflict (feature_key) do update
  set enabled = excluded.enabled,
      updated_at = excluded.updated_at,
      updated_by = excluded.updated_by;
  return p_enabled;
end;
$$;

revoke execute on function public.set_place_check_ins_enabled_dashboard(boolean)
  from public, anon;
grant execute on function public.set_place_check_ins_enabled_dashboard(boolean)
  to authenticated;

-- Check in ----------------------------------------------------------------
-- Expected outcomes come back as data so the app can show the distance:
--   {"ok": true,  "already": false, "distance_m": 41, "radius_m": 250, ...}
--   {"ok": false, "reason": "too_far" | "low_accuracy" | "daily_limit"
--                         | "place_unavailable", ...}
-- Only a signed-out caller or a paused feature raises (errors 'feature_off').
create or replace function public.check_in_to_place(
  p_place_id uuid,
  p_lat double precision,
  p_lng double precision,
  p_accuracy_m double precision
)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_user uuid := auth.uid();
  v_place record;
  v_radius integer;
  v_distance integer;
  v_accuracy integer;
  v_day date := (now() at time zone 'Africa/Nairobi')::date;
  v_inserted integer;
begin
  if v_user is null then
    raise exception 'Sign in to check in' using errcode = '42501';
  end if;
  if not exists (
    select 1 from public.app_feature_flags
    where feature_key = 'place_check_ins' and enabled
  ) then
    raise exception 'feature_off' using errcode = 'P0001';
  end if;
  if p_place_id is null or p_lat is null or p_lng is null
     or p_lat not between -90 and 90 or p_lng not between -180 and 180 then
    raise exception 'Missing or invalid location' using errcode = '22004';
  end if;

  select p.id, p.name, p.type, p.county_id,
         public.place_check_in_radius(p.type, p.check_in_radius_m) as radius,
         round(st_distance(
           p.location::geography,
           st_setsrid(st_makepoint(p_lng, p_lat), 4326)::geography
         ))::integer as distance
    into v_place
  from public.places p
  where p.id = p_place_id and p.status = 'reviewed' and p.archived_at is null;

  if not found then
    return jsonb_build_object('ok', false, 'reason', 'place_unavailable');
  end if;

  v_radius := v_place.radius;
  v_distance := v_place.distance;
  v_accuracy := case when p_accuracy_m is null then null
                     else round(greatest(p_accuracy_m, 0))::integer end;

  -- A fix worse than 100 m can't say where the person is.
  if v_accuracy is null or v_accuracy > 100 then
    return jsonb_build_object(
      'ok', false, 'reason', 'low_accuracy',
      'distance_m', v_distance, 'radius_m', v_radius,
      'accuracy_m', v_accuracy
    );
  end if;

  -- Within the radius, with up to 50 m of slack for the phone's own error.
  if v_distance > v_radius + least(v_accuracy, 50) then
    return jsonb_build_object(
      'ok', false, 'reason', 'too_far',
      'distance_m', v_distance, 'radius_m', v_radius
    );
  end if;

  if (
    select count(*) from public.place_check_ins
    where user_id = v_user and visit_day = v_day
  ) >= 20 then
    return jsonb_build_object('ok', false, 'reason', 'daily_limit');
  end if;

  insert into public.place_check_ins (
    user_id, place_id, county_id, visit_day, distance_m, accuracy_m
  )
  values (
    v_user, v_place.id, v_place.county_id, v_day, v_distance, v_accuracy
  )
  on conflict (user_id, place_id, visit_day) do nothing;
  get diagnostics v_inserted = row_count;

  return jsonb_build_object(
    'ok', true,
    'already', v_inserted = 0,
    'place_id', v_place.id,
    'place_name', v_place.name,
    'county_id', v_place.county_id,
    'distance_m', v_distance,
    'radius_m', v_radius
  );
end;
$$;

revoke execute on function public.check_in_to_place(
  uuid, double precision, double precision, double precision
) from public, anon;
grant execute on function public.check_in_to_place(
  uuid, double precision, double precision, double precision
) to authenticated;

-- Read back ---------------------------------------------------------------
-- What a county has verified for the caller: the places (first check-in each,
-- with the place's type as its category) and how many distinct days.
-- `enabled` lets the Passport show the Bronze-to-Gold card as live or "Later".
create or replace function public.my_county_check_ins(p_county_id smallint)
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  with mine as (
    select c.place_id, c.visit_day, c.checked_in_at
    from public.place_check_ins c
    where c.user_id = auth.uid() and c.county_id = p_county_id
  ),
  firsts as (
    select distinct on (m.place_id) m.place_id, m.checked_in_at
    from mine m
    order by m.place_id, m.checked_in_at
  )
  select jsonb_build_object(
    'enabled', exists (
      select 1 from public.app_feature_flags
      where feature_key = 'place_check_ins' and enabled
    ),
    'visit_days', (select count(distinct visit_day) from mine),
    'places', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', p.id,
        'name', p.name,
        'category', p.type,
        'visited_at', f.checked_in_at
      ) order by f.checked_in_at)
      from firsts f
      join public.places p on p.id = f.place_id
    ), '[]'::jsonb)
  );
$$;

revoke execute on function public.my_county_check_ins(smallint)
  from public, anon;
grant execute on function public.my_county_check_ins(smallint)
  to authenticated;

-- Whole-passport summary ----------------------------------------------------
-- One row per county the caller has checked in at, plus the county's reviewed
-- place count (a county with few places lowers its own targets). The app
-- turns these into Bronze/Silver/Gold using its PassportRules.
create or replace function public.my_check_in_summary()
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select jsonb_build_object(
    'enabled', exists (
      select 1 from public.app_feature_flags
      where feature_key = 'place_check_ins' and enabled
    ),
    'counties', coalesce((
      select jsonb_agg(jsonb_build_object(
        'county_id', s.county_id,
        'places', s.places,
        'categories', s.categories,
        'visit_days', s.visit_days,
        'places_total', (
          select count(*) from public.places p
          where p.county_id = s.county_id
            and p.status = 'reviewed' and p.archived_at is null
        )
      ))
      from (
        select c.county_id,
               count(distinct c.place_id) as places,
               count(distinct p.type) as categories,
               count(distinct c.visit_day) as visit_days
        from public.place_check_ins c
        join public.places p on p.id = c.place_id
        where c.user_id = auth.uid()
        group by c.county_id
      ) s
    ), '[]'::jsonb)
  );
$$;

revoke execute on function public.my_check_in_summary() from public, anon;
grant execute on function public.my_check_in_summary() to authenticated;
