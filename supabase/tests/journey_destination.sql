-- Run against a local database after all migrations. Rolls back all data.
begin;
insert into auth.users (id, email) values
  ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'destination-test@example.invalid');
insert into public.pro_entitlement_periods (user_id, starts_at, ends_at)
values ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        now() - interval '1 day', now() + interval '1 day');

select set_config('request.jwt.claim.sub',
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', true);
set local role authenticated;

do $$
declare
  v_id uuid := 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
  v_place uuid := 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';
  v_result jsonb;
begin
  v_result := public.upload_journey_to_place(
    'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', v_id,
    'Journey to Nairobi National Museum',
    now() - interval '1 hour', now() - interval '10 minutes',
    '[]'::jsonb, 0, '[]'::jsonb, v_place,
    'Nairobi National Museum', -1.273, 36.814
  );
  if (v_result ->> 'already_uploaded')::boolean then
    raise exception 'First destination upload reported as a retry';
  end if;
  if not exists (
    select 1 from public.journeys
    where id = v_id and destination_place_id = v_place
      and destination_name = 'Nairobi National Museum'
  ) then
    raise exception 'Destination was not stored';
  end if;

  v_result := public.upload_journey_to_place(
    'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', v_id,
    'Journey to Nairobi National Museum',
    now() - interval '1 hour', now() - interval '10 minutes',
    '[]'::jsonb, 0, '[]'::jsonb, v_place,
    'Nairobi National Museum', -1.273, 36.814
  );
  if not (v_result ->> 'already_uploaded')::boolean then
    raise exception 'Retry was not idempotent';
  end if;

  begin
    perform public.upload_journey_to_place(
      'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', v_id,
      'Changed destination', now() - interval '1 hour',
      now() - interval '10 minutes', '[]'::jsonb, 0, '[]'::jsonb,
      'dddddddd-dddd-4ddd-8ddd-dddddddddddd', 'Other place', null, null
    );
    raise exception 'Changed destination was accepted';
  exception when invalid_parameter_value then null;
  end;
end $$;

-- Planned stops are stored with the destination, and bad ones are refused.
do $$
declare
  v_id uuid := 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee';
  v_place uuid := 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';
begin
  perform public.upload_journey_to_place(
    'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', v_id, 'Trip with stops',
    now() - interval '1 hour', now() - interval '10 minutes',
    '[]'::jsonb, 0, '[]'::jsonb, v_place, 'Ol Donyo Sabuk', -1.14, 37.2,
    null,
    '[{"place_id":"p1","name":"Fourteen Falls","lat":-1.2,"lng":37.1}]'::jsonb
  );
  if (select jsonb_array_length(stops) from public.journeys
      where id = v_id) <> 1 then
    raise exception 'Stops were not stored';
  end if;

  begin
    perform public.upload_journey_to_place(
      'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
      'ffffffff-ffff-4fff-8fff-ffffffffffff', 'Bad stops',
      now() - interval '1 hour', now() - interval '10 minutes',
      '[]'::jsonb, 0, '[]'::jsonb, v_place, 'Ol Donyo Sabuk', -1.14, 37.2,
      null, '[{"place_id":"p1","name":"","lat":99,"lng":0}]'::jsonb
    );
    raise exception 'Invalid stops were accepted';
  exception when invalid_parameter_value then null;
  end;
end $$;

rollback;
