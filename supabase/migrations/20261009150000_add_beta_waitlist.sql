-- Landing-page waitlist and "The 47" closed-beta seats.
-- Signups arrive through the join-waitlist edge function (service role).
-- The page reads only the seat counter, through get_beta_seat_status().

create table if not exists public.waitlist_signups (
  id uuid primary key default gen_random_uuid(),
  email text not null check (length(email) between 5 and 254),
  email_key text generated always as (lower(trim(email))) stored,
  display_name text check (display_name is null or length(display_name) <= 60),
  platform text not null check (platform in ('android', 'ios')),
  wants_beta boolean not null default false,
  status text not null default 'waitlisted'
    check (status in ('waitlisted', 'applied', 'approved', 'declined', 'forfeited')),
  founder_number smallint check (founder_number between 1 and 47),
  founder_display text not null default 'numeral'
    check (founder_display in ('numeral', 'name')),
  source text check (source is null or length(source) <= 40),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  approved_at timestamptz,
  constraint waitlist_signups_email_key_unique unique (email_key),
  constraint waitlist_signups_founder_number_unique unique (founder_number),
  constraint waitlist_signups_number_needs_approval
    check (founder_number is null or status = 'approved')
);

create index if not exists waitlist_signups_status_created_idx
  on public.waitlist_signups (status, created_at);

alter table public.waitlist_signups enable row level security;
revoke all on public.waitlist_signups from public, anon, authenticated;

-- 12 -> 'XII'. Founder numbers are 1..47, so a short lookup is enough.
create or replace function public.founder_numeral(n integer)
returns text
language plpgsql
immutable
as $$
declare
  vals integer[] := array[40, 10, 9, 5, 4, 1];
  syms text[] := array['XL', 'X', 'IX', 'V', 'IV', 'I'];
  out text := '';
  i integer;
begin
  if n is null or n < 1 or n > 47 then
    return null;
  end if;
  for i in 1..array_length(vals, 1) loop
    while n >= vals[i] loop
      out := out || syms[i];
      n := n - vals[i];
    end loop;
  end loop;
  return out;
end;
$$;

-- Public seat counter for the landing page.
create or replace function public.get_beta_seat_status()
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select jsonb_build_object(
    'seats_total', 47,
    'seats_taken', count(*) filter (where status = 'approved'),
    'seats_open', 47 - count(*) filter (where status = 'approved')
  )
  from public.waitlist_signups;
$$;

-- Called by the join-waitlist function. A repeat signup never reveals that the
-- address exists; it can only upgrade (waitlisted -> applied), never downgrade.
create or replace function public.join_waitlist(
  p_email text,
  p_platform text,
  p_wants_beta boolean,
  p_name text,
  p_source text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_email text := lower(trim(p_email));
  v_platform text := lower(trim(p_platform));
  v_recent integer;
  v_open boolean;
begin
  if v_email !~ '^[^\s@]+@[^\s@]+\.[^\s@]+$' or length(v_email) > 254 then
    raise exception 'Enter a valid email address' using errcode = '22023';
  end if;
  if v_platform not in ('android', 'ios') then
    raise exception 'Pick Android or iOS' using errcode = '22023';
  end if;

  -- Flood guard: a burst of signups is more likely a script than a crowd.
  select count(*) into v_recent
  from public.waitlist_signups
  where created_at > now() - interval '1 minute';
  if v_recent >= 60 then
    raise exception 'Too many signups right now, try again shortly'
      using errcode = '54000';
  end if;

  v_open := (select count(*) from public.waitlist_signups where status = 'approved') < 47;

  insert into public.waitlist_signups (email, platform, wants_beta, status, display_name, source)
  values (
    v_email,
    v_platform,
    coalesce(p_wants_beta, false),
    case when coalesce(p_wants_beta, false) then 'applied' else 'waitlisted' end,
    nullif(left(trim(coalesce(p_name, '')), 60), ''),
    nullif(left(trim(coalesce(p_source, '')), 40), '')
  )
  on conflict (email_key) do update
    set platform = excluded.platform,
        wants_beta = public.waitlist_signups.wants_beta or excluded.wants_beta,
        status = case
          when public.waitlist_signups.status = 'waitlisted' and excluded.wants_beta
            then 'applied'
          else public.waitlist_signups.status
        end,
        display_name = coalesce(public.waitlist_signups.display_name, excluded.display_name),
        updated_at = now();

  return jsonb_build_object('ok', true, 'beta_open', v_open);
end;
$$;

-- Dashboard: list and decide applications.
create or replace function public.list_waitlist_dashboard(p_status text default null)
returns table (
  id uuid,
  email text,
  display_name text,
  platform text,
  wants_beta boolean,
  status text,
  founder_number smallint,
  founder_numeral text,
  founder_display text,
  created_at timestamptz
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
  select w.id, w.email, w.display_name, w.platform, w.wants_beta, w.status,
         w.founder_number, public.founder_numeral(w.founder_number::integer),
         w.founder_display, w.created_at
  from public.waitlist_signups w
  where p_status is null or w.status = p_status
  order by w.created_at;
end;
$$;

-- Approve with a founder number (1..47), or decline/forfeit. A number is
-- permanent while the seat is held and returns to the pool on forfeit.
create or replace function public.set_waitlist_status_dashboard(
  p_id uuid,
  p_status text,
  p_founder_number smallint default null,
  p_founder_display text default null
)
returns public.waitlist_signups
language plpgsql
security definer
set search_path = public
as $$
declare
  v_row public.waitlist_signups;
begin
  if coalesce(public.current_admin_role() in ('owner', 'admin'), false) is not true then
    raise exception 'Owner or admin access required' using errcode = '42501';
  end if;
  if p_status not in ('waitlisted', 'applied', 'approved', 'declined', 'forfeited') then
    raise exception 'Unknown status %', p_status using errcode = '22023';
  end if;
  if p_status = 'approved' and p_founder_number is null then
    raise exception 'Approving needs a founder number (1-47)' using errcode = '22023';
  end if;

  update public.waitlist_signups
  set status = p_status,
      founder_number = case when p_status = 'approved' then p_founder_number else null end,
      founder_display = coalesce(p_founder_display, founder_display),
      approved_at = case when p_status = 'approved' then coalesce(approved_at, now()) else null end,
      updated_at = now()
  where id = p_id
  returning * into v_row;

  if not found then
    raise exception 'Signup not found' using errcode = 'P0002';
  end if;
  return v_row;
exception
  when unique_violation then
    raise exception 'Founder number % is already taken', p_founder_number
      using errcode = '23505';
end;
$$;

revoke all on function public.get_beta_seat_status() from public;
grant execute on function public.get_beta_seat_status() to anon, authenticated;

revoke all on function public.join_waitlist(text, text, boolean, text, text)
  from public, anon, authenticated;
grant execute on function public.join_waitlist(text, text, boolean, text, text) to service_role;

revoke all on function public.list_waitlist_dashboard(text) from public, anon;
revoke all on function public.set_waitlist_status_dashboard(uuid, text, smallint, text)
  from public, anon;
grant execute on function public.list_waitlist_dashboard(text) to authenticated;
grant execute on function public.set_waitlist_status_dashboard(uuid, text, smallint, text)
  to authenticated;
