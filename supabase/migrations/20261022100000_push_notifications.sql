-- Push notifications: devices, queue, broadcast campaigns with approval,
-- audience filtering, email fallback, and the first automatic push
-- (place photo reviewed). See claude/notifications-plan.md.
--
-- Everything here is reached only through security definer functions:
-- the tables are closed to anon and authenticated.

-- ---------------------------------------------------------------- settings
alter table public.profiles
  add column if not exists notify_announcements boolean not null default true,
  add column if not exists notify_photo_reviews boolean not null default true,
  add column if not exists notify_trip_reviews boolean not null default true,
  add column if not exists notify_weekend_plans boolean not null default false;

alter table public.app_feature_flags
  drop constraint if exists app_feature_flags_feature_key_check;
alter table public.app_feature_flags add constraint app_feature_flags_feature_key_check
  check (feature_key in (
    'county_news', 'public_trips_read', 'public_trips_publish',
    'place_photos', 'push_broadcasts'
  ));
insert into public.app_feature_flags (feature_key, enabled)
values ('push_broadcasts', false)
on conflict (feature_key) do nothing;

-- ------------------------------------------------------------------ tables
create table if not exists public.push_devices (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  token text not null unique check (char_length(token) between 20 and 4096),
  platform text not null check (platform in ('android', 'ios')),
  flavor text not null default 'prod' check (flavor in ('dev', 'prod')),
  app_version text,
  os_permission text not null default 'unknown'
    check (os_permission in ('granted', 'denied', 'unknown')),
  last_seen_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);
create index if not exists push_devices_user_idx on public.push_devices (user_id);

create table if not exists public.push_campaigns (
  id uuid primary key default gen_random_uuid(),
  title text not null check (char_length(title) between 1 and 50),
  body text not null check (char_length(body) between 1 and 140),
  dest_kind text not null default 'home'
    check (dest_kind in ('home', 'explore', 'county', 'place', 'badges', 'my_photos', 'profile')),
  dest_id text,
  filters jsonb not null default '{"scope":"everyone"}'::jsonb,
  include_email boolean not null default true,
  scheduled_at timestamptz,
  status text not null default 'draft'
    check (status in ('draft', 'pending_approval', 'approved', 'scheduled',
                      'sending', 'sent', 'rejected', 'cancelled')),
  content_hash text not null default '',
  test_sent_hash text,
  counts jsonb not null default '{}'::jsonb,
  created_by uuid not null references auth.users (id) on delete restrict,
  submitted_by uuid references auth.users (id) on delete set null,
  submitted_at timestamptz,
  approved_by uuid references auth.users (id) on delete set null,
  approved_at timestamptz,
  rejection_note text,
  started_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists push_campaigns_status_idx
  on public.push_campaigns (status, scheduled_at);

create table if not exists public.push_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  kind text not null
    check (kind in ('announcement', 'photo_review', 'trip_review', 'weekend_plan', 'test')),
  delivery text not null default 'push' check (delivery in ('push', 'email')),
  payload jsonb not null default '{}'::jsonb,
  campaign_id uuid references public.push_campaigns (id) on delete set null,
  dedupe_key text unique,
  status text not null default 'queued'
    check (status in ('queued', 'sending', 'sent', 'failed', 'skipped')),
  status_reason text,
  attempts smallint not null default 0,
  send_after timestamptz not null default now(),
  claimed_at timestamptz,
  sent_at timestamptz,
  opened_at timestamptz,
  provider_message_id text,
  created_at timestamptz not null default now()
);
create index if not exists push_events_due_idx
  on public.push_events (send_after) where status in ('queued', 'sending');
create index if not exists push_events_user_idx
  on public.push_events (user_id, kind, created_at desc);
create index if not exists push_events_campaign_idx on public.push_events (campaign_id);

