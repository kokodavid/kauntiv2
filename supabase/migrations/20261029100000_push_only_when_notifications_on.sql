-- Push goes only to phones that have notifications turned on.
--
-- Until now a phone counted as reachable unless it had refused ("denied"),
-- so phones that were never asked ("unknown") were counted in audience
-- estimates and sent to, though the phone would show nothing. Reachable now
-- means the phone reported "granted". A phone re-reports on every app open,
-- so people who allow notifications later start receiving them on their
-- own. Only the permission test changes in the functions below.

create or replace function public.push_audience_internal(
  p_filters jsonb,
  p_requester uuid default null
)
returns table (
  user_id uuid,
  opted_in boolean,
  has_push boolean,
  recently_broadcast boolean,
  email text,
  first_name text
)
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_scope text := coalesce(p_filters ->> 'scope', 'everyone');
  v_counties smallint[];
  v_interests text[];
  v_min_claimed int := nullif(p_filters ->> 'min_claimed', '')::int;
  v_max_claimed int := nullif(p_filters ->> 'max_claimed', '')::int;
  v_platform text := nullif(p_filters ->> 'platform', '');
  v_min_ver int[] := public.push_version_key(p_filters ->> 'min_app_version');
  v_max_ver int[] := public.push_version_key(p_filters ->> 'max_app_version');
  v_active int := nullif(p_filters ->> 'active_within_days', '')::int;
  v_inactive int := nullif(p_filters ->> 'inactive_for_days', '')::int;
  v_device_filter boolean;
begin
  if p_filters ? 'home_county_ids' then
    select array_agg(x::smallint) into v_counties
    from jsonb_array_elements_text(p_filters -> 'home_county_ids') x;
  end if;
  if p_filters ? 'interests' then
    select array_agg(x) into v_interests
    from jsonb_array_elements_text(p_filters -> 'interests') x;
  end if;
  v_device_filter := v_platform is not null or v_min_ver is not null or v_max_ver is not null;

  return query
  select p.id,
         p.notify_announcements,
         exists (select 1 from public.push_devices d
                 where d.user_id = p.id and d.os_permission = 'granted'),
         exists (select 1 from public.push_events e
                 where e.user_id = p.id and e.kind = 'announcement'
                   and e.status in ('queued', 'sending', 'sent')
                   and e.created_at > now() - interval '7 days'),
         u.email::text,
         (select nullif(split_part(btrim(coalesce(w.display_name, '')), ' ', 1), '')
          from public.waitlist_signups w where w.user_id = p.id limit 1)
  from public.profiles p
  join auth.users u on u.id = p.id
  where u.deleted_at is null
    and (u.banned_until is null or u.banned_until < now())
    and (v_scope <> 'me' or p.id = p_requester)
    and (v_scope <> 'testers' or exists (
          select 1 from public.waitlist_signups s
          where s.user_id = p.id and s.status = 'approved'))
    and (v_counties is null or p.home_county_id = any (v_counties))
    and (v_interests is null or p.interests && v_interests)
    and (v_min_claimed is null or (
          select count(distinct c.county_id) from public.county_visits c
          where c.user_id = p.id and c.state = 'explored') >= v_min_claimed)
    and (v_max_claimed is null or (
          select count(distinct c.county_id) from public.county_visits c
          where c.user_id = p.id and c.state = 'explored') <= v_max_claimed)
    and (not v_device_filter or exists (
          select 1 from public.push_devices d
          where d.user_id = p.id
            and (v_platform is null or d.platform = v_platform)
            and (v_min_ver is null or public.push_version_key(d.app_version) >= v_min_ver)
            and (v_max_ver is null or public.push_version_key(d.app_version) <= v_max_ver)))
    and (v_active is null or exists (
          select 1 from public.push_devices d
          where d.user_id = p.id and d.last_seen_at >= now() - make_interval(days => v_active)))
    and (v_inactive is null or not exists (
          select 1 from public.push_devices d
          where d.user_id = p.id and d.last_seen_at >= now() - make_interval(days => v_inactive)));
end;
$$;

create or replace function public.send_test_push_dashboard(p_id uuid)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_c public.push_campaigns;
  v_count integer;
