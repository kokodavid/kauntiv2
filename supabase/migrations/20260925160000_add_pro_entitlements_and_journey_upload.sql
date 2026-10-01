-- Journeys step 3: a server-side Pro entitlement and the one write path for
-- completed Journeys.
--
-- Pro is stored as entitlement periods. Until billing exists (tracker #12)
-- periods are granted by admins; store/M-Pesa receipts will insert periods
-- through their own server paths later. Clients can read their own periods
-- but never write them.

create table public.pro_entitlement_periods (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  starts_at timestamptz not null,
  -- Null: open-ended until an admin (or billing) closes it.
  ends_at timestamptz,
  source text not null default 'admin'
    check (source in ('admin', 'app_store', 'play_store', 'mpesa')),
  reference text check (reference is null or length(reference) <= 200),
  created_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now(),
  constraint pro_entitlement_periods_order
    check (ends_at is null or ends_at > starts_at)
);

create index pro_entitlement_periods_user_idx
  on public.pro_entitlement_periods (user_id, starts_at desc);

alter table public.pro_entitlement_periods enable row level security;

create policy "Users can read their own Pro periods"
  on public.pro_entitlement_periods for select to authenticated
  using (user_id = (select auth.uid()) or public.is_admin());

create policy "Admins manage Pro periods"
  on public.pro_entitlement_periods for all to authenticated
  using (public.has_admin_role('admin'))
  with check (public.has_admin_role('admin'));

grant select, insert, update, delete on public.pro_entitlement_periods
  to authenticated;

-- Whether [p_user_id] had Pro at [p_at]. Internal: used by the upload.
create function public.has_pro_at(p_user_id uuid, p_at timestamptz)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.pro_entitlement_periods period
    where period.user_id = p_user_id
      and period.starts_at <= p_at
      and (period.ends_at is null or period.ends_at > p_at)
  );
$$;

revoke execute on function public.has_pro_at(uuid, timestamptz) from public;

-- The signed-in user's Pro right now, for gating Start Journey in the app.
-- The app may cache it for offline starts; the upload re-checks on the
-- server, so the cache can never grant a cloud write.
create function public.my_pro_status()
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select jsonb_build_object(
    'active', current_period.id is not null,
    'active_until', current_period.ends_at,
    'checked_at', now()
  )
  from (select 1) as anchor
  left join lateral (
    select period.id, period.ends_at
    from public.pro_entitlement_periods period
    where period.user_id = auth.uid()
      and period.starts_at <= now()
      and (period.ends_at is null or period.ends_at > now())
    order by period.ends_at desc nulls first
    limit 1
  ) as current_period on true;
$$;

revoke execute on function public.my_pro_status() from public;
grant execute on function public.my_pro_status() to authenticated;

-- The upload payload as rows, in recording order. A SQL helper instead of a
-- temporary table: PL/pgSQL caches plans against temp-table OIDs, which
-- breaks on pooled connections.
create function public.journey_upload_rows(p_points jsonb)
returns table (
  sequence_number integer,
  segment_number integer,
  recorded_at timestamptz,
  latitude numeric,
  longitude numeric,
  accuracy_m numeric
)
language sql
stable
set search_path = public
as $$
  select
    (e.ord - 1)::integer,
    (e.p ->> 'segment')::integer,
    (e.p ->> 'recorded_at')::timestamptz,
    (e.p ->> 'lat')::numeric,
    (e.p ->> 'lng')::numeric,
    (e.p ->> 'accuracy_m')::numeric
  from jsonb_array_elements(p_points) with ordinality as e (p, ord);
$$;

revoke execute on function public.journey_upload_rows(jsonb) from public;