create table if not exists public.push_kind_settings (
  kind text primary key
    check (kind in ('announcement', 'photo_review', 'trip_review', 'weekend_plan')),
  enabled boolean not null default true,
  updated_at timestamptz not null default now(),
  updated_by uuid references auth.users (id) on delete set null
);
insert into public.push_kind_settings (kind)
values ('announcement'), ('photo_review'), ('trip_review'), ('weekend_plan')
on conflict (kind) do nothing;

alter table public.push_devices enable row level security;
alter table public.push_campaigns enable row level security;
alter table public.push_events enable row level security;
alter table public.push_kind_settings enable row level security;
revoke all on public.push_devices, public.push_campaigns,
  public.push_events, public.push_kind_settings from public, anon, authenticated;

-- ----------------------------------------------------------------- helpers
create or replace function public.push_require_service()
returns void
language plpgsql
as $$
begin
  -- Cron runs with no JWT (null role); PostgREST always sets one.
  if auth.role() is not null and auth.role() <> 'service_role' then
    raise exception 'Service role required' using errcode = '42501';
  end if;
end;
$$;

create or replace function public.push_require_draft_role()
returns text
language plpgsql
stable
security definer
set search_path = public
as $$
declare v_role text := public.current_admin_role()::text;
begin
  if v_role is null or v_role not in ('owner', 'admin', 'editor', 'moderator') then
    raise exception 'Dashboard access required' using errcode = '42501';
  end if;
  return v_role;
end;
$$;

create or replace function public.push_require_sender_role()
returns void
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if coalesce(public.current_admin_role()::text in ('owner', 'admin'), false) is not true then
    raise exception 'Owner or admin access required' using errcode = '42501';
  end if;
end;
$$;

-- Quiet hours 21:00-07:00 East Africa Time: move to 07:00.
create or replace function public.push_next_send_time(p_at timestamptz default now())
returns timestamptz
language sql
immutable
as $$
  select case
    when extract(hour from p_at at time zone 'Africa/Nairobi') >= 21 then
      ((date_trunc('day', p_at at time zone 'Africa/Nairobi') + interval '1 day 7 hours')
        at time zone 'Africa/Nairobi')
    when extract(hour from p_at at time zone 'Africa/Nairobi') < 7 then
      ((date_trunc('day', p_at at time zone 'Africa/Nairobi') + interval '7 hours')
        at time zone 'Africa/Nairobi')
    else p_at
  end;
$$;

create or replace function public.push_version_key(p_version text)
returns int[]
language sql
immutable
as $$
  select string_to_array(
    nullif(regexp_replace(split_part(coalesce(p_version, ''), '+', 1), '[^0-9.]', '', 'g'), ''),
    '.')::int[];
$$;

create or replace function public.push_profile_switch(p_user uuid, p_kind text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select case p_kind
    when 'announcement' then p.notify_announcements
    when 'photo_review' then p.notify_photo_reviews
    when 'trip_review' then p.notify_trip_reviews
    when 'weekend_plan' then p.notify_weekend_plans
    else true
  end
  from public.profiles p where p.id = p_user;
$$;

create or replace function public.push_campaign_hash(
  p_title text, p_body text, p_dest_kind text, p_dest_id text,
  p_filters jsonb, p_include_email boolean, p_scheduled_at timestamptz
)
returns text
language sql
immutable
as $$
  select md5(concat_ws('|', p_title, p_body, p_dest_kind, coalesce(p_dest_id, ''),
    p_filters::text, p_include_email::text, coalesce(p_scheduled_at::text, '')));
$$;

-- ---------------------------------------------------------------- audience
-- One function drives both the count shown in the console and the real send,
-- so they cannot drift. Never exposed to clients.
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
                 where d.user_id = p.id and d.os_permission <> 'denied'),
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
revoke all on function public.push_audience_internal(jsonb, uuid) from public, anon, authenticated;

