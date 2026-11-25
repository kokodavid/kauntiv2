-- Best order (S11, Pro): the stops of one day in a short driving order.
-- The ordering itself runs in the `plan-best-order` Edge Function (it holds
-- the Mapbox key). This file holds the two database halves: a check that
-- hands the function the day's stops, and the call that applies the result.

-- Each call to the order check, for the rate limit (20 an hour).
create table public.trip_plan_order_log (
  user_id uuid not null references auth.users (id) on delete cascade,
  at timestamptz not null default now()
);
create index trip_plan_order_log_idx on public.trip_plan_order_log (user_id, at);
alter table public.trip_plan_order_log enable row level security;
-- No policies: only the function below touches it.

-- Called by the Edge Function with the member's own token. Raises unless
-- the caller may edit the plan, the owner has Pro, the day has two stops
-- or more and the caller is under the hourly limit. Returns the day's stops
-- in their current order with coordinates.
create function public.trip_plan_day_order_input(p_day uuid)
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
  select coalesce(jsonb_agg(jsonb_build_object('id', s.id, 'lat', pl.lat, 'lng', pl.lng)
    order by s.position, s.created_at, s.id), '[]'::jsonb)
  into v_stops
  from public.trip_plan_stops s
  join public.places pl on pl.id = s.place_id
  where s.day_id = p_day;
  if jsonb_array_length(v_stops) < 2 then
    raise exception 'trip_plan_bad_input' using errcode = '22023';
  end if;
  insert into public.trip_plan_order_log (user_id) values (auth.uid());
  return jsonb_build_object('plan_id', v_plan, 'stops', v_stops);
end $$;

-- Puts a day's stops in the given order. The list must be exactly the
-- day's stops, or the day changed meanwhile ('trip_plan_order_stale').
-- Any editor may reorder by hand; this is also how Best order lands.
create function public.set_trip_plan_day_order(p_day uuid, p_stop_ids uuid[])
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare v_plan uuid;
begin
  select plan_id into v_plan from public.trip_plan_days where id = p_day;
  if v_plan is null then
    raise exception 'trip_plan_not_found' using errcode = 'P0002';
  end if;
  perform trip_plan_private.assert_editor(v_plan);
  if p_stop_ids is null
    or cardinality(p_stop_ids) <> (select count(*) from public.trip_plan_stops where day_id = p_day)
    or cardinality(p_stop_ids) <> (select count(distinct x) from unnest(p_stop_ids) x)
    or exists (select 1 from unnest(p_stop_ids) x
      where not exists (select 1 from public.trip_plan_stops s where s.id = x and s.day_id = p_day))
  then
    raise exception 'trip_plan_order_stale' using errcode = '40001';
  end if;
  update public.trip_plan_stops s
  set position = o.n * 1024, updated_at = now()
  from (select x as id, ordinality as n from unnest(p_stop_ids) with ordinality as t(x, ordinality)) o
  where s.id = o.id;
  update public.trip_plan_days set route_stops_key = null, updated_at = now()
  where id = p_day;
  perform trip_plan_private.touch(v_plan);
end $$;

do $$
declare f text;
begin
  foreach f in array array[
    'trip_plan_day_order_input(uuid)',
    'set_trip_plan_day_order(uuid, uuid[])'
  ] loop
    execute format('revoke execute on function public.%s from public', f);
    execute format('grant execute on function public.%s to authenticated', f);
  end loop;
end $$;
