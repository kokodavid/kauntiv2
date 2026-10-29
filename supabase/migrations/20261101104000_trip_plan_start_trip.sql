-- Start trip from a plan day (S8).
--
-- 1. A recorded Trip may now carry up to 19 planned stops (20 places with
--    the destination), so a Pro day of 20 stops fits. Stops are still only
--    a record of the plan; badges come from where the Trip actually goes.
-- 2. A day can be linked to the Trips recorded for it. A plan is past once
--    every day has a recorded Trip, as well as when its last date passes.

alter table public.journeys drop constraint journeys_stops_is_short_array;
alter table public.journeys
  add constraint journeys_stops_is_short_array check (
    jsonb_typeof(stops) = 'array' and jsonb_array_length(stops) <= 19
  );

create or replace function public.journey_stops_valid(p_stops jsonb)
returns boolean
language sql
immutable
set search_path = public
as $$
  select p_stops is not null
    and jsonb_typeof(p_stops) = 'array'
    and jsonb_array_length(p_stops) <= 19
    and not exists (
      select 1
      from jsonb_array_elements(p_stops) stop
      where jsonb_typeof(stop) <> 'object'
         or jsonb_typeof(stop -> 'place_id') is distinct from 'string'
         or jsonb_typeof(stop -> 'name') is distinct from 'string'
         or length(btrim(stop ->> 'name')) not between 1 and 160
         or jsonb_typeof(stop -> 'lat') is distinct from 'number'
         or jsonb_typeof(stop -> 'lng') is distinct from 'number'
         or (stop ->> 'lat')::double precision not between -90 and 90
         or (stop ->> 'lng')::double precision not between -180 and 180
    );
$$;

-- The link is made when the Trip starts (its id is made on the phone), so
-- there is no foreign key to journeys: the Trip is uploaded when it ends.
-- A link counts once its Trip exists.
create table public.trip_plan_day_recordings (
  id uuid primary key default gen_random_uuid(),
  plan_id uuid not null references public.trip_plans (id) on delete cascade,
  day_id uuid not null references public.trip_plan_days (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  journey_id uuid not null,
  created_at timestamptz not null default now(),
  unique (day_id, user_id, journey_id)
);
create index trip_plan_day_recordings_plan_idx
  on public.trip_plan_day_recordings (plan_id);

alter table public.trip_plan_day_recordings enable row level security;
-- No policies: read and written through the functions below only.

create function public.link_trip_plan_day_recording(p_day uuid, p_journey uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare v_plan uuid;
begin
  perform trip_plan_private.assert_enabled();
  if auth.uid() is null then
    raise exception 'not_signed_in' using errcode = '28000';
  end if;
  select plan_id into v_plan from public.trip_plan_days where id = p_day;
  if v_plan is null or not trip_plan_private.is_member(v_plan) then
    raise exception 'trip_plan_not_found' using errcode = 'P0002';
  end if;
  insert into public.trip_plan_day_recordings (plan_id, day_id, user_id, journey_id)
  values (v_plan, p_day, auth.uid(), p_journey)
  on conflict do nothing;
end $$;

-- My recorded Trips for a plan's days (never other members' Trips): the
-- latest uploaded Trip per day.
create function public.my_trip_plan_recordings(p_plan uuid)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(jsonb_agg(row_json), '[]'::jsonb)
  from (
    select distinct on (r.day_id) jsonb_build_object(
      'day_id', r.day_id, 'journey_id', j.id,
      'started_at', j.started_at, 'ended_at', j.ended_at) as row_json
    from public.trip_plan_day_recordings r
    join public.journeys j on j.id = r.journey_id and j.user_id = r.user_id
    where r.plan_id = p_plan and r.user_id = auth.uid()
      and trip_plan_private.is_member(p_plan)
    order by r.day_id, j.started_at desc
  ) t;
$$;

revoke execute on function public.link_trip_plan_day_recording(uuid, uuid) from public;
revoke execute on function public.my_trip_plan_recordings(uuid) from public;
grant execute on function public.link_trip_plan_day_recording(uuid, uuid) to authenticated;
grant execute on function public.my_trip_plan_recordings(uuid) to authenticated;

-- Past: the last date has gone by, or every day has a recorded Trip.
create or replace function trip_plan_private.is_past(p_plan uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select (
      p.start_date is not null
      and p.start_date + (
        (select count(*) from public.trip_plan_days d where d.plan_id = p.id)::integer - 1
      ) < current_date
    )
    or (
      exists (select 1 from public.trip_plan_days d where d.plan_id = p.id)
      and not exists (
        select 1 from public.trip_plan_days d
        where d.plan_id = p.id
          and not exists (
            select 1 from public.trip_plan_day_recordings r
            join public.journeys j on j.id = r.journey_id
            where r.day_id = d.id)
      )
    )
  from public.trip_plans p where p.id = p_plan;
$$;