create or replace function public.estimate_push_audience_dashboard(
  p_filters jsonb,
  p_include_email boolean default true
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_scope text := coalesce(p_filters ->> 'scope', 'everyone');
  r record;
begin
  perform public.push_require_draft_role();
  select count(*) as matched,
         count(*) filter (where not a.opted_in) as opted_out,
         count(*) filter (where a.opted_in and a.recently_broadcast and v_scope <> 'me') as capped,
         count(*) filter (where a.opted_in and (v_scope = 'me' or not a.recently_broadcast)
                            and a.has_push) as push,
         count(*) filter (where a.opted_in and (v_scope = 'me' or not a.recently_broadcast)
                            and not a.has_push and p_include_email and a.email is not null) as email_only
  into r
  from public.push_audience_internal(p_filters, auth.uid()) a;

  -- Narrow filters could identify a person, so small audiences are hidden.
  if r.matched < 5 and v_scope <> 'me' then
    return jsonb_build_object('hidden', true, 'message', 'Fewer than 5 people match.');
  end if;
  return jsonb_build_object(
    'hidden', false,
    'matched', r.matched,
    'opted_out', r.opted_out,
    'capped', r.capped,
    'push', r.push,
    'email_only', r.email_only,
    'unreachable', r.matched - r.opted_out - r.capped - r.push - r.email_only
  );
end;
$$;

-- --------------------------------------------------------- app: devices
create or replace function public.register_push_device(
  p_token text,
  p_platform text,
  p_flavor text default 'prod',
  p_app_version text default null,
  p_os_permission text default 'unknown'
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Sign in required' using errcode = '42501';
  end if;
  insert into public.push_devices (user_id, token, platform, flavor, app_version, os_permission, last_seen_at)
  values (auth.uid(), p_token, p_platform, coalesce(p_flavor, 'prod'),
          left(p_app_version, 40), coalesce(p_os_permission, 'unknown'), now())
  on conflict (token) do update
    set user_id = auth.uid(),
        platform = excluded.platform,
        flavor = excluded.flavor,
        app_version = excluded.app_version,
        os_permission = excluded.os_permission,
        last_seen_at = now();
end;
$$;

create or replace function public.remove_push_device(p_token text)
returns void
language sql
security definer
set search_path = public
as $$
  delete from public.push_devices where token = p_token and user_id = auth.uid();
$$;

create or replace function public.log_push_open(p_event_id uuid)
returns void
language sql
security definer
set search_path = public
as $$
  update public.push_events
  set opened_at = coalesce(opened_at, now())
  where id = p_event_id and user_id = auth.uid();
$$;

-- -------------------------------------------------- dashboard: campaigns
create or replace function public.save_push_campaign_dashboard(
  p_id uuid,
  p_title text,
  p_body text,
  p_dest_kind text,
  p_dest_id text,
  p_filters jsonb,
  p_include_email boolean,
  p_scheduled_at timestamptz default null
)
returns public.push_campaigns
language plpgsql
security definer
set search_path = public
as $$
declare
  v_role text := public.push_require_draft_role();
  v_row public.push_campaigns;
  v_title text := btrim(coalesce(p_title, ''));
  v_body text := btrim(coalesce(p_body, ''));
  v_dest_id text := nullif(btrim(coalesce(p_dest_id, '')), '');
  v_filters jsonb := coalesce(p_filters, '{"scope":"everyone"}'::jsonb);
  v_hash text;
begin
  if char_length(v_title) not between 1 and 50 then
    raise exception 'Title must be 1 to 50 characters' using errcode = '22023';
  end if;
  if char_length(v_body) not between 1 and 140 then
    raise exception 'Message must be 1 to 140 characters' using errcode = '22023';
  end if;
  if p_dest_kind not in ('home', 'explore', 'county', 'place', 'badges', 'my_photos', 'profile') then
    raise exception 'Unknown destination' using errcode = '22023';
  end if;
  if p_dest_kind in ('county', 'place') and v_dest_id is null then
    raise exception 'Choose a county or place' using errcode = '22023';
  end if;
  if p_dest_kind not in ('county', 'place') then v_dest_id := null; end if;
  if coalesce(v_filters ->> 'scope', 'everyone') not in ('everyone', 'testers', 'me') then
    raise exception 'Unknown audience' using errcode = '22023';
  end if;

  v_hash := public.push_campaign_hash(v_title, v_body, p_dest_kind, v_dest_id,
    v_filters, coalesce(p_include_email, true), p_scheduled_at);

  if p_id is null then
    insert into public.push_campaigns (title, body, dest_kind, dest_id, filters,
      include_email, scheduled_at, content_hash, created_by)
    values (v_title, v_body, p_dest_kind, v_dest_id, v_filters,
      coalesce(p_include_email, true), p_scheduled_at, v_hash, auth.uid())
    returning * into v_row;
    return v_row;
  end if;

  select * into v_row from public.push_campaigns where id = p_id for update;
  if not found then
    raise exception 'Campaign not found' using errcode = 'P0002';
  end if;
  if v_row.status in ('sending', 'sent', 'cancelled') then
    raise exception 'This campaign can no longer be edited' using errcode = '55000';
  end if;
  if v_role not in ('owner', 'admin') and v_row.created_by <> auth.uid() then
    raise exception 'Only the author or an admin can edit this' using errcode = '42501';
  end if;

  update public.push_campaigns
  set title = v_title, body = v_body, dest_kind = p_dest_kind, dest_id = v_dest_id,
      filters = v_filters, include_email = coalesce(p_include_email, true),
      scheduled_at = p_scheduled_at, content_hash = v_hash,
      -- Any change after submission or approval clears the approval.
      status = case when v_hash <> v_row.content_hash then 'draft' else v_row.status end,
      approved_by = case when v_hash <> v_row.content_hash then null else v_row.approved_by end,
      approved_at = case when v_hash <> v_row.content_hash then null else v_row.approved_at end,
      submitted_by = case when v_hash <> v_row.content_hash then null else v_row.submitted_by end,
      submitted_at = case when v_hash <> v_row.content_hash then null else v_row.submitted_at end,
      rejection_note = case when v_hash <> v_row.content_hash then null else v_row.rejection_note end,
      updated_at = now()
  where id = p_id
  returning * into v_row;
  return v_row;
end;
$$;

-- Queues the real message to the caller's own devices (always bypasses
-- opt-out, caps and quiet hours) and records that this exact content was tested.
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
                 where user_id = auth.uid() and os_permission <> 'denied') then
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

