-- Run against a local database after all migrations. Rolls back all test data.
begin;
insert into auth.users (id, email) values
  ('77777777-7777-4777-8777-777777777777', 'billing-user@example.invalid');

do $$
declare
  v_user text := '77777777-7777-4777-8777-777777777777';
  v_now bigint := (extract(epoch from now()) * 1000)::bigint;
  v_day bigint := 86400000;
  v_result text;
  v_ends timestamptz;
begin
  -- First purchase creates one period.
  v_result := public.apply_revenuecat_event(jsonb_build_object(
    'id', 'evt-1', 'type', 'INITIAL_PURCHASE', 'app_user_id', v_user,
    'store', 'PLAY_STORE', 'original_transaction_id', 'GPA.1',
    'purchased_at_ms', v_now - v_day, 'expiration_at_ms', v_now + 29 * v_day,
    'event_timestamp_ms', v_now - v_day));
  if v_result <> 'applied' then raise exception 'Purchase not applied: %', v_result; end if;

  -- Same event again: harmless.
  v_result := public.apply_revenuecat_event(jsonb_build_object(
    'id', 'evt-1', 'type', 'INITIAL_PURCHASE', 'app_user_id', v_user,
    'store', 'PLAY_STORE', 'original_transaction_id', 'GPA.1',
    'purchased_at_ms', v_now - v_day, 'expiration_at_ms', v_now + 29 * v_day));
  if v_result <> 'duplicate' then raise exception 'Retry was not a duplicate'; end if;

  -- Renewal moves the end of the same period.
  perform public.apply_revenuecat_event(jsonb_build_object(
    'id', 'evt-2', 'type', 'RENEWAL', 'app_user_id', v_user,
    'store', 'PLAY_STORE', 'original_transaction_id', 'GPA.1',
    'purchased_at_ms', v_now, 'expiration_at_ms', v_now + 59 * v_day,
    'event_timestamp_ms', v_now));
  if (select count(*) from public.pro_entitlement_periods
      where user_id = v_user::uuid and source = 'play_store') <> 1 then
    raise exception 'Renewal created a second period';
  end if;

  -- An older event arriving late does not roll the end date back.
  perform public.apply_revenuecat_event(jsonb_build_object(
    'id', 'evt-old', 'type', 'RENEWAL', 'app_user_id', v_user,
    'store', 'PLAY_STORE', 'original_transaction_id', 'GPA.1',
    'purchased_at_ms', v_now - v_day, 'expiration_at_ms', v_now + 10 * v_day,
    'event_timestamp_ms', v_now - 2 * v_day));
  select ends_at into v_ends from public.pro_entitlement_periods
    where user_id = v_user::uuid and source = 'play_store';
  if v_ends < now() + interval '50 days' then
    raise exception 'Out-of-order event moved the end date back';
  end if;

  -- A refund ends access now.
  perform public.apply_revenuecat_event(jsonb_build_object(
    'id', 'evt-3', 'type', 'CANCELLATION', 'cancel_reason', 'CUSTOMER_SUPPORT',
    'app_user_id', v_user, 'store', 'PLAY_STORE',
    'original_transaction_id', 'GPA.1',
    'purchased_at_ms', v_now, 'expiration_at_ms', v_now + 59 * v_day,
    'event_timestamp_ms', v_now + 1000));
  if exists (
    select 1 from public.pro_entitlement_periods
    where user_id = v_user::uuid and source = 'play_store'
      and ends_at > now() + interval '1 minute') then
    raise exception 'Refund did not end access';
  end if;

  -- An ordinary cancellation keeps access to the paid-for end date.
  perform public.apply_revenuecat_event(jsonb_build_object(
    'id', 'evt-4', 'type', 'INITIAL_PURCHASE', 'app_user_id', v_user,
    'store', 'APP_STORE', 'original_transaction_id', '1000001',
    'purchased_at_ms', v_now, 'expiration_at_ms', v_now + 30 * v_day,
    'event_timestamp_ms', v_now));
  perform public.apply_revenuecat_event(jsonb_build_object(
    'id', 'evt-5', 'type', 'CANCELLATION', 'cancel_reason', 'UNSUBSCRIBE',
    'app_user_id', v_user, 'store', 'APP_STORE',
    'original_transaction_id', '1000001',
    'purchased_at_ms', v_now, 'expiration_at_ms', v_now + 30 * v_day,
    'event_timestamp_ms', v_now + 1000));
  if not exists (
    select 1 from public.pro_entitlement_periods
    where user_id = v_user::uuid and source = 'app_store'
      and ends_at > now() + interval '20 days') then
    raise exception 'Cancellation cut access short';
  end if;

  -- Anonymous RevenueCat ids and other stores are ignored.
  v_result := public.apply_revenuecat_event(jsonb_build_object(
    'id', 'evt-6', 'type', 'INITIAL_PURCHASE',
    'app_user_id', '$RCAnonymousID:abc', 'store', 'APP_STORE',
    'original_transaction_id', '1000002',
    'purchased_at_ms', v_now, 'expiration_at_ms', v_now + 30 * v_day));
  if v_result <> 'ignored' then raise exception 'Anonymous id was applied'; end if;
  v_result := public.apply_revenuecat_event(jsonb_build_object(
    'id', 'evt-7', 'type', 'INITIAL_PURCHASE', 'app_user_id', v_user,
    'store', 'STRIPE', 'original_transaction_id', 'sub_1',
    'purchased_at_ms', v_now, 'expiration_at_ms', v_now + 30 * v_day));
  if v_result <> 'ignored' then raise exception 'Unsupported store was applied'; end if;

  -- A restore under another account moves the subscription to it.
  insert into auth.users (id, email) values
    ('88888888-8888-4888-8888-888888888888', 'billing-new@example.invalid');
  v_result := public.apply_revenuecat_event(jsonb_build_object(
    'id', 'evt-8', 'type', 'TRANSFER', 'store', 'APP_STORE',
    'transferred_from', jsonb_build_array(v_user, '$RCAnonymousID:zzz'),
    'transferred_to', jsonb_build_array('88888888-8888-4888-8888-888888888888'),
    'event_timestamp_ms', v_now + 5000));
  if v_result <> 'applied' then raise exception 'Transfer not applied: %', v_result; end if;
  if not exists (
    select 1 from public.pro_entitlement_periods
    where user_id = '88888888-8888-4888-8888-888888888888'
      and source = 'app_store' and ends_at > now() + interval '20 days') then
    raise exception 'Transfer did not move the subscription';
  end if;
  if exists (select 1 from public.pro_entitlement_periods
             where user_id = v_user::uuid and source = 'app_store') then
    raise exception 'Old account kept the subscription';
  end if;

  -- The flag exists and starts off.
  if (select enabled from public.app_feature_flags
      where feature_key = 'billing') is not false then
    raise exception 'billing flag should start off';
  end if;
end;
$$;

-- Clients can call neither the write path nor read the event log.
set local role authenticated;
do $$
begin
  begin
    perform public.apply_revenuecat_event('{"id":"x","type":"RENEWAL"}');
    raise exception 'authenticated could call apply_revenuecat_event';
  exception when insufficient_privilege then null;
  end;
  begin
    perform count(*) from public.billing_events;
    raise exception 'authenticated could read billing_events';
  exception when insufficient_privilege then null;
  end;
end;
$$;

rollback;