begin
  perform public.push_require_draft_role();
  select * into v_c from public.push_campaigns where id = p_id for update;
  if not found then raise exception 'Campaign not found' using errcode = 'P0002'; end if;
  if v_c.status in ('sending', 'sent', 'cancelled') then
    raise exception 'This campaign can no longer be tested' using errcode = '55000';
  end if;
  if not exists (select 1 from public.push_devices
                 where user_id = auth.uid() and os_permission = 'granted') then
    raise exception 'Open the app on your phone and allow notifications first'
      using errcode = '55000';
  end if;

  insert into public.push_events (user_id, kind, delivery, payload, campaign_id, dedupe_key)
  values (auth.uid(), 'test', 'push',
    jsonb_build_object('title', v_c.title, 'body', v_c.body,
      'dest_kind', v_c.dest_kind, 'dest_id', v_c.dest_id),
    v_c.id, 'test:' || v_c.id || ':' || gen_random_uuid());
  get diagnostics v_count = row_count;

  update public.push_campaigns
  set test_sent_hash = content_hash, updated_at = now()
  where id = p_id;
  return v_count;
end;
$$;

create or replace function public.push_fallback_to_email(p_event_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  e public.push_events;
  v_email text;
  v_campaign_email boolean := true;
begin
  select * into e from public.push_events where id = p_event_id;
  if not found or e.delivery <> 'push' or e.kind not in ('announcement', 'photo_review', 'trip_review') then
    return false;
  end if;
  if exists (select 1 from public.push_devices
             where user_id = e.user_id and os_permission = 'granted') then
    return false; -- another live device may still receive it
  end if;
  if e.campaign_id is not null then
    select include_email into v_campaign_email from public.push_campaigns where id = e.campaign_id;
  end if;
  if not coalesce(v_campaign_email, true) then return false; end if;
  -- One fallback email a week for announcements.
  if e.kind = 'announcement' and exists (
       select 1 from public.push_events x
       where x.user_id = e.user_id and x.kind = 'announcement' and x.delivery = 'email'
         and x.status in ('queued', 'sending', 'sent') and x.created_at > now() - interval '7 days') then
    return false;
  end if;
  select u.email::text into v_email from auth.users u where u.id = e.user_id;
  if v_email is null then return false; end if;

  insert into public.push_events (user_id, kind, delivery, payload, campaign_id, dedupe_key, send_after)
  values (e.user_id, e.kind, 'email', e.payload, e.campaign_id,
          'email:' || coalesce(e.dedupe_key, e.id::text), public.push_next_send_time(now()))
  on conflict (dedupe_key) do nothing;
  return found;
end;
$$;

create or replace function public.claim_push_events(p_limit integer default 50)
returns table (
  event_id uuid, user_id uuid, kind text, delivery text, title text, body text,
  dest_kind text, dest_id text, tokens text[], email text, first_name text
)
language plpgsql
security definer
set search_path = public
as $$
declare
  r public.push_events;
  v_ids uuid[] := '{}';
  v_flag boolean;
  v_delivery boolean;
  v_today int;
  v_week int;
  v_exempt boolean;
  v_has_tokens boolean;
begin
  perform public.push_require_service();
  v_flag := coalesce((select enabled from public.app_feature_flags
                      where feature_key = 'push_broadcasts'), false);
  v_delivery := coalesce((select delivery_enabled from public.beta_tester_invite_settings limit 1), false);

  for r in
    select * from public.push_events e
    where e.attempts < 5 and e.send_after <= now()
      and (e.status = 'queued' or (e.status = 'sending' and e.claimed_at < now() - interval '10 minutes'))
    order by e.send_after
    limit greatest(1, least(p_limit, 100)) * 3
    for update skip locked
  loop
    exit when coalesce(array_length(v_ids, 1), 0) >= least(p_limit, 100);
    if r.kind = 'announcement' and not v_flag then continue; end if; -- stays queued
    if r.delivery = 'email' and not v_delivery then continue; end if;

    if r.kind <> 'test' and not coalesce(
         (select s.enabled from public.push_kind_settings s where s.kind = r.kind), true) then
      update public.push_events set status = 'skipped', status_reason = 'paused' where id = r.id;
      continue;
    end if;
    if r.kind <> 'test' and not coalesce(public.push_profile_switch(r.user_id, r.kind), true) then
      update public.push_events set status = 'skipped', status_reason = 'opted_out' where id = r.id;
      continue;
    end if;

    if r.kind <> 'test' and r.delivery = 'push' then
      v_exempt := r.kind in ('photo_review', 'trip_review');
      select count(*) filter (where (e.sent_at at time zone 'Africa/Nairobi')::date
                                    = (now() at time zone 'Africa/Nairobi')::date),
             count(*)
      into v_today, v_week
      from public.push_events e
      where e.user_id = r.user_id and e.delivery = 'push' and e.status = 'sent'
        and e.kind <> 'test' and e.sent_at > now() - interval '7 days';
      if (v_exempt and v_today >= 3) or (not v_exempt and (v_today >= 1 or v_week >= 3)) then
        update public.push_events set status = 'skipped', status_reason = 'cap' where id = r.id;
        continue;
      end if;
    end if;

    if r.delivery = 'push' then
      select exists (select 1 from public.push_devices d
                     where d.user_id = r.user_id and d.os_permission = 'granted') into v_has_tokens;
      if not v_has_tokens then
        update public.push_events set status = 'skipped', status_reason = 'no_device' where id = r.id;
        perform public.push_fallback_to_email(r.id);
        continue;
      end if;
    end if;

    update public.push_events
    set status = 'sending', claimed_at = now(), attempts = attempts + 1
    where id = r.id;
    v_ids := v_ids || r.id;
  end loop;

  return query
  select e.id, e.user_id, e.kind, e.delivery,
         e.payload ->> 'title', e.payload ->> 'body',
         e.payload ->> 'dest_kind', e.payload ->> 'dest_id',
         case when e.delivery = 'push' then
           array(select d.token from public.push_devices d
                 where d.user_id = e.user_id and d.os_permission = 'granted')
         else '{}'::text[] end,
         case when e.delivery = 'email' then u.email::text end,
         (select nullif(split_part(btrim(coalesce(w.display_name, '')), ' ', 1), '')
          from public.waitlist_signups w where w.user_id = e.user_id limit 1)
  from public.push_events e
  join auth.users u on u.id = e.user_id
  where e.id = any (v_ids);
end;
$$;

create or replace function public.queue_photo_review_push()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_place text;
  v_has_device boolean;
  v_email text;
  v_title text;
  v_body text;
  v_pending_id uuid;
  v_pending_count int;
begin
  if new.status = old.status or new.status not in ('approved', 'rejected') then
    return new;
  end if;
  select p.name into v_place from public.places p where p.id = new.place_id;
  v_place := coalesce(v_place, 'a place');
  if new.status = 'approved' then
    v_title := 'Your photo is live';
    v_body := 'Your photo of ' || v_place || ' is now on Kaunti47.';
  else
    v_title := 'Your photo was reviewed';
    v_body := 'We''ve looked at your photo of ' || v_place || '. See the result.';
  end if;

  select exists (select 1 from public.push_devices
                 where user_id = new.user_id and os_permission = 'granted') into v_has_device;
  select u.email::text into v_email from auth.users u where u.id = new.user_id;
  if not v_has_device and v_email is null then return new; end if;

  -- Merge several reviews inside the same wait into one message.
  select e.id, coalesce((e.payload ->> 'count')::int, 1)
  into v_pending_id, v_pending_count
  from public.push_events e
  where e.user_id = new.user_id and e.kind = 'photo_review'
    and e.status = 'queued' and e.delivery = case when v_has_device then 'push' else 'email' end
    and e.created_at > now() - interval '1 hour'
  order by e.created_at desc limit 1;

  if v_pending_id is not null then
    update public.push_events
    set payload = jsonb_build_object(
      'title', 'Your photos were reviewed',
      'body', (v_pending_count + 1) || ' of your photos were reviewed. See the results.',
      'dest_kind', 'my_photos', 'count', v_pending_count + 1)
    where id = v_pending_id;
    return new;
  end if;

  insert into public.push_events (user_id, kind, delivery, payload, dedupe_key, send_after)
  values (new.user_id, 'photo_review',
    case when v_has_device then 'push' else 'email' end,
    jsonb_build_object('title', v_title, 'body', v_body, 'dest_kind', 'my_photos', 'count', 1),
    'photo:' || new.id, public.push_next_send_time(now()))
  on conflict (dedupe_key) do nothing;
  return new;
end;
$$;

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
                  where d.user_id = p.id and d.os_permission = 'granted')
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