create or replace function public.submit_push_campaign_dashboard(p_id uuid)
returns public.push_campaigns
language plpgsql
security definer
set search_path = public
as $$
declare v_c public.push_campaigns;
begin
  perform public.push_require_draft_role();
  select * into v_c from public.push_campaigns where id = p_id for update;
  if not found then raise exception 'Campaign not found' using errcode = 'P0002'; end if;
  if v_c.status <> 'draft' then
    raise exception 'Only a draft can be submitted' using errcode = '55000';
  end if;
  if v_c.created_by <> auth.uid() and coalesce(public.current_admin_role()::text in ('owner', 'admin'), false) is not true then
    raise exception 'Only the author can submit this' using errcode = '42501';
  end if;
  if v_c.test_sent_hash is distinct from v_c.content_hash then
    raise exception 'Send a test to your own phone first' using errcode = '55000';
  end if;
  update public.push_campaigns
  set status = 'pending_approval', submitted_by = auth.uid(), submitted_at = now(),
      rejection_note = null, updated_at = now()
  where id = p_id returning * into v_c;
  return v_c;
end;
$$;

create or replace function public.approve_push_campaign_dashboard(p_id uuid)
returns public.push_campaigns
language plpgsql
security definer
set search_path = public
as $$
declare v_c public.push_campaigns;
begin
  perform public.push_require_sender_role();
  select * into v_c from public.push_campaigns where id = p_id for update;
  if not found then raise exception 'Campaign not found' using errcode = 'P0002'; end if;
  if v_c.status <> 'pending_approval' then
    raise exception 'Nothing to approve' using errcode = '55000';
  end if;
  update public.push_campaigns
  set status = 'approved', approved_by = auth.uid(), approved_at = now(), updated_at = now()
  where id = p_id returning * into v_c;
  return v_c;
