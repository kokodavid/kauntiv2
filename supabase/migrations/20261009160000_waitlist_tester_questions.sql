-- The landing page now takes an email first, then a short set of required
-- questions that help decide who becomes one of the 47 testers. The tester
-- programme itself is not advertised; seats are awarded from the dashboard.

alter table public.waitlist_signups
  alter column platform drop not null,
  add column if not exists base_county text
    check (base_county is null or length(base_county) between 2 and 40),
  add column if not exists counties_visited text
    check (counties_visited is null or counties_visited in ('0-5', '6-15', '16-30', '31-47')),
  add column if not exists travel_frequency text
    check (travel_frequency is null or travel_frequency in ('weekly', 'monthly', 'few_times_year', 'rarely')),
  add column if not exists upcoming_trip text
    check (upcoming_trip is null or upcoming_trip in ('within_4_weeks', 'later_this_year', 'none_planned')),
  add column if not exists accepts_rules boolean,
  add column if not exists answered_at timestamptz;

-- Replaces the earlier five-argument version.
drop function if exists public.join_waitlist(text, text, boolean, text, text)
;

-- Step 1 sends only the email. Step 2 sends the same email with every answer.
-- A repeat call never reveals that an address already exists, and answers can
-- only be changed while the person has not been approved, declined or removed.
create or replace function public.join_waitlist(
  p_email text,
  p_source text default null,
  p_base_county text default null,
  p_platform text default null,
  p_counties_visited text default null,
  p_travel_frequency text default null,
  p_upcoming_trip text default null,
  p_accepts_rules boolean default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_email text := lower(trim(p_email));
  v_platform text := nullif(lower(trim(coalesce(p_platform, ''))), '');
  v_base text := nullif(left(trim(coalesce(p_base_county, '')), 40), '');
  v_has_answers boolean;
  v_recent integer;
begin
  if v_email !~ '^[^\s@]+@[^\s@]+\.[^\s@]+$' or length(v_email) > 254 then
    raise exception 'Enter a valid email address' using errcode = '22023';
  end if;

  v_has_answers := coalesce(
    v_base is not null or v_platform is not null or p_counties_visited is not null
      or p_travel_frequency is not null or p_upcoming_trip is not null
      or p_accepts_rules is not null,
    false
  );

  if v_has_answers then
    if v_base is null or v_platform is null or p_counties_visited is null
       or p_travel_frequency is null or p_upcoming_trip is null
       or p_accepts_rules is not true then
      raise exception 'Please answer every question' using errcode = '22023';
    end if;
    if v_platform not in ('android', 'ios') then
      raise exception 'Pick Android or iPhone' using errcode = '22023';
    end if;
    if p_counties_visited not in ('0-5', '6-15', '16-30', '31-47')
       or p_travel_frequency not in ('weekly', 'monthly', 'few_times_year', 'rarely')
       or p_upcoming_trip not in ('within_4_weeks', 'later_this_year', 'none_planned') then
      raise exception 'Please choose from the options given' using errcode = '22023';
    end if;
  end if;

  -- Flood guard: a burst of signups is more likely a script than a crowd.
  select count(*) into v_recent
  from public.waitlist_signups
  where created_at > now() - interval '1 minute';
  if v_recent >= 60 then
    raise exception 'Too many signups right now, try again shortly'
      using errcode = '54000';
  end if;

  insert into public.waitlist_signups (
    email, platform, wants_beta, status, source,
    base_county, counties_visited, travel_frequency, upcoming_trip,
    accepts_rules, answered_at
  )
  values (
    v_email,
    v_platform,
    v_has_answers,
    case when v_has_answers then 'applied' else 'waitlisted' end,
    nullif(left(trim(coalesce(p_source, '')), 40), ''),
    v_base,
    p_counties_visited,
    p_travel_frequency,
    p_upcoming_trip,
    case when v_has_answers then true else null end,
    case when v_has_answers then now() else null end
  )
  on conflict (email_key) do update
    set platform = case when v_has_answers then excluded.platform
                        else public.waitlist_signups.platform end,
        base_county = case when v_has_answers then excluded.base_county
                           else public.waitlist_signups.base_county end,
        counties_visited = case when v_has_answers then excluded.counties_visited
                                else public.waitlist_signups.counties_visited end,
        travel_frequency = case when v_has_answers then excluded.travel_frequency
                                else public.waitlist_signups.travel_frequency end,
        upcoming_trip = case when v_has_answers then excluded.upcoming_trip
                             else public.waitlist_signups.upcoming_trip end,
        accepts_rules = case when v_has_answers then true
                             else public.waitlist_signups.accepts_rules end,
        answered_at = case when v_has_answers
                           then coalesce(public.waitlist_signups.answered_at, now())
                           else public.waitlist_signups.answered_at end,
        wants_beta = public.waitlist_signups.wants_beta or v_has_answers,
        status = case
          when v_has_answers and public.waitlist_signups.status = 'waitlisted' then 'applied'
          else public.waitlist_signups.status
        end,
        updated_at = now()
    where public.waitlist_signups.status in ('waitlisted', 'applied')
       or not v_has_answers;

  return jsonb_build_object('ok', true, 'answered', v_has_answers);
end;
$$;

revoke all on function public.join_waitlist(text, text, text, text, text, text, text, boolean)
  from public, anon, authenticated;
grant execute on function public.join_waitlist(text, text, text, text, text, text, text, boolean)
  to service_role;

-- Dashboard list now carries the answers. Return type changed, so recreate.
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
  approved_at timestamptz
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
         w.upcoming_trip, w.accepts_rules, w.answered_at, w.created_at, w.approved_at
  from public.waitlist_signups w
  where p_status is null or w.status = p_status
  order by w.created_at desc;
end;
$$;

revoke all on function public.list_waitlist_dashboard(text) from public, anon;
grant execute on function public.list_waitlist_dashboard(text) to authenticated;
