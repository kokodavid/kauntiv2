-- Slice 4 and 5 of the notifications plan: the trip-paused reminder switch
-- and the weekly "weekend idea" push, with settings the person can change.

alter table public.profiles
  add column if not exists notify_trip_alerts boolean not null default true,
  -- Weekend idea settings (Settings > Notifications > Weekend ideas).
  add column if not exists weekend_use_saved boolean not null default true,
  add column if not exists weekend_include_nearby boolean not null default true,
  add column if not exists weekend_radius_km integer not null default 200;

alter table public.profiles
  drop constraint if exists profiles_weekend_radius_km_known;
alter table public.profiles
  add constraint profiles_weekend_radius_km_known
  check (weekend_radius_km in (50, 100, 200, 300));

-- Picks at most one place per opted-in person and queues a push.
--   1. Saved first: a saved trip plan's destination, then a saved place not
--      yet ticked off. A saved place is not suggested again for 6 weeks.
--   2. Only when the person has saved nothing at all: a reviewed place
--      within weekend_radius_km of their home county's centre that matches
--      their interests (any place when they have none), never one already
--      suggested. The server knows no live position, so the home county is
--      the only starting point.
-- Each part follows the person's own weekend settings. People with no
-- match get nothing: a weak suggestion is worse than none. Runs Thursdays
-- 16:30 EAT.
create or replace function public.enqueue_weekend_plans()
returns integer
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_week text := to_char((now() at time zone 'Africa/Nairobi')::date, 'IYYY-IW');
  v_count integer;
begin
  perform public.push_require_service();

  with eligible as (
    select p.*
    from public.profiles p
    where p.notify_weekend_plans
      and exists (select 1 from public.push_devices d
                  where d.user_id = p.id and d.os_permission <> 'denied')
  ), saved as (
    select e.id as user_id, t.destination_place_id as place_id, 1 as pri,
           t.name as trip_name
    from eligible e
    join public.saved_trips t on t.user_id = e.id
    where e.weekend_use_saved
    union all
    select e.id, w.place_id, 2, null
    from eligible e
    join public.wishlist_items w on w.user_id = e.id
    where e.weekend_use_saved and w.place_id is not null and w.ticked_at is null
  ), saved_ready as (
    select s.*
    from saved s
    join public.places pl on pl.id = s.place_id
    where pl.status = 'reviewed' and pl.archived_at is null
      and not exists (
        select 1 from public.push_events x
        where x.user_id = s.user_id and x.kind = 'weekend_plan'
          and x.payload ->> 'dest_id' = s.place_id::text
          and x.created_at > now() - interval '42 days')
  ), nearby as (
    select e.id as user_id, pl.id as place_id, 3 as pri, null::text as trip_name
    from eligible e
    join public.counties hc on hc.id = e.home_county_id
    join public.places pl on pl.status = 'reviewed' and pl.archived_at is null
    where e.weekend_include_nearby
      and not exists (select 1 from saved s where s.user_id = e.id)
      and ST_DistanceSphere(hc.centroid, pl.location) <= e.weekend_radius_km * 1000
      and (cardinality(e.interests) = 0 or exists (
            select 1 from public.interest_place_types ipt
            where ipt.interest_key = any (e.interests)
              and ipt.place_type = lower(pl.type)))
      and not exists (
        select 1 from public.push_events x
        where x.user_id = e.id and x.kind = 'weekend_plan'
          and x.payload ->> 'dest_id' = pl.id::text)
  ), ranked as (
    select u.*,
           row_number() over (
             partition by u.user_id
             order by u.pri, md5(u.user_id::text || u.place_id::text || v_week)
           ) as rn
    from (select * from saved_ready union all select * from nearby) u
  ), ins as (
    insert into public.push_events (user_id, kind, delivery, payload, dedupe_key, send_after)
    select r.user_id, 'weekend_plan', 'push',
           jsonb_build_object(
             'title', case r.pri when 1 then 'Your saved plan' when 2 then 'Still on your list' else 'A weekend idea' end,
             'body', case r.pri
               when 1 then 'Your plan "' || r.trip_name || '" is ready when you are.'
               when 2 then 'You saved ' || pl.name || '. This weekend could be the one.'
               else pl.name || ' in ' || c.name || ' is a good weekend trip.' end,
             'dest_kind', 'place',
             'dest_id', r.place_id::text),
           'weekend:' || v_week || ':' || r.user_id,
           public.push_next_send_time(now())
    from ranked r
    join public.places pl on pl.id = r.place_id
    join public.counties c on c.id = pl.county_id
    where r.rn = 1
    on conflict (dedupe_key) do nothing
    returning 1
  )
  select count(*) into v_count from ins;
  return v_count;
end;
$$;

revoke all on function public.enqueue_weekend_plans() from public, anon, authenticated;
grant execute on function public.enqueue_weekend_plans() to service_role;

-- Thursday 16:30 East Africa Time is 13:30 UTC. Skipped where pg_cron is not
-- installed; schedule it by hand there.
do $$
begin
  if exists (select 1 from pg_extension where extname = 'pg_cron') then
    perform cron.schedule('weekend-plans', '30 13 * * 4',
      'select public.enqueue_weekend_plans()');
  end if;
end;
$$;
