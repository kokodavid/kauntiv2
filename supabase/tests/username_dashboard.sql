-- Run against a local database after all migrations. Rolls back all data.
begin;
insert into auth.users (id, email, raw_user_meta_data) values
  ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'dash-user@example.invalid', '{"full_name": "Amina"}'),
  ('cccccccc-cccc-4ccc-8ccc-cccccccccccc', 'dash-owner@example.invalid', '{}'),
  ('dddddddd-dddd-4ddd-8ddd-dddddddddddd', 'dash-mod@example.invalid', '{}');

insert into public.admin_members (user_id, role, status) values
  ('cccccccc-cccc-4ccc-8ccc-cccccccccccc', 'owner', 'active'),
  ('dddddddd-dddd-4ddd-8ddd-dddddddddddd', 'moderator', 'active');

-- The user picks a name first.
select set_config('request.jwt.claim.sub', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', true);
set local role authenticated;
select public.set_username('nyati-fan');

-- A normal user cannot reset or edit lists.
do $$
begin
  begin
    perform public.reset_username_dashboard('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa');
    raise exception 'A normal user reset a username';
  exception when insufficient_privilege then null;
  end;
  begin
    perform public.username_lists_dashboard();
    raise exception 'A normal user read the lists';
  exception when insufficient_privilege then null;
  end;
end $$;

-- A moderator can reset but not edit lists.
select set_config('request.jwt.claim.sub', 'dddddddd-dddd-4ddd-8ddd-dddddddddddd', true);
do $$
declare r record;
begin
  begin
    perform public.add_username_term_dashboard('words', 'zebra');
    raise exception 'A moderator edited the lists';
  exception when insufficient_privilege then null;
  end;
  select * into r from public.reset_username_dashboard('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa');
  if r.handle !~ '^[a-z]+[0-9]{1,5}$' or not r.username_is_generated then
    raise exception 'Reset gave an unexpected result: %', r;
  end if;
end $$;

-- The user is back on a generated name, may choose freely, and cannot take
-- the old one back.
select set_config('request.jwt.claim.sub', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', true);
do $$
declare r record;
begin
  if public.has_chosen_username('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa') then
    raise exception 'A reset account should need to choose again';
  end if;
  if public.check_username('nyati-fan') <> 'taken' then
    raise exception 'The old username should be held even against its owner';
  end if;
  select * into r from public.set_username('nyati-fresh');
  if r.handle <> 'nyati-fresh' then raise exception 'Could not choose again: %', r; end if;
end $$;

-- Owner edits the lists.
select set_config('request.jwt.claim.sub', 'cccccccc-cccc-4ccc-8ccc-cccccccccccc', true);
do $$
declare l jsonb;
begin
  perform public.add_username_term_dashboard('words', ' Zebra ');
  perform public.add_username_term_dashboard('blocked', 'badword');
  perform public.add_username_term_dashboard('reserved', 'my-brand');
  l := public.username_lists_dashboard();
  if not (l -> 'words') @> '[{"word":"zebra","active":true}]'::jsonb then raise exception 'word missing %', l; end if;
  if not (l -> 'blocked') ? 'badword' then raise exception 'blocked missing'; end if;
  if not (l -> 'reserved') ? 'my-brand' then raise exception 'reserved missing'; end if;

  begin
    perform public.add_username_term_dashboard('words', 'a1');
    raise exception 'A bad word was accepted';
  exception when sqlstate '22023' then null;
  end;
  begin
    perform public.add_username_term_dashboard('nope', 'abc');
    raise exception 'An unknown list was accepted';
  exception when sqlstate '22023' then null;
  end;

  -- The new rules apply.
  if public.check_username('xbadwordx') <> 'blocked' then raise exception 'new blocked term not applied'; end if;
  if public.check_username('my-brand') <> 'reserved' then raise exception 'new reserved name not applied'; end if;

  perform public.remove_username_term_dashboard('words', 'zebra');
  perform public.remove_username_term_dashboard('blocked', 'badword');
  perform public.remove_username_term_dashboard('reserved', 'my-brand');
  l := public.username_lists_dashboard();
  if not (l -> 'words') @> '[{"word":"zebra","active":false}]'::jsonb then raise exception 'word not switched off'; end if;
  if (l -> 'blocked') ? 'badword' then raise exception 'blocked not removed'; end if;
  if public.check_username('xbadwordx') <> 'available' then raise exception 'removed term still blocks'; end if;
end $$;

rollback;
