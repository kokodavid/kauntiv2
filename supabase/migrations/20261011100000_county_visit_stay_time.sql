-- How long someone stayed on each visit, so a county they only passed
-- through can show "you stayed about 40 min, 2 hours earns the badge".
--
-- county_visit_events.stay_seconds: entered_at to the moment the phone
-- resolved the visit (the exit, or the dwell check). Null for visits
-- recorded before this, and for older app builds that don't send it.
--
-- Stays do not add up: each entry starts its own timer, and a visit under
-- the dwell threshold resolves as passed-through on its own. This only
-- reports the latest one.

alter table public.county_visit_events
  add column if not exists stay_seconds integer
    check (stay_seconds is null or stay_seconds >= 0);

drop function if exists public.record_county_visit(smallint, text, timestamptz);

create or replace function public.record_county_visit(
  p_county_id smallint,
  p_outcome text,
  p_entered_at timestamptz,
  p_stay_seconds integer default null
)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_user_id uuid := auth.uid();
  v_existing public.county_visits;
begin
  if v_user_id is null then
    raise exception 'record_county_visit requires an authenticated user';
  end if;

  if p_outcome not in ('explored', 'passed_through') then
    raise exception 'record_county_visit: invalid outcome %', p_outcome;
  end if;

  insert into public.county_visit_events (
    user_id,
    county_id,
    outcome,
    source,
    entered_at,
    confirmed_at,
    stay_seconds
  )
  values (
    v_user_id,
    p_county_id,
    p_outcome,
    'automatic',
    p_entered_at,
    now(),
    case when p_stay_seconds is null then null else greatest(p_stay_seconds, 0) end
  );

  select * into v_existing
  from public.county_visits
  where user_id = v_user_id and county_id = p_county_id
  for update;

  if not found then
    insert into public.county_visits (
      user_id,
      county_id,
      state,
      entered_at,
      confirmed_at,
      pass_count
    )
    values (
      v_user_id,
      p_county_id,
      p_outcome,
      p_entered_at,
      case when p_outcome = 'explored' then now() else null end,
      1
    );
    return;
  end if;

  if v_existing.state = 'explored' then
    update public.county_visits
      set pass_count = pass_count + 1
      where id = v_existing.id;
    return;
  end if;

  update public.county_visits
    set state = p_outcome,
        entered_at = p_entered_at,
        pass_count = pass_count + 1,
        confirmed_at = case
          when p_outcome = 'explored' then now()
          else confirmed_at
        end
    where id = v_existing.id;
end;
$$;

revoke execute on function public.record_county_visit(smallint, text, timestamptz, integer) from public;
grant execute on function public.record_county_visit(smallint, text, timestamptz, integer) to authenticated;

drop function if exists public.sync_county_visit(uuid, smallint, text, timestamptz);

-- Older builds call this with four named arguments and still work: the
-- fifth has a default.
create or replace function public.sync_county_visit(
  p_user_id uuid,
  p_county_id smallint,
  p_outcome text,
  p_entered_at timestamptz,
  p_stay_seconds integer default null
) returns jsonb
language plpgsql
set search_path = public
as $$
declare
  v_inserted integer;
  v_visits jsonb;
begin
  if auth.uid() is null or auth.uid() <> p_user_id then
    raise exception 'Visit owner does not match authenticated account' using errcode = '42501';
  end if;
  -- Serialize all visits for an account, including first visits with no row yet.
  perform pg_advisory_xact_lock(hashtextextended(p_user_id::text, 0));
  insert into public.county_visit_receipts(user_id, county_id, entered_at, outcome)
    values (p_user_id, p_county_id, p_entered_at, p_outcome)
    on conflict do nothing;
  get diagnostics v_inserted = row_count;
  if v_inserted = 1 then
    perform public.record_county_visit(
      p_county_id, p_outcome, p_entered_at, p_stay_seconds
    );
  end if;
  select coalesce(jsonb_agg(jsonb_build_object('county_id', county_id, 'state', state)
      order by county_id), '[]'::jsonb) into v_visits
    from public.county_visits where user_id = p_user_id;
  return v_visits;