end;
$$;

create or replace function public.reject_push_campaign_dashboard(p_id uuid, p_note text)
returns public.push_campaigns
language plpgsql
security definer
set search_path = public
as $$
declare v_c public.push_campaigns;
begin
  perform public.push_require_sender_role();
  if btrim(coalesce(p_note, '')) = '' then
    raise exception 'Add a short note for the author' using errcode = '22004';
  end if;
  select * into v_c from public.push_campaigns where id = p_id for update;
  if not found then raise exception 'Campaign not found' using errcode = 'P0002'; end if;
  if v_c.status <> 'pending_approval' then
    raise exception 'Nothing to reject' using errcode = '55000';
  end if;
  update public.push_campaigns
  set status = 'draft', rejection_note = left(btrim(p_note), 300),
      submitted_by = null, submitted_at = null, updated_at = now()
  where id = p_id returning * into v_c;
  return v_c;
end;
$$;

-- Owners and admins only. Allowed from a tested draft or an approved campaign.
create or replace function public.schedule_push_campaign_dashboard(
  p_id uuid,
  p_when timestamptz default null
)
returns public.push_campaigns
language plpgsql
security definer
set search_path = public
as $$
declare v_c public.push_campaigns;
begin
  perform public.push_require_sender_role();
  select * into v_c from public.push_campaigns where id = p_id for update;
  if not found then raise exception 'Campaign not found' using errcode = 'P0002'; end if;
  if v_c.status not in ('draft', 'approved') then
    raise exception 'This campaign cannot be scheduled from its current state' using errcode = '55000';
  end if;
  if v_c.test_sent_hash is distinct from v_c.content_hash then
    raise exception 'Send a test to your own phone first' using errcode = '55000';
  end if;
  if not coalesce((select enabled from public.app_feature_flags
                   where feature_key = 'push_broadcasts'), false) then
    raise exception 'Broadcasts are switched off' using errcode = '55000';
  end if;
  update public.push_campaigns
  set status = 'scheduled',
      scheduled_at = greatest(coalesce(p_when, now()), now() - interval '1 minute'),
      approved_by = coalesce(approved_by, auth.uid()),
      approved_at = coalesce(approved_at, now()),
      updated_at = now()
  where id = p_id returning * into v_c;
  return v_c;
end;
$$;

create or replace function public.cancel_push_campaign_dashboard(p_id uuid)
returns public.push_campaigns
language plpgsql
security definer
set search_path = public
as $$
declare
  v_role text := public.push_require_draft_role();
  v_c public.push_campaigns;
begin
  select * into v_c from public.push_campaigns where id = p_id for update;
  if not found then raise exception 'Campaign not found' using errcode = 'P0002'; end if;
  if v_c.status not in ('draft', 'pending_approval', 'approved', 'scheduled', 'rejected') then
    raise exception 'This campaign has already started' using errcode = '55000';
  end if;
  if v_role not in ('owner', 'admin') and v_c.created_by <> auth.uid() then
    raise exception 'Only the author or an admin can cancel this' using errcode = '42501';
  end if;
  update public.push_campaigns
  set status = 'cancelled', updated_at = now()
  where id = p_id returning * into v_c;
  return v_c;
end;
$$;

create or replace function public.list_push_campaigns_dashboard(p_status text default null)
returns table (
  id uuid, title text, body text, dest_kind text, dest_id text, filters jsonb,
  include_email boolean, scheduled_at timestamptz, status text, test_sent boolean,
  counts jsonb, created_by uuid, created_by_label text, submitted_at timestamptz,
  approved_at timestamptz, rejection_note text, created_at timestamptz
)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  perform public.push_require_draft_role();
  if public.current_admin_role() is null then return; end if;
  return query
  select c.id, c.title, c.body, c.dest_kind, c.dest_id, c.filters, c.include_email,
         c.scheduled_at, c.status, (c.test_sent_hash = c.content_hash), c.counts,
         c.created_by, coalesce(split_part(u.email::text, '@', 1), 'unknown'),
         c.submitted_at, c.approved_at, c.rejection_note, c.created_at
  from public.push_campaigns c
  left join auth.users u on u.id = c.created_by
  where p_status is null or c.status = p_status
  order by c.created_at desc
  limit 200;