-- Uploads one completed Journey with its points, in one transaction.
--
-- p_points is a JSON array in recording order of
--   {"segment": int, "recorded_at": timestamptz, "lat": num, "lng": num,
--    "accuracy_m": num}
-- Sequence numbers are the array order. Distance is computed here, within
-- segments only (a pause gap is never counted).
--
-- Rules:
-- - p_user_id is the signed-in account (42501), so an account switch
--   mid-request can never file one account's route under another;
-- - the caller owns the Journey (42501);
-- - Pro was active when the Journey started; it may have lapsed since, so a
--   session that began with Pro can still finish and upload (42501);
-- - timing is sane: ends after it starts, not in the future (5 min clock
--   skew), at most 7 days long, started within the last 90 days (22023);
-- - points sit inside the Journey, strictly increase in time and never go
--   back a segment (22023); at most 50,000 points (22023);
-- - a retry of an already uploaded Journey returns it unchanged.
create function public.upload_journey(
  p_user_id uuid,
  p_journey_id uuid,
  p_title text,
  p_started_at timestamptz,
  p_ended_at timestamptz,
  p_points jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_existing public.journeys;
  v_count integer;
  v_bad integer;
  v_distance numeric;
begin
  if v_user is null or v_user <> p_user_id then
    raise exception 'Journey owner does not match the signed-in account'
      using errcode = '42501';
  end if;

  select * into v_existing from public.journeys where id = p_journey_id;
  if found then
    if v_existing.user_id <> v_user then
      raise exception 'Journey belongs to another account'
        using errcode = '42501';
    end if;
    return jsonb_build_object(
      'id', v_existing.id,
      'distance_m', v_existing.distance_m,
      'already_uploaded', true
    );
  end if;

  if p_ended_at <= p_started_at
     or p_ended_at > now() + interval '5 minutes'
     or p_ended_at - p_started_at > interval '7 days'
     or p_started_at < now() - interval '90 days' then
    raise exception 'Journey timing is not valid' using errcode = '22023';
  end if;

  if not public.has_pro_at(v_user, p_started_at) then
    raise exception 'Pro was not active when this Journey started'
      using errcode = '42501';
  end if;

  if p_points is null or jsonb_typeof(p_points) <> 'array' then
    raise exception 'Journey points must be an array' using errcode = '22023';
  end if;
  v_count := jsonb_array_length(p_points);
  if v_count > 50000 then
    raise exception 'Too many Journey points' using errcode = '22023';
  end if;

  select count(*) into v_bad
  from (
    select
      point.*,
      lag(point.recorded_at) over w as previous_at,
      lag(point.segment_number) over w as previous_segment
    from public.journey_upload_rows(p_points) point
    window w as (order by point.sequence_number)
  ) checked
  where checked.segment_number is null
     or checked.recorded_at is null
     or checked.latitude is null
     or checked.longitude is null
     or checked.accuracy_m is null
     or checked.segment_number < 0
     or checked.recorded_at < p_started_at
     or checked.recorded_at > p_ended_at
     or checked.recorded_at <= checked.previous_at
     or checked.segment_number < checked.previous_segment;
  if v_bad > 0 then
    raise exception 'Journey points are not valid' using errcode = '22023';
  end if;

  select coalesce(sum(
    2 * 6371000 * asin(sqrt(
      power(sin(radians(pair.latitude - pair.previous_latitude) / 2), 2)
      + cos(radians(pair.previous_latitude)) * cos(radians(pair.latitude))
        * power(sin(radians(pair.longitude - pair.previous_longitude) / 2), 2)
    ))
  ), 0) into v_distance
  from (
    select
      point.latitude,
      point.longitude,
      lag(point.latitude) over w as previous_latitude,
      lag(point.longitude) over w as previous_longitude
    from public.journey_upload_rows(p_points) point
    window w as (partition by point.segment_number order by point.sequence_number)
  ) pair
  where pair.previous_latitude is not null;

  insert into public.journeys (
    id, user_id, title, started_at, ended_at, distance_m
  ) values (
    p_journey_id, v_user, p_title, p_started_at, p_ended_at,
    round(v_distance, 2)
  );

  insert into public.journey_points (
    journey_id, sequence_number, segment_number, recorded_at,
    latitude, longitude, accuracy_m
  )
  select
    p_journey_id, sequence_number, segment_number, recorded_at,
    round(latitude, 6), round(longitude, 6), round(accuracy_m, 2)
  from public.journey_upload_rows(p_points);

  return jsonb_build_object(
    'id', p_journey_id,
    'distance_m', round(v_distance, 2),
    'already_uploaded', false
  );
end;
$$;

revoke execute on function public.upload_journey(uuid, uuid, text, timestamptz, timestamptz, jsonb)
  from public;
grant execute on function public.upload_journey(uuid, uuid, text, timestamptz, timestamptz, jsonb)
  to authenticated;
