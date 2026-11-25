-- Billing foundation ----------------------------------------------------------
-- Store purchases (App Store, Google Play) arrive through RevenueCat and are
-- written into pro_entitlement_periods by the revenuecat-webhook edge
-- function. Clients still cannot write periods; this file adds:
--   1. a dashboard-controlled "billing" switch (paywall hidden while off),
--   2. a log of received RevenueCat events (also makes retries harmless),
--   3. one period per store subscription, kept current as it renews/ends,
--   4. apply_revenuecat_event(), the single service-only write path.
-- Prices are not stored here: they live in the stores and RevenueCat.

-- 1. Switch ------------------------------------------------------------------
alter table public.app_feature_flags
  drop constraint if exists app_feature_flags_feature_key_check;
alter table public.app_feature_flags add constraint app_feature_flags_feature_key_check
  check (feature_key in (
    'county_news', 'public_trips_read', 'public_trips_publish',
    'place_photos', 'push_broadcasts', 'place_check_ins', 'ads', 'billing'
  ));
insert into public.app_feature_flags (feature_key, enabled)
values ('billing', false)
on conflict (feature_key) do nothing;

create or replace function public.set_billing_enabled_dashboard(
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
  values ('billing', p_enabled, now(), auth.uid())
  on conflict (feature_key) do update
  set enabled = excluded.enabled,
      updated_at = excluded.updated_at,
      updated_by = excluded.updated_by;
  return p_enabled;
end;
$$;

revoke execute on function public.set_billing_enabled_dashboard(boolean)
  from public, anon;
grant execute on function public.set_billing_enabled_dashboard(boolean)
  to authenticated;

-- 2. Event log ---------------------------------------------------------------
create table public.billing_events (
  -- RevenueCat's event id: receiving the same event twice does nothing.
  id text primary key,
  received_at timestamptz not null default now(),
  event_type text not null,
  app_user_id text,
  environment text,
  store text,
  outcome text not null default 'received',
  payload jsonb not null
);

create index billing_events_user_idx
  on public.billing_events (app_user_id, received_at desc);

-- Service role only: no policies, no client grants.
alter table public.billing_events enable row level security;
revoke all on public.billing_events from anon, authenticated;

-- 3. One period per store subscription ---------------------------------------
alter table public.pro_entitlement_periods
  add column if not exists store_event_at timestamptz;

-- reference holds the store's original transaction id, so a subscription is
-- one row for its whole life and renewals just move ends_at.
create unique index if not exists pro_entitlement_periods_store_reference_idx
  on public.pro_entitlement_periods (source, reference)
  where reference is not null and source <> 'admin';

-- 4. The write path ----------------------------------------------------------
-- Takes the "event" object of a RevenueCat webhook. Returns what happened:
-- applied, duplicate, or ignored. Raises only on real failures, so the edge
-- function can answer 500 and RevenueCat retries.
create or replace function public.apply_revenuecat_event(p_event jsonb)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id text := p_event ->> 'id';
  v_type text := p_event ->> 'type';
  v_app_user text := p_event ->> 'app_user_id';
  v_store text := p_event ->> 'store';
  v_source text;
  v_user uuid;
  v_from uuid[];
  v_ref text;
  v_start timestamptz;
  v_end timestamptz;
  v_at timestamptz;
  v_outcome text := 'ignored';
begin
  if v_id is null or v_type is null then
    raise exception 'Event id and type are required' using errcode = '22023';
  end if;

  insert into public.billing_events
    (id, event_type, app_user_id, environment, store, payload)
  values
    (v_id, v_type, v_app_user, p_event ->> 'environment', v_store, p_event)
  on conflict (id) do nothing;
  if not found then
    return 'duplicate';
  end if;

  -- A restore under another account moves the subscription with it. The
  -- event has no period dates, so the existing rows change owner.
  if v_type = 'TRANSFER' then
    select coalesce(array_agg(value::uuid), '{}') into v_from
    from jsonb_array_elements_text(
      coalesce(p_event -> 'transferred_from', '[]'::jsonb))
    where value ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$';
    select value::uuid into v_user
    from jsonb_array_elements_text(
      coalesce(p_event -> 'transferred_to', '[]'::jsonb))
    where value ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
      and exists (select 1 from auth.users where id = value::uuid)
    limit 1;
    if v_user is null or cardinality(v_from) = 0 then
      update public.billing_events set outcome = 'ignored' where id = v_id;
      return 'ignored';
    end if;
    update public.pro_entitlement_periods
    set user_id = v_user,
        store_event_at = to_timestamp(
          coalesce((p_event ->> 'event_timestamp_ms')::numeric,
                   extract(epoch from now()) * 1000) / 1000.0)
    where user_id = any (v_from)
      and user_id <> v_user
      and source in ('app_store', 'play_store');
    update public.billing_events set outcome = 'applied' where id = v_id;
    return 'applied';
  end if;

  -- Only events that describe a subscription period change entitlement.
  if v_type not in (
    'INITIAL_PURCHASE', 'RENEWAL', 'PRODUCT_CHANGE', 'UNCANCELLATION',
    'CANCELLATION', 'EXPIRATION', 'BILLING_ISSUE', 'SUBSCRIPTION_EXTENDED'
  ) then
    return 'ignored';
  end if;

  v_source := case v_store
    when 'APP_STORE' then 'app_store'
    when 'MAC_APP_STORE' then 'app_store'
    when 'PLAY_STORE' then 'play_store'
    else null
  end;
  v_ref := coalesce(p_event ->> 'original_transaction_id',
                    p_event ->> 'transaction_id');
  if v_source is null or v_ref is null
     or p_event ->> 'expiration_at_ms' is null
     or p_event ->> 'purchased_at_ms' is null then
    update public.billing_events set outcome = 'ignored' where id = v_id;
    return 'ignored';
  end if;

  -- Purchases are only offered to signed-in users, so the RevenueCat user id
  -- is the Supabase user id. Anything else (anonymous ids) is not ours.
  begin
    v_user := v_app_user::uuid;
  exception when invalid_text_representation then
    v_user := null;
  end;
  if v_user is null
     or not exists (select 1 from auth.users where id = v_user) then
    update public.billing_events set outcome = 'unknown_user' where id = v_id;
    return 'ignored';
  end if;

  v_start := to_timestamp((p_event ->> 'purchased_at_ms')::numeric / 1000.0);
  v_end := to_timestamp((p_event ->> 'expiration_at_ms')::numeric / 1000.0);
  v_at := to_timestamp(
    coalesce((p_event ->> 'event_timestamp_ms')::numeric,
             (p_event ->> 'purchased_at_ms')::numeric) / 1000.0);

  -- A refund ends access now. An ordinary cancellation (auto-renew off) keeps
  -- access until the paid-for period ends, which expiration_at_ms already says.
  if v_type = 'CANCELLATION'
     and p_event ->> 'cancel_reason' = 'CUSTOMER_SUPPORT' then
    v_end := least(v_end, v_at);
  end if;

  insert into public.pro_entitlement_periods
    (user_id, starts_at, ends_at, source, reference, store_event_at)
  values
    (v_user, v_start, greatest(v_end, v_start + interval '1 second'),
     v_source, v_ref, v_at)
  on conflict (source, reference)
    where reference is not null and source <> 'admin'
  do update set
    user_id = excluded.user_id,
    ends_at = greatest(excluded.ends_at,
                       pro_entitlement_periods.starts_at + interval '1 second'),
    store_event_at = excluded.store_event_at
  -- Events can arrive out of order; the newest one wins.
  where pro_entitlement_periods.store_event_at is null
     or excluded.store_event_at >= pro_entitlement_periods.store_event_at;

  v_outcome := 'applied';
  update public.billing_events set outcome = v_outcome where id = v_id;
  return v_outcome;
end;
$$;

revoke execute on function public.apply_revenuecat_event(jsonb)
  from public, anon, authenticated;
grant execute on function public.apply_revenuecat_event(jsonb)
  to service_role;