end;
$$;

create or replace function public.pending_push_approval_count_dashboard()
returns integer
language sql
stable
security definer
set search_path = public
as $$
  select case when public.current_admin_role()::text in ('owner', 'admin')
    then (select count(*)::int from public.push_campaigns where status = 'pending_approval')
    else 0 end;
$$;

create or replace function public.get_push_campaign_stats_dashboard(p_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  perform public.push_require_draft_role();
  return (
    select jsonb_build_object(
      'queued', count(*) filter (where status in ('queued', 'sending')),
      'push_sent', count(*) filter (where delivery = 'push' and status = 'sent'),
      'email_sent', count(*) filter (where delivery = 'email' and status = 'sent'),
      'failed', count(*) filter (where status = 'failed'),
      'skipped', count(*) filter (where status = 'skipped'),
      'opened', count(*) filter (where opened_at is not null),
      'skipped_reasons', coalesce((
        select jsonb_object_agg(reason, n) from (
          select coalesce(status_reason, 'unknown') as reason, count(*) as n
          from public.push_events
          where campaign_id = p_id and status = 'skipped' group by 1) s), '{}'::jsonb)
    )
    from public.push_events where campaign_id = p_id and kind <> 'test'
  );
end;
$$;

-- ----------------------------------- dashboard: kinds, flag, device health
create or replace function public.list_push_kinds_dashboard()
returns table (kind text, enabled boolean, sent_7d bigint, opened_7d bigint, failed_7d bigint)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  perform public.push_require_draft_role();
  return query
  select k.kind, k.enabled,
    count(e.*) filter (where e.status = 'sent'),
    count(e.*) filter (where e.opened_at is not null),
    count(e.*) filter (where e.status = 'failed')
  from public.push_kind_settings k
  left join public.push_events e
    on e.kind = k.kind and e.created_at > now() - interval '7 days'
  group by k.kind, k.enabled
  order by k.kind;
end;
$$;

create or replace function public.set_push_kind_enabled_dashboard(p_kind text, p_enabled boolean)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.push_require_sender_role();
  update public.push_kind_settings
  set enabled = p_enabled, updated_at = now(), updated_by = auth.uid()
  where kind = p_kind;
  if not found then raise exception 'Unknown kind' using errcode = '22023'; end if;
  return p_enabled;
end;
$$;

create or replace function public.set_push_broadcasts_enabled_dashboard(p_enabled boolean)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.push_require_sender_role();
  if p_enabled is null then raise exception 'Enabled value is required' using errcode = '22004'; end if;
  insert into public.app_feature_flags (feature_key, enabled, updated_at, updated_by)
  values ('push_broadcasts', p_enabled, now(), auth.uid())
  on conflict (feature_key) do update
    set enabled = excluded.enabled, updated_at = excluded.updated_at, updated_by = excluded.updated_by;
  return p_enabled;
end;
$$;

create or replace function public.push_device_health_dashboard()
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  perform public.push_require_draft_role();
  return jsonb_build_object(
    'devices', (select count(*) from public.push_devices),
    'denied', (select count(*) from public.push_devices where os_permission = 'denied'),
    'by_platform', coalesce((select jsonb_object_agg(platform, n) from (
      select platform, count(*) n from public.push_devices group by 1) s), '{}'::jsonb),
    'by_version', coalesce((select jsonb_object_agg(v, n) from (
      select coalesce(app_version, 'unknown') v, count(*) n from public.push_devices group by 1) s), '{}'::jsonb),
    'failed_7d', (select count(*) from public.push_events
                  where status = 'failed' and created_at > now() - interval '7 days'),
    'email_fallback_7d', (select count(*) from public.push_events
                  where delivery = 'email' and status = 'sent' and created_at > now() - interval '7 days')
  );
end;
$$;

-- ------------------------------------------------- enqueue (service/cron)
create or replace function public.enqueue_push_campaign(p_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_c public.push_campaigns;
  v_scope text;
  v_push int := 0;
  v_email int := 0;
  v_out int := 0;
  v_cap int := 0;
  v_none int := 0;
  v_counts jsonb;
begin
  perform public.push_require_service();
  select * into v_c from public.push_campaigns where id = p_id for update;
  if not found or v_c.status <> 'scheduled' then
    return jsonb_build_object('skipped', true);
  end if;
  v_scope := coalesce(v_c.filters ->> 'scope', 'everyone');

  update public.push_campaigns set status = 'sending', started_at = now() where id = p_id;

  -- Counted before inserting, so this send does not count as "already
  -- had a broadcast this week".
  select count(*) filter (where not a.opted_in),
         count(*) filter (where a.opted_in and a.recently_broadcast and v_scope <> 'me'),
         count(*) filter (where a.opted_in and (v_scope = 'me' or not a.recently_broadcast)
                            and not a.has_push and not (v_c.include_email and a.email is not null))
  into v_out, v_cap, v_none
  from public.push_audience_internal(v_c.filters, v_c.created_by) a;

  with a as (select * from public.push_audience_internal(v_c.filters, v_c.created_by)),
  ins as (
    insert into public.push_events (user_id, kind, delivery, payload, campaign_id, dedupe_key, send_after)
    select a.user_id, 'announcement',
           case when a.has_push then 'push' else 'email' end,
           jsonb_build_object('title', v_c.title, 'body', v_c.body,
             'dest_kind', v_c.dest_kind, 'dest_id', v_c.dest_id),
           v_c.id, v_c.id || ':' || a.user_id,
           public.push_next_send_time(now())
    from a
    where a.opted_in
      and (v_scope = 'me' or not a.recently_broadcast)
      and (a.has_push or (v_c.include_email and a.email is not null))
    on conflict (dedupe_key) do nothing
    returning delivery
  )
  select count(*) filter (where delivery = 'push'),
         count(*) filter (where delivery = 'email')
  into v_push, v_email from ins;

  v_counts := jsonb_build_object('push', v_push, 'email', v_email,
    'opted_out', v_out, 'capped', v_cap, 'unreachable', v_none);
  update public.push_campaigns
  set status = 'sent', counts = v_counts, updated_at = now() where id = p_id;
  return v_counts;
end;
$$;

create or replace function public.run_due_push_campaigns()
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare r record; n int := 0;
begin
  perform public.push_require_service();
  if not coalesce((select enabled from public.app_feature_flags
                   where feature_key = 'push_broadcasts'), false) then
    return 0;
  end if;
  for r in select id from public.push_campaigns
           where status = 'scheduled' and scheduled_at <= now()
           order by scheduled_at limit 5
  loop
    perform public.enqueue_push_campaign(r.id);
    n := n + 1;
  end loop;
  return n;
end;
$$;

-- --------------------------------------------------- worker (service role)
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
             where user_id = e.user_id and os_permission <> 'denied') then
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
                     where d.user_id = r.user_id and d.os_permission <> 'denied') into v_has_tokens;
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
                 where d.user_id = e.user_id and d.os_permission <> 'denied')
         else '{}'::text[] end,
         case when e.delivery = 'email' then u.email::text end,
         (select nullif(split_part(btrim(coalesce(w.display_name, '')), ' ', 1), '')
          from public.waitlist_signups w where w.user_id = e.user_id limit 1)
  from public.push_events e
  join auth.users u on u.id = e.user_id
  where e.id = any (v_ids);
