-- Lets an owner/admin award a tester seat to an existing app user straight from
-- their profile. The person may not be on the waitlist, so this creates the
-- waitlist row when needed and then awards the founder number.

create or replace function public.award_seat_by_email_dashboard(
  p_email text,
  p_founder_number smallint
)
returns public.waitlist_signups
language plpgsql
security definer
set search_path = public
as $$
declare
  v_email text := lower(trim(coalesce(p_email, '')));
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

  insert into public.waitlist_signups (email, status, founder_number, approved_at, source)
  values (v_email, 'approved', p_founder_number, now(), 'dashboard')
  on conflict (email_key) do update
    set status = 'approved',
        founder_number = excluded.founder_number,
        approved_at = coalesce(public.waitlist_signups.approved_at, now()),
        updated_at = now()
  returning * into v_row;

  return v_row;
exception
  when unique_violation then
    raise exception 'Founder number % is already taken', p_founder_number
      using errcode = '23505';
end;
$$;

revoke all on function public.award_seat_by_email_dashboard(text, smallint) from public, anon;
grant execute on function public.award_seat_by_email_dashboard(text, smallint) to authenticated;
