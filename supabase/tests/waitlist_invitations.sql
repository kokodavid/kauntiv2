-- Run after migrations. No emails are sent; all fixture data rolls back.
begin;
insert into auth.users (id, email) values
  ('e1000000-0000-4000-8000-000000000001', 'invite-owner@example.invalid'),
  ('e1000000-0000-4000-8000-000000000002', 'invite-mod@example.invalid');
insert into public.admin_members (user_id, role, status) values
  ('e1000000-0000-4000-8000-000000000001', 'owner', 'active'),
  ('e1000000-0000-4000-8000-000000000002', 'moderator', 'active');
insert into public.waitlist_signups (id, email, status, platform, source) values
  ('e2000000-0000-4000-8000-000000000001', 'invite-open@example.invalid', 'waitlisted', null, 'dashboard'),
  ('e2000000-0000-4000-8000-000000000002', 'invite-applied@example.invalid', 'applied', 'ios', 'dashboard'),
  ('e2000000-0000-4000-8000-000000000003', 'invite-closed@example.invalid', 'declined', null, 'dashboard');
update public.beta_tester_invite_settings set delivery_enabled = true,
  android_opt_in_url = 'https://play.google.com/apps/testing/test',
  ios_testflight_url = 'https://testflight.apple.com/join/test' where singleton;

select set_config('request.jwt.claim.sub', 'e1000000-0000-4000-8000-000000000002', true);
set local role authenticated;
do $$ begin
  begin
    perform public.claim_waitlist_tester_invite_dashboard('e2000000-0000-4000-8000-000000000001', 'android');
    raise exception 'Moderator sent an invitation';
  exception when insufficient_privilege then null; end;
end $$;
select set_config('request.jwt.claim.sub', 'e1000000-0000-4000-8000-000000000001', true);
do $$
declare r record;
begin
  select * into r from public.claim_waitlist_tester_invite_dashboard('e2000000-0000-4000-8000-000000000001', 'android');
  if r.founder_number is not null or r.platform <> 'android' or r.email <> 'invite-open@example.invalid'
     or r.access_url <> 'https://play.google.com/apps/testing/test' then
    raise exception 'Wrong general invitation: %', r;
  end if;
  begin
    perform public.claim_waitlist_tester_invite_dashboard('e2000000-0000-4000-8000-000000000001', 'android');
    raise exception 'Duplicate in-flight invitation accepted';
  exception when sqlstate '55P03' then null; end;
  begin
    perform public.claim_waitlist_tester_invite_dashboard('e2000000-0000-4000-8000-000000000003', 'ios');
    raise exception 'Closed applicant accepted';
  exception when sqlstate '22023' then null; end;
  begin
    perform public.claim_waitlist_tester_invite_dashboard('e2000000-0000-4000-8000-000000000002', null);
    raise exception 'Missing platform accepted';
  exception when sqlstate '22023' then null; end;
  begin
    perform public.claim_beta_tester_invite_dashboard('e2000000-0000-4000-8000-000000000001');
    raise exception 'Seat invitation accepted without a seat';
  exception when sqlstate '22023' then null; end;
end $$;
reset role;
do $$
declare r record;
begin
  select * into r from public.waitlist_signups where id = 'e2000000-0000-4000-8000-000000000001';
  if r.status <> 'waitlisted' or r.founder_number is not null or r.platform is not null or r.approved_at is not null then
    raise exception 'Invitation changed applicant or allocated a seat';
  end if;
end $$;
update public.beta_tester_invites set status = 'failed' where signup_id = 'e2000000-0000-4000-8000-000000000001';
set local role authenticated;
select * from public.claim_waitlist_tester_invite_dashboard('e2000000-0000-4000-8000-000000000001', 'ios');
select * from public.claim_waitlist_tester_invite_dashboard('e2000000-0000-4000-8000-000000000002', 'ios');
reset role;
do $$ begin
  if not exists (select 1 from public.beta_tester_invites where signup_id = 'e2000000-0000-4000-8000-000000000001'
    and founder_number is null and platform = 'ios' and attempt_count = 2) then
    raise exception 'Retry did not preserve the unseated invitation';
  end if;
end $$;
update public.beta_tester_invite_settings set delivery_enabled = false where singleton;
set local role authenticated;
do $$ begin
  begin
    perform public.claim_waitlist_tester_invite_dashboard('e2000000-0000-4000-8000-000000000001', 'android');
    raise exception 'Disabled delivery accepted';
  exception when sqlstate '22023' then null; end;
end $$;
rollback;
