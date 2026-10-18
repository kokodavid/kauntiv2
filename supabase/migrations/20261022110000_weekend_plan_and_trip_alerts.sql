-- Slice 4 and 5 of the notifications plan: the trip-paused reminder switch
-- and the weekly "weekend idea" push.

alter table public.profiles
  add column if not exists notify_trip_alerts boolean not null default true;

-- Picks one place per opted-in person and queues a push. A place is chosen
-- from reviewed, unarchived places anywhere in Kenya that match the
-- person's interests (any place when they have none), skipping places they
-- saved and places already suggested to them. Home county plays no part.
-- People with no match get nothing: a weak suggestion is worse than none.
-- Runs Thursdays 16:30 EAT.
create or replace function public.enqueue_weekend_plans()
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_week text := to_char((now() at time zone 'Africa/Nairobi')::date, 'IYYY-IW');
  v_count integer;
begin
  perform public.push_require_service();

  with candidates as (
    select p.id as user_id,
           pl.id as place_id,
           pl.name as place_name,
           c.name as county_name,
           row_number() over (
             partition by p.id
             order by md5(p.id::text || pl.id::text || v_week)
           ) as rn
    from public.profiles p
    join public.places pl on true
    join public.counties c on c.id = pl.county_id
    where p.notify_weekend_plans
      and pl.status = 'reviewed'
      and pl.archived_at is null
      and exists (select 1 from public.push_devices d
                  where d.user_id = p.id and d.os_permission <> 'denied')
      and (cardinality(p.interests) = 0 or exists (
            select 1 from public.interest_place_types ipt
            where ipt.interest_key = any (p.interests)
              and ipt.place_type = lower(pl.type)))
      and not exists (select 1 from public.wishlist_items w
                      where w.user_id = p.id and w.place_id = pl.id)
      and not exists (select 1 from public.push_events e
                      where e.user_id = p.id and e.kind = 'weekend_plan'
                        and e.payload ->> 'dest_id' = pl.id::text)
  ), ins as (
    insert into public.push_events (user_id, kind, delivery, payload, dedupe_key, send_after)
    select user_id, 'weekend_plan', 'push',
           jsonb_build_object(
             'title', 'A weekend idea',
             'body', place_name || ' in ' || county_name || ' is worth a visit.',
             'dest_kind', 'place',
             'dest_id', place_id::text),
           'weekend:' || v_week || ':' || user_id,
           public.push_next_send_time(now())
    from candidates
    where rn = 1
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
