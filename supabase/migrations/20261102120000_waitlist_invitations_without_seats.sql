-- General tester invitations do not award or change founder seats.
alter table public.beta_tester_invites alter column founder_number drop not null;

create or replace function public.claim_waitlist_tester_invite_dashboard(
  p_signup_id uuid,
  p_platform text
)
returns table (invite_id uuid, email text, platform text, founder_number smallint, access_url text)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_signup public.waitlist_signups;
  v_settings public.beta_tester_invite_settings;
  v_invite public.beta_tester_invites;
  v_platform text := lower(trim(coalesce(p_platform, '')));
  v_url text;
begin
  if coalesce(public.current_admin_role() in ('owner', 'admin'), false) is not true then
    raise exception 'Owner or admin access required' using errcode = '42501';
  end if;
  if v_platform not in ('android', 'ios') then
    raise exception 'Choose Android or iPhone for this tester' using errcode = '22023';
  end if;

  -- Serialize with seat awards and other invitations for this applicant.
  select * into v_signup from public.waitlist_signups where id = p_signup_id for update;
  if not found then
    raise exception 'Applicant was not found' using errcode = 'P0002';
  end if;
  if v_signup.status not in ('waitlisted', 'applied') or v_signup.founder_number is not null then
    raise exception 'Only an open waitlist applicant without a seat can receive this invitation' using errcode = '22023';
  end if;

  select * into v_settings from public.beta_tester_invite_settings where singleton;
  if not coalesce(v_settings.delivery_enabled, false) then
    raise exception 'Tester invitation delivery is disabled in Feature settings' using errcode = '22023';
  end if;
  v_url := case when v_platform = 'android'
    then v_settings.android_opt_in_url else v_settings.ios_testflight_url end;
  if nullif(trim(v_url), '') is null then
    raise exception 'The required tester access link has not been configured' using errcode = '22023';
  end if;

  insert into public.beta_tester_invites (
    signup_id, email, platform, founder_number, status, attempt_count, last_attempt_at, last_error, updated_at
  ) values (
    v_signup.id, v_signup.email, v_platform, null, 'sending', 1, now(), null, now()
  )
  on conflict (signup_id) do update
    set email = excluded.email,
        platform = excluded.platform,
        founder_number = null,
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
  return query select v_invite.id, v_signup.email, v_platform, null::smallint, v_url;
end;
$$;

revoke all on function public.claim_waitlist_tester_invite_dashboard(uuid, text) from public, anon;
grant execute on function public.claim_waitlist_tester_invite_dashboard(uuid, text) to authenticated;