end;
$$;
revoke execute on function public.sync_county_visit(uuid, smallint, text, timestamptz, integer) from public;
grant execute on function public.sync_county_visit(uuid, smallint, text, timestamptz, integer) to authenticated;

-- County badge detail gains the passed-through facts: how many times, the
-- latest pass and how long that stay was.
create or replace function public.county_badge_detail(p_county_id smallint)
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  with visit as (
    select v.state, v.confirmed_at, v.pass_count
    from public.county_visits v
    where v.user_id = auth.uid() and v.county_id = p_county_id
  ),
  explored as (
    select
      count(*) as visits,
      count(distinct date_trunc('month', e.entered_at)) as months,
      max(e.entered_at) as last_at
    from public.county_visit_events e
    where e.user_id = auth.uid()
      and e.county_id = p_county_id
      and e.outcome = 'explored'
  ),
  last_visit as (
    select max(e.entered_at) as at
    from public.county_visit_events e
    where e.user_id = auth.uid() and e.county_id = p_county_id
  ),
  last_pass as (
    select e.entered_at as at, e.stay_seconds as stay
    from public.county_visit_events e
    where e.user_id = auth.uid()
      and e.county_id = p_county_id
      and e.outcome = 'passed_through'
    order by e.entered_at desc
    limit 1
  ),
  journeys as (
    select count(distinct jc.journey_id) as count,
           coalesce(sum(jc.distance_m), 0) as distance
    from public.journey_counties jc
    where jc.user_id = auth.uid() and jc.county_id = p_county_id
  ),
  saved as (
    select
      count(distinct w.place_id) as saved,
      count(distinct w.place_id) filter (where w.ticked_at is not null)
        as visited
    from public.wishlist_items w
    where w.user_id = auth.uid()
      and w.county_id = p_county_id
      and w.place_id is not null
  ),
  county_places as (
    select count(*) as total
    from public.places p
    where p.county_id = p_county_id
  ),
  suggestions as (
    select coalesce(
      jsonb_agg(
        jsonb_build_object(
          'id', s.id,
          'name', s.name,
          'type', s.type,
          'summary', s.summary,
          'lat', s.lat,
          'lng', s.lng,
          'thumbnail_url', s.thumbnail_url,
          'saved', s.saved
        )
        order by s.name
      ),
      '[]'::jsonb
    ) as list
    from (
      select
        p.id, p.name, p.type, p.summary, p.lat, p.lng,
        (
          select i.thumbnail_url
          from public.place_images i
          where i.place_id = p.id
          order by i.sort_order
          limit 1
        ) as thumbnail_url,
        exists (
          select 1 from public.wishlist_items w
          where w.user_id = auth.uid() and w.place_id = p.id
        ) as saved
      from public.places p
      where p.county_id = p_county_id and p.lat is not null
      order by p.name
      limit 30
    ) s
  )
  select jsonb_build_object(
    'state', (select state from visit),
    'earned_at', (select confirmed_at from visit),
    'pass_count', (select pass_count from visit),
    'last_pass_at', (select at from last_pass),
    'last_pass_stay_seconds', (select stay from last_pass),
    'explored_visits', (select visits from explored),
    'explored_months', (select months from explored),
    'last_explored_at', (select last_at from explored),
    'last_visited_at', (select at from last_visit),
    'journeys', (select count from journeys),
    'journey_distance_m', (select distance from journeys),
    'saved_places', (select saved from saved),
    'saved_visited', (select visited from saved),
    'places_total', (select total from county_places),
    'places_visited', (select visited from saved),
    'suggested_places', (select list from suggestions)
  );
$$;

revoke execute on function public.county_badge_detail(smallint) from public;
grant execute on function public.county_badge_detail(smallint) to authenticated;
