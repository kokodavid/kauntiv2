-- Queue for the "your report is resolved" email. A report is queued once, when
-- its status first becomes 'resolved'. Sending happens in an edge function and
-- never blocks the app or the dashboard.

create table if not exists public.feedback_resolved_emails (
  report_id uuid primary key references public.feedback_reports (id) on delete cascade,
  status text not null default 'queued'
    check (status in ('queued', 'sending', 'sent', 'failed', 'skipped')),
  attempts smallint not null default 0,
  last_error text,
  provider_message_id text,
  queued_at timestamptz not null default now(),
  claimed_at timestamptz,
  sent_at timestamptz
);

alter table public.feedback_resolved_emails enable row level security;
revoke all on public.feedback_resolved_emails from public, anon, authenticated;

create or replace function public.queue_feedback_resolved_email()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.status = 'resolved' and old.status is distinct from 'resolved' then
    insert into public.feedback_resolved_emails (report_id)
    values (new.id)
    on conflict (report_id) do nothing;
  end if;
  return new;
end;
$$;

drop trigger if exists feedback_reports_queue_resolved_email on public.feedback_reports;
create trigger feedback_reports_queue_resolved_email
  after update of status on public.feedback_reports
  for each row execute function public.queue_feedback_resolved_email();

-- Called by the edge function (service role) and by owners/admins through it.
-- Claims up to p_limit emails that are queued, failed with attempts left, or
-- stuck in 'sending' for over 10 minutes.
create or replace function public.claim_feedback_resolved_emails(p_limit int default 10)
returns table (
  report_id uuid,
  report_number text,
  report_title text,
  category text,
  team_reply text,
  resolved_at timestamptz,
  email text,
  first_name text,
  delivery_enabled boolean
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_enabled boolean;
begin
  if auth.role() <> 'service_role' then
    raise exception 'Service role required' using errcode = '42501';
  end if;
  select s.delivery_enabled into v_enabled
  from public.beta_tester_invite_settings s limit 1;
  if not coalesce(v_enabled, false) then
    return;
  end if;

  return query
  with picked as (
    select q.report_id
    from public.feedback_resolved_emails q
    where q.attempts < 5
      and (q.status in ('queued', 'failed')
        or (q.status = 'sending' and q.claimed_at < now() - interval '10 minutes'))
    order by q.queued_at
    limit greatest(1, least(p_limit, 25))
    for update skip locked
  ), claimed as (
    update public.feedback_resolved_emails q
    set status = 'sending', claimed_at = now(), attempts = q.attempts + 1
    from picked
    where q.report_id = picked.report_id
    returning q.report_id
  )
  select r.id, r.reference, r.title, r.category, r.tester_response, r.resolved_at,
         coalesce(w.email, u.email::text),
         nullif(split_part(btrim(coalesce(w.display_name, '')), ' ', 1), ''),
         true
  from claimed c
  join public.feedback_reports r on r.id = c.report_id
  left join public.waitlist_signups w on w.user_id = r.user_id
  left join auth.users u on u.id = r.user_id;
end;
$$;

create or replace function public.record_feedback_resolved_email(
  p_report_id uuid,
  p_provider_message_id text,
  p_error text,
  p_skipped boolean default false
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.role() <> 'service_role' then
    raise exception 'Service role required' using errcode = '42501';
  end if;
  update public.feedback_resolved_emails
  set status = case
        when p_skipped then 'skipped'
        when p_error is null then 'sent'
        else 'failed'
      end,
      provider_message_id = p_provider_message_id,
      last_error = left(p_error, 500),
      sent_at = case when p_error is null and not p_skipped then now() else sent_at end
  where report_id = p_report_id;
end;
$$;

revoke execute on function public.claim_feedback_resolved_emails(int) from public, anon, authenticated;
revoke execute on function public.record_feedback_resolved_email(uuid, text, text, boolean) from public, anon, authenticated;
grant execute on function public.claim_feedback_resolved_emails(int) to service_role;
grant execute on function public.record_feedback_resolved_email(uuid, text, text, boolean) to service_role;
