-- Run against a local database after all migrations. Rolls back all data.
-- The "direct handle update" check needs supabase/deferred/username_lockdown.sql
-- to have been applied (dev has it; on prod, run this test after the lockdown).
begin;
insert into auth.users (id, email, raw_user_meta_data) values
  ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'username-a@example.invalid',
   '{"full_name": "Amina Real Name"}'),
  ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', 'username-b@example.invalid',
   '{"full_name": "Brian Real Name"}');

do $$
declare
  v_a public.quest_public_profiles;
  v_b public.quest_public_profiles;
begin
  select * into v_a from public.quest_public_profiles
  where user_id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
  select * into v_b from public.quest_public_profiles
  where user_id = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';

  -- New accounts get a friendly word + number handle, not name/email/uid.
  if v_a.handle !~ '^[a-z]+[0-9]{1,5}$' then
    raise exception 'Unexpected generated handle: %', v_a.handle;
  end if;
  if v_a.handle like '%amina%' or v_a.handle like '%username%' then
    raise exception 'Handle leaked personal data: %', v_a.handle;
  end if;
  if not v_a.username_is_generated then
    raise exception 'A new account should be marked generated';
  end if;
  if public.has_chosen_username(v_a.user_id) then
    raise exception 'A new account has not chosen a username yet';
  end if;
  if v_a.handle = v_b.handle then
    raise exception 'Two accounts got the same handle';
  end if;
end $$;

select set_config('request.jwt.claim.sub',
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', true);
set local role authenticated;

do $$
declare
  v_suggestions text[];
  v_handle text;
  v_words text[] := '{}';
  v_result record;
begin
  -- Suggestions: four distinct, free, different words.
  v_suggestions := public.suggest_usernames(4);
  if array_length(v_suggestions, 1) <> 4 then
    raise exception 'Expected 4 suggestions, got %', v_suggestions;
  end if;
  foreach v_handle in array v_suggestions loop
    if public.check_username(v_handle) <> 'available' then
      raise exception 'Suggestion % is not available', v_handle;
    end if;
    v_words := v_words || regexp_replace(v_handle, '[0-9]+$', '');
  end loop;
  if (select count(distinct w) from unnest(v_words) w) <> 4 then
    raise exception 'Suggestions repeat a word: %', v_suggestions;
  end if;

  -- Validation outcomes.
  if public.check_username('ab') <> 'invalid' then raise exception 'ab'; end if;
  if public.check_username('12345') <> 'invalid' then raise exception 'digits only'; end if;
  if public.check_username('Bad Name') <> 'invalid' then raise exception 'space'; end if;
  if public.check_username('admin') <> 'reserved' then raise exception 'admin'; end if;
  if public.check_username('Kaunti47') <> 'reserved' then raise exception 'kaunti47'; end if;
  if public.check_username('fuck-you1') <> 'blocked' then raise exception 'blocked'; end if;

  -- Someone cannot set an invalid name.
  begin
    perform public.set_username('admin');
    raise exception 'A reserved username was accepted';
  exception when sqlstate '22023' then null;
  end;

  -- Handles cannot be written directly any more.
  begin
    update public.quest_public_profiles set handle = 'sneaky1'
    where user_id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
    raise exception 'A direct handle update was allowed';
  exception when insufficient_privilege then null;
  end;

  -- First choice: lowercased, flagged chosen, no cooldown yet.
  select * into v_result from public.set_username('  Nyati-Fan ');
  if v_result.handle <> 'nyati-fan' or v_result.username_is_generated then
    raise exception 'First choice not saved: %', v_result;
  end if;
  if v_result.username_changed_at is not null then
    raise exception 'The first choice should not start the cooldown';
  end if;
  if not public.has_chosen_username('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa') then
    raise exception 'has_chosen_username should be true after choosing';
  end if;
  if public.check_username('nyati-fan') <> 'yours' then
    raise exception 'Own handle should report yours';
  end if;
end $$;

-- A second user cannot take it, in any casing.
select set_config('request.jwt.claim.sub',
  'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', true);

do $$
declare
  v_own text;
  v_result record;
begin
  if public.check_username('NYATI-FAN') <> 'taken' then
    raise exception 'A taken username showed as available';
  end if;
  begin
    perform public.set_username('nyati-fan');
    raise exception 'A taken username was accepted';
  exception when sqlstate '22023' then null;
  end;

  -- "Keep this one": confirm the generated handle as is.
  select handle into v_own from public.quest_public_profiles
  where user_id = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
  select * into v_result from public.set_username(v_own);
  if v_result.username_is_generated or v_result.handle <> v_own then
    raise exception 'Keeping the generated handle failed: %', v_result;
  end if;
end $$;

-- Back to A: change once, then hit the 30 day limit.
select set_config('request.jwt.claim.sub',
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', true);

do $$
declare
  v_result record;
begin
  select * into v_result from public.set_username('nyati-two');
  if v_result.handle <> 'nyati-two' or v_result.username_changed_at is null then
    raise exception 'The change was not saved: %', v_result;
  end if;

  begin
    perform public.set_username('nyati-three');
    raise exception 'The 30 day limit was not enforced';
  exception when sqlstate '54000' then null;
  end;
end $$;

-- The old handle is held for B.
select set_config('request.jwt.claim.sub',
  'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', true);
do $$
begin
  if public.check_username('nyati-fan') <> 'taken' then
    raise exception 'A released handle was available during the hold';
  end if;
  if public.check_username('nyati-two') <> 'taken' then
    raise exception 'A current handle was available to someone else';
  end if;
end $$;

reset role;

-- After the hold and the cooldown, things open up again.
update public.username_history set released_at = now() - interval '1 day';
update public.quest_public_profiles
set username_changed_at = now() - interval '31 days'
where user_id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';

select set_config('request.jwt.claim.sub',
  'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', true);
set local role authenticated;
do $$
begin
  if public.check_username('nyati-fan') <> 'available' then
    raise exception 'A handle past its hold should be free';
  end if;
end $$;

select set_config('request.jwt.claim.sub',
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', true);
do $$
declare
  v_result record;
begin
  select * into v_result from public.set_username('nyati-three');
  if v_result.handle <> 'nyati-three' then
    raise exception 'A change after 30 days failed: %', v_result;
  end if;
end $$;

reset role;

-- Existing real names stay stored (staff need them) but are not part of
-- the public identity: the account keeps its display_name, handle is the
-- public name.
do $$
begin
  if (select display_name from public.quest_public_profiles
      where user_id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa') <> 'Amina Real Name' then
    raise exception 'display_name should be preserved for staff';
  end if;
end $$;

-- Nothing is exposed to anon.
set local role anon;
do $$
begin
  begin
    perform public.suggest_usernames(4);
    raise exception 'anon could call suggest_usernames';
  exception when insufficient_privilege then null;
  end;
end $$;
reset role;

rollback;