end;
$$;

create or replace function public.record_push_result(
  p_event_id uuid,
  p_ok boolean,
  p_error text default null,
  p_dead_tokens text[] default '{}',
  p_message_id text default null,
  p_permanent boolean default false
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare e public.push_events;
begin
  perform public.push_require_service();
  select * into e from public.push_events where id = p_event_id;
  if not found then return; end if;
  if coalesce(array_length(p_dead_tokens, 1), 0) > 0 then
    delete from public.push_devices where token = any (p_dead_tokens);
  end if;

  if p_ok then
    update public.push_events
    set status = 'sent', sent_at = now(), provider_message_id = p_message_id, status_reason = null
    where id = p_event_id;
  elsif p_permanent or e.attempts >= 5 then
    update public.push_events
    set status = 'failed', status_reason = left(coalesce(p_error, 'failed'), 200)
    where id = p_event_id;
    if e.delivery = 'push' then perform public.push_fallback_to_email(p_event_id); end if;
  else
    update public.push_events
    set status = 'queued', status_reason = left(coalesce(p_error, 'retry'), 200),
        send_after = now() + make_interval(mins => 2 * e.attempts::int)
    where id = p_event_id;
  end if;
end;
$$;

-- -------------------------------- producer: place photo reviewed (push)
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
                 where user_id = new.user_id and os_permission <> 'denied') into v_has_device;
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

