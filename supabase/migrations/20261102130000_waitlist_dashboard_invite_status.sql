-- The dashboard needs to know who has already been invited, so invited
-- applicants can leave "To review" and carry an "Invited" chip.
drop function if exists public.list_waitlist_dashboard(text);

create or replace function public.list_waitlist_dashboard(p_status text default null)
returns table (
  id uuid,
  email text,
  display_name text,
  platform text,
  status text,
  founder_number smallint,
  founder_numeral text,
  founder_display text,
  base_county text,
  counties_visited text,
  travel_frequency text,
  upcoming_trip text,
  accepts_rules boolean,
  answered_at timestamptz,
  created_at timestamptz,
  approved_at timestamptz,
  invite_status text,
  invited_at timestamptz
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
  select w.id, w.email, w.display_name, w.platform, w.status,
         w.founder_number, public.founder_numeral(w.founder_number::integer),
         w.founder_display, w.base_county, w.counties_visited, w.travel_frequency,
         w.upcoming_trip, w.accepts_rules, w.answered_at, w.created_at, w.approved_at,
         i.status, i.sent_at
  from public.waitlist_signups w
  left join public.beta_tester_invites i on i.signup_id = w.id
  where p_status is null or w.status = p_status
  order by w.created_at desc;
end;
$$;

revoke all on function public.list_waitlist_dashboard(text) from public, anon;
grant execute on function public.list_waitlist_dashboard(text) to authenticated;
