-- Run against a local database after all migrations. Rolls back all data.
begin;
insert into auth.users (id, email) values
  ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'saved-trips-a@example.invalid'),
  ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', 'saved-trips-b@example.invalid');

select set_config('request.jwt.claim.sub',
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', true);
set local role authenticated;

do $$
declare
  v_place uuid;
begin
  select id into v_place from public.places limit 1;
  if v_place is null then
    raise exception 'Seed at least one place before running this test';
  end if;

  insert into public.saved_trips (name, destination_place_id, stop_place_ids)
  values ('Day out', v_place, '{}');

  begin
    insert into public.saved_trips (name, destination_place_id, stop_place_ids)
    values ('Day out again', v_place, '{}');
    raise exception 'The same plan was saved twice';
  exception when unique_violation then null;
  end;

  begin
    insert into public.saved_trips (name, destination_place_id)
    values ('   ', v_place);
    raise exception 'A blank name was accepted';
  exception when check_violation then null;
  end;

  -- Another user cannot see it.
  perform set_config('request.jwt.claim.sub',
    'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', true);
  if exists (select 1 from public.saved_trips) then
    raise exception 'A saved trip leaked to another account';
  end if;
end $$;

rollback;