drop trigger if exists place_photo_submissions_queue_push on public.place_photo_submissions;
create trigger place_photo_submissions_queue_push
  after update of status on public.place_photo_submissions
  for each row execute function public.queue_photo_review_push();

-- --------------------------------------------------------------- grants
revoke all on function
  public.push_require_service(), public.push_require_draft_role(),
  public.push_require_sender_role(), public.push_profile_switch(uuid, text),
  public.enqueue_push_campaign(uuid), public.run_due_push_campaigns(),
  public.push_fallback_to_email(uuid), public.claim_push_events(integer),
  public.record_push_result(uuid, boolean, text, text[], text, boolean),
  public.queue_photo_review_push()
  from public, anon, authenticated;
grant execute on function
  public.enqueue_push_campaign(uuid), public.run_due_push_campaigns(),
  public.claim_push_events(integer),
  public.record_push_result(uuid, boolean, text, text[], text, boolean)
  to service_role;

revoke all on function
  public.register_push_device(text, text, text, text, text),
  public.remove_push_device(text), public.log_push_open(uuid),
  public.estimate_push_audience_dashboard(jsonb, boolean),
  public.save_push_campaign_dashboard(uuid, text, text, text, text, jsonb, boolean, timestamptz),
  public.send_test_push_dashboard(uuid), public.submit_push_campaign_dashboard(uuid),
  public.approve_push_campaign_dashboard(uuid), public.reject_push_campaign_dashboard(uuid, text),
  public.schedule_push_campaign_dashboard(uuid, timestamptz),
  public.cancel_push_campaign_dashboard(uuid), public.list_push_campaigns_dashboard(text),
  public.pending_push_approval_count_dashboard(), public.get_push_campaign_stats_dashboard(uuid),
  public.list_push_kinds_dashboard(), public.set_push_kind_enabled_dashboard(text, boolean),
  public.set_push_broadcasts_enabled_dashboard(boolean), public.push_device_health_dashboard()
  from public, anon;
grant execute on function
  public.register_push_device(text, text, text, text, text),
  public.remove_push_device(text), public.log_push_open(uuid),
  public.estimate_push_audience_dashboard(jsonb, boolean),
  public.save_push_campaign_dashboard(uuid, text, text, text, text, jsonb, boolean, timestamptz),
  public.send_test_push_dashboard(uuid), public.submit_push_campaign_dashboard(uuid),
  public.approve_push_campaign_dashboard(uuid), public.reject_push_campaign_dashboard(uuid, text),
  public.schedule_push_campaign_dashboard(uuid, timestamptz),
  public.cancel_push_campaign_dashboard(uuid), public.list_push_campaigns_dashboard(text),
  public.pending_push_approval_count_dashboard(), public.get_push_campaign_stats_dashboard(uuid),
  public.list_push_kinds_dashboard(), public.set_push_kind_enabled_dashboard(text, boolean),
  public.set_push_broadcasts_enabled_dashboard(boolean), public.push_device_health_dashboard()
  to authenticated;
