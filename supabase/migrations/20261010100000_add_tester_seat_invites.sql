-- Tester access invites are created only after an administrator awards a seat.
-- The sender is an Edge Function; no mail-provider credential is stored in SQL.

create table if not exists public.beta_tester_invite_settings (
  singleton boolean primary key default true check (singleton),
  delivery_enabled boolean not null default false,
  android_opt_in_url text,
  ios_testflight_url text,
  updated_at timestamptz not null default now(),
  updated_by uuid references auth.users (id) on delete set null
);

insert into public.beta_tester_invite_settings (singleton)
values (true)
on conflict (singleton) do nothing;

create table if not exists public.beta_tester_invites (
  id uuid primary key default gen_random_uuid(),
  signup_id uuid not null unique references public.waitlist_signups (id) on delete cascade,
  email text not null,
  platform text not null check (platform in ('android', 'ios')),
  founder_number smallint not null check (founder_number between 1 and 47),
  status text not null default 'queued' check (status in ('queued', 'sending', 'sent', 'failed')),
  provider_message_id text,
  attempt_count integer not null default 0 check (attempt_count >= 0),
  last_attempt_at timestamptz,
  sent_at timestamptz,
  last_error text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists beta_tester_invites_status_idx
  on public.beta_tester_invites (status, created_at desc);

alter table public.beta_tester_invite_settings enable row level security;
alter table public.beta_tester_invites enable row level security;
revoke all on public.beta_tester_invite_settings from public, anon, authenticated;
revoke all on public.beta_tester_invites from public, anon, authenticated;

create or replace function public.queue_beta_tester_invite()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.status = 'approved'
     and new.platform in ('android', 'ios')
     and (
       tg_op = 'INSERT'
       or old.status is distinct from 'approved'
       or old.platform is distinct from new.platform
       or old.founder_number is distinct from new.founder_number
     ) then
    insert into public.beta_tester_invites (
      signup_id, email, platform, founder_number, status, updated_at
    ) values (
      new.id, new.email, new.platform, new.founder_number, 'queued', now()
    )
    on conflict (signup_id) do update
      set email = excluded.email,
          platform = excluded.platform,
          founder_number = excluded.founder_number,
          status = case
            when public.beta_tester_invites.status = 'sent' then 'sent'
            else 'queued'
          end,
          updated_at = now();
  end if;
  return new;
end;
$$;

create or replace function public.approve_waitlist_tester_seat_dashboard(
  p_id uuid,
  p_founder_number smallint,
  p_platform text
)
returns public.waitlist_signups
language plpgsql
security definer
set search_path = public
as $$
declare
  v_platform text := lower(trim(coalesce(p_platform, '')));
  v_row public.waitlist_signups;
begin
  if coalesce(public.current_admin_role() in ('owner', 'admin'), false) is not true then
    raise exception 'Owner or admin access required' using errcode = '42501';
  end if;
  if p_founder_number is null or p_founder_number not between 1 and 47 then
    raise exception 'Choose a founder number (1-47)' using errcode = '22023';
  end if;
  if v_platform not in ('android', 'ios') then
    raise exception 'Choose Android or iPhone for the tester' using errcode = '22023';
  end if;

  update public.waitlist_signups
  set status = 'approved',
      platform = v_platform,
      founder_number = p_founder_number,
      approved_at = coalesce(approved_at, now()),
      updated_at = now()
  where id = p_id
  returning * into v_row;

  if not found then
    raise exception 'Applicant was not found' using errcode = 'P0002';
  end if;
  return v_row;
exception
  when unique_violation then
    raise exception 'Founder number % is already taken', p_founder_number using errcode = '23505';
end;
$$;

drop trigger if exists queue_beta_tester_invite_after_approval on public.waitlist_signups;
create trigger queue_beta_tester_invite_after_approval
after insert or update of status, platform, founder_number on public.waitlist_signups
for each row execute function public.queue_beta_tester_invite();

create or replace function public.award_tester_seat_dashboard(
  p_email text,
  p_founder_number smallint,
  p_platform text
)
returns public.waitlist_signups
language plpgsql
security definer
set search_path = public
as $$
declare
  v_email text := lower(trim(coalesce(p_email, '')));
  v_platform text := lower(trim(coalesce(p_platform, '')));
  v_row public.waitlist_signups;
begin
  if coalesce(public.current_admin_role() in ('owner', 'admin'), false) is not true then
    raise exception 'Owner or admin access required' using errcode = '42501';
  end if;
  if length(v_email) < 5 then
    raise exception 'A valid email is required' using errcode = '22023';
  end if;
  if p_founder_number is null or p_founder_number not between 1 and 47 then
    raise exception 'Choose a founder number (1-47)' using errcode = '22023';
  end if;
  if v_platform not in ('android', 'ios') then
    raise exception 'Choose Android or iPhone for the tester' using errcode = '22023';
  end if;

  insert into public.waitlist_signups (
    email, platform, status, founder_number, approved_at, source
  ) values (
    v_email, v_platform, 'approved', p_founder_number, now(), 'dashboard'
  )
  on conflict (email_key) do update
    set platform = excluded.platform,
        status = 'approved',
        founder_number = excluded.founder_number,
        approved_at = coalesce(public.waitlist_signups.approved_at, now()),
        updated_at = now()
  returning * into v_row;

  return v_row;
exception
  when unique_violation then
    raise exception 'Founder number % is already taken', p_founder_number using errcode = '23505';
end;
$$;

create or replace function public.get_beta_tester_invite_settings_dashboard()
returns table (
  delivery_enabled boolean,
  android_opt_in_url text,
  ios_testflight_url text,
  updated_at timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
begin
  if coalesce(public.current_admin_role() in ('owner', 'admin'), false) is not true then
    raise exception 'Owner or admin access required' using errcode = '42501';
  end if;
  return query
    select s.delivery_enabled, s.android_opt_in_url, s.ios_testflight_url, s.updated_at
    from public.beta_tester_invite_settings s
    where s.singleton;
end;
$$;

create or replace function public.set_beta_tester_invite_settings_dashboard(
  p_delivery_enabled boolean,
  p_android_opt_in_url text,
  p_ios_testflight_url text
)
returns table (
  delivery_enabled boolean,
  android_opt_in_url text,
  ios_testflight_url text,
  updated_at timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_android text := nullif(trim(coalesce(p_android_opt_in_url, '')), '');
  v_ios text := nullif(trim(coalesce(p_ios_testflight_url, '')), '');
begin
  if coalesce(public.current_admin_role() in ('owner', 'admin'), false) is not true then
    raise exception 'Owner or admin access required' using errcode = '42501';
  end if;
  if v_android is not null and v_android !~ '^https://[^[:space:]]+$' then
    raise exception 'Android opt-in URL must use HTTPS' using errcode = '22023';
  end if;
  if v_ios is not null and v_ios !~ '^https://[^[:space:]]+$' then
    raise exception 'TestFlight URL must use HTTPS' using errcode = '22023';
  end if;
  if p_delivery_enabled and (v_android is null or v_ios is null) then
    raise exception 'Add both the Android opt-in and TestFlight links before enabling delivery' using errcode = '22023';
  end if;

  insert into public.beta_tester_invite_settings (
    singleton, delivery_enabled, android_opt_in_url, ios_testflight_url, updated_at, updated_by
  ) values (
    true, coalesce(p_delivery_enabled, false), v_android, v_ios, now(), auth.uid()
  )
  on conflict (singleton) do update
    set delivery_enabled = excluded.delivery_enabled,
        android_opt_in_url = excluded.android_opt_in_url,
        ios_testflight_url = excluded.ios_testflight_url,
        updated_at = excluded.updated_at,
        updated_by = excluded.updated_by;

  return query
    select s.delivery_enabled, s.android_opt_in_url, s.ios_testflight_url, s.updated_at
    from public.beta_tester_invite_settings s
    where s.singleton;
end;
$$;

create or replace function public.get_beta_tester_invite_dashboard(p_signup_id uuid)
returns table (
  status text,
  attempt_count integer,
  sent_at timestamptz,
  last_error text
)
language plpgsql
security definer
set search_path = public
as $$
begin
  if coalesce(public.current_admin_role() in ('owner', 'admin'), false) is not true then
    raise exception 'Owner or admin access required' using errcode = '42501';
  end if;
  return query
    select i.status, i.attempt_count, i.sent_at, i.last_error
    from public.beta_tester_invites i
    where i.signup_id = p_signup_id;
end;
$$;

create or replace function public.claim_beta_tester_invite_dashboard(p_signup_id uuid)
returns table (
  invite_id uuid,
  email text,
  platform text,
  founder_number smallint,
  access_url text
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_signup public.waitlist_signups;
  v_settings public.beta_tester_invite_settings;
  v_invite public.beta_tester_invites;
  v_url text;
begin
  if coalesce(public.current_admin_role() in ('owner', 'admin'), false) is not true then
    raise exception 'Owner or admin access required' using errcode = '42501';
  end if;

  select * into v_signup from public.waitlist_signups where id = p_signup_id for update;
  if not found or v_signup.status <> 'approved' then
    raise exception 'A tester invitation can only be sent after a seat is approved' using errcode = '22023';
  end if;
  if v_signup.platform not in ('android', 'ios') then
    raise exception 'Choose Android or iPhone for this tester before sending an invitation' using errcode = '22023';
  end if;

  select * into v_settings from public.beta_tester_invite_settings where singleton;
  if not coalesce(v_settings.delivery_enabled, false) then
    raise exception 'Tester invitation delivery is disabled in Feature settings' using errcode = '22023';
  end if;
  v_url := case when v_signup.platform = 'android'
    then v_settings.android_opt_in_url else v_settings.ios_testflight_url end;
  if v_url is null then
    raise exception 'The required tester access link has not been configured' using errcode = '22023';
  end if;

  insert into public.beta_tester_invites (
    signup_id, email, platform, founder_number, status, attempt_count, last_attempt_at, last_error, updated_at
  ) values (
    v_signup.id, v_signup.email, v_signup.platform, v_signup.founder_number,
    'sending', 1, now(), null, now()
  )
  on conflict (signup_id) do update
    set email = excluded.email,
        platform = excluded.platform,
        founder_number = excluded.founder_number,
        status = 'sending',
        attempt_count = public.beta_tester_invites.attempt_count + 1,
        last_attempt_at = now(),
        last_error = null,
        updated_at = now()
    where public.beta_tester_invites.status <> 'sending'
  returning * into v_invite;

  if v_invite.id is null then
    raise exception 'An invitation delivery is already in progress' using errcode = '55P03';
  end if;

  return query select v_invite.id, v_signup.email, v_signup.platform, v_signup.founder_number, v_url;
end;
$$;

create or replace function public.record_beta_tester_invite_delivery(
  p_invite_id uuid,
  p_provider_message_id text,
  p_error text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.beta_tester_invites
  set status = case when nullif(trim(coalesce(p_error, '')), '') is null then 'sent' else 'failed' end,
      provider_message_id = nullif(trim(coalesce(p_provider_message_id, '')), ''),
      sent_at = case when nullif(trim(coalesce(p_error, '')), '') is null then now() else null end,
      last_error = nullif(left(trim(coalesce(p_error, '')), 1000), ''),
      updated_at = now()
  where id = p_invite_id and status = 'sending';
end;
$$;

revoke all on function public.award_tester_seat_dashboard(text, smallint, text) from public, anon;
revoke all on function public.approve_waitlist_tester_seat_dashboard(uuid, smallint, text) from public, anon;
revoke all on function public.get_beta_tester_invite_settings_dashboard() from public, anon;
revoke all on function public.set_beta_tester_invite_settings_dashboard(boolean, text, text) from public, anon;
revoke all on function public.get_beta_tester_invite_dashboard(uuid) from public, anon;
revoke all on function public.claim_beta_tester_invite_dashboard(uuid) from public, anon;
revoke all on function public.record_beta_tester_invite_delivery(uuid, text, text) from public, anon, authenticated;
grant execute on function public.award_tester_seat_dashboard(text, smallint, text) to authenticated;
grant execute on function public.approve_waitlist_tester_seat_dashboard(uuid, smallint, text) to authenticated;
grant execute on function public.get_beta_tester_invite_settings_dashboard() to authenticated;
grant execute on function public.set_beta_tester_invite_settings_dashboard(boolean, text, text) to authenticated;
grant execute on function public.get_beta_tester_invite_dashboard(uuid) to authenticated;
grant execute on function public.claim_beta_tester_invite_dashboard(uuid) to authenticated;
grant execute on function public.record_beta_tester_invite_delivery(uuid, text, text) to service_role;
