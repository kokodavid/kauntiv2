-- Run against a local database after all migrations. Rolls back all test data.
begin;
insert into auth.users (id, email) values
  ('33333333-3333-4333-8333-333333333333', 'journey-pro@example.invalid'),
  ('44444444-4444-4444-8444-444444444444', 'journey-free@example.invalid');

-- Pro for the first user from 10 days ago until 1 hour ago (lapsed).
insert into public.pro_entitlement_periods (user_id, starts_at, ends_at)
values ('33333333-3333-4333-8333-333333333333',
        now() - interval '10 days', now() - interval '1 hour');

select set_config('request.jwt.claim.sub',
  '33333333-3333-4333-8333-333333333333', true);
set local role authenticated;

do $$
declare
  v_result jsonb;
  v_points jsonb := jsonb_build_array(
    jsonb_build_object('segment', 0, 'recorded_at', now() - interval '3 hours',
      'lat', -1.2921, 'lng', 36.8219, 'accuracy_m', 8),
    jsonb_build_object('segment', 0, 'recorded_at', now() - interval '170 minutes',
      'lat', -1.3000, 'lng', 36.8300, 'accuracy_m', 8),
    -- A pause: the jump to segment 1 is not counted.
    jsonb_build_object('segment', 1, 'recorded_at', now() - interval '100 minutes',
      'lat', -0.5000, 'lng', 36.0000, 'accuracy_m', 10)
  );
begin
  -- Started while Pro was active, finished after it lapsed: accepted.
  v_result := public.upload_journey(
    '55555555-5555-4555-8555-555555555555', 'Nairobi loop',
    now() - interval '3 hours', now() - interval '90 minutes', v_points);
  if (v_result ->> 'already_uploaded')::boolean then
    raise exception 'First upload reported as a retry';
  end if;
  -- ~1.26 km between the two segment-0 points; the segment jump adds nothing.
  if (v_result ->> 'distance_m')::numeric not between 1200 and 1350 then
    raise exception 'Unexpected distance %', v_result ->> 'distance_m';
  end if;
  if (select count(*) from public.journey_points
      where journey_id = '55555555-5555-4555-8555-555555555555') <> 3 then
    raise exception 'Points were not stored';
  end if;

  -- A retry returns the stored Journey.
  v_result := public.upload_journey(
    '55555555-5555-4555-8555-555555555555', 'Nairobi loop',
    now() - interval '3 hours', now() - interval '90 minutes', v_points);
  if not (v_result ->> 'already_uploaded')::boolean then
    raise exception 'Retry was not idempotent';
  end if;

  -- Started after Pro lapsed: rejected.
  begin
    perform public.upload_journey(
      '66666666-6666-4666-8666-666666666666', 'Too late',
      now() - interval '30 minutes', now() - interval '10 minutes', '[]');
    raise exception 'Upload without Pro was accepted';
  exception when insufficient_privilege then null;
  end;

  -- Points out of order: rejected.
  begin
    perform public.upload_journey(
      '77777777-7777-4777-8777-777777777777', 'Out of order',
      now() - interval '3 hours', now() - interval '2 hours',
      jsonb_build_array(v_points -> 1, v_points -> 0));
    raise exception 'Out-of-order points were accepted';
  exception when invalid_parameter_value then null;
  end;

  -- Ends in the future: rejected.
  begin
    perform public.upload_journey(
      '88888888-8888-4888-8888-888888888888', 'Future',
      now() - interval '1 hour', now() + interval '1 hour', '[]');
    raise exception 'Future end was accepted';
  exception when invalid_parameter_value then null;
  end;

  -- My status reflects the lapsed period.
  if (public.my_pro_status() ->> 'active')::boolean then
    raise exception 'Lapsed Pro reported as active';
  end if;
end $$;

-- Another account can't read or overwrite the Journey.
select set_config('request.jwt.claim.sub',
  '44444444-4444-4444-8444-444444444444', true);
do $$
begin
  if exists (select 1 from public.journeys
      where id = '55555555-5555-4555-8555-555555555555') then
    raise exception 'Another account can read the Journey';
  end if;
  begin
    perform public.upload_journey(
      '55555555-5555-4555-8555-555555555555', 'Hijack',
      now() - interval '3 hours', now() - interval '90 minutes', '[]');
    raise exception 'Another account overwrote the Journey';
  exception when insufficient_privilege then null;
  end;
  begin
    insert into public.pro_entitlement_periods (user_id, starts_at)
    values ('44444444-4444-4444-8444-444444444444', now());
    raise exception 'A user granted themselves Pro';
  exception when insufficient_privilege then null;
  end;
end $$;
rollback;
