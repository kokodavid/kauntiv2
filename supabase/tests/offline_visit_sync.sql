-- Run against a local database after all migrations. Rolls back all test data.
begin;
insert into auth.users(id, email) values
  ('11111111-1111-4111-8111-111111111111', 'offline-sync-test@example.invalid');
select set_config('request.jwt.claim.sub', '11111111-1111-4111-8111-111111111111', true);
set local role authenticated;
select public.sync_county_visit('11111111-1111-4111-8111-111111111111',
  1::smallint, 'explored', '2026-09-07T00:00:00Z');
select public.sync_county_visit('11111111-1111-4111-8111-111111111111',
  1::smallint, 'explored', '2026-09-07T00:00:00Z');
do $$
begin
  if (select pass_count from public.county_visits where county_id = 1 and user_id = auth.uid()) <> 1 then
    raise exception 'Duplicate retry incremented visit count';
  end if;
  begin
    perform public.sync_county_visit('22222222-2222-4222-8222-222222222222',
      1::smallint, 'explored', '2026-09-07T00:00:00Z');
    raise exception 'Wrong account was accepted';
  exception when insufficient_privilege then null;
  end;
end $$;
select public.sync_county_visit('11111111-1111-4111-8111-111111111111',
  1::smallint, 'passed_through', '2026-09-08T00:00:00Z');
do $$
begin
  if not exists (select 1 from public.county_visits where county_id = 1
      and user_id = auth.uid() and pass_count = 2 and state = 'explored') then
    raise exception 'Return visit did not preserve explored state';
  end if;
end $$;
rollback;
