-- Beta feedback loop (slice 1-5): reports, admin notes, status history and
-- private screenshot storage.
--
-- Access model
--   * A tester is whoever holds an approved seat in `waitlist_signups`
--     (the existing "The 47" flow). `has_tester_seat()` is the only check;
--     nothing here knows the number 47, so widening feedback to every user
--     later is a change inside `submit_feedback`, not a schema change.
--   * Seats are keyed by email. `user_id` links a seat to the signed-in
--     account the first time it is used, so a later email change keeps access.
--   * Reports reach the server only through `submit_feedback` (a security
--     definer function that re-validates ownership, seat, lengths and a daily
--     cap). There is no client insert/update policy on any feedback table.
--   * Admin notes and status history live in their own tables with no user
--     policy, so a submitter can never read internal notes. The only text a
--     tester sees from staff is `feedback_reports.tester_response`.
--   * Admin access is explicit (owner/admin RPCs, same check as the waitlist
--     functions): there is deliberately no broad admin table policy. Reports
--     hold device details and optional contact consent.
--   * Screenshots use a private bucket (`feedback-media`, public: false) with
--     folder-owner RLS plus a read policy for owner/admin so the dashboard can
--     sign preview URLs. Size and type limits are set on the bucket itself.

alter table public.waitlist_signups
  add column if not exists user_id uuid references auth.users (id) on delete set null;

create unique index if not exists waitlist_signups_user_id_unique
  on public.waitlist_signups (user_id)
  where user_id is not null;

create or replace function public.has_tester_seat()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.waitlist_signups w
    where w.status = 'approved'
      and (
        w.user_id = auth.uid()
        or w.email_key = lower(coalesce(auth.jwt() ->> 'email', ''))
      )
  );
$$;

create or replace function public.can_manage_feedback()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(public.current_admin_role() in ('owner', 'admin'), false);
$$;

create table if not exists public.feedback_reports (
  id uuid primary key default gen_random_uuid(),
  number bigint generated always as identity,
  reference text,
  user_id uuid not null references auth.users (id) on delete cascade,
  client_id uuid,
  source text not null default 'beta_tester'
    check (source in ('beta_tester', 'general_user')),
  category text not null
    check (category in ('bug', 'feature_idea', 'content_issue', 'performance', 'usability')),
  severity text not null
    check (severity in ('blocking', 'major', 'minor')),
  title text not null check (length(title) between 3 and 120),
  description text not null check (length(description) between 10 and 4000),
  screen text check (screen is null or length(screen) <= 200),
  app_version text check (app_version is null or length(app_version) <= 40),
  build_number text check (build_number is null or length(build_number) <= 40),
  flavor text check (flavor is null or length(flavor) <= 20),
  platform text check (platform is null or length(platform) <= 20),
  os_version text check (os_version is null or length(os_version) <= 60),
  device_model text check (device_model is null or length(device_model) <= 80),
  locale text check (locale is null or length(locale) <= 20),
  contact_ok boolean not null default false,
  status text not null default 'received'
    check (status in (
      'received', 'triaged', 'investigating', 'planned',
      'resolved', 'closed', 'rejected', 'duplicate'
    )),
  duplicate_of uuid references public.feedback_reports (id) on delete set null,
  assigned_to uuid references auth.users (id) on delete set null,
  tester_response text check (tester_response is null or length(tester_response) <= 2000),
  responded_at timestamptz,
  resolved_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint feedback_reports_number_unique unique (number),
  constraint feedback_reports_client_unique unique (user_id, client_id),
  constraint feedback_reports_duplicate_needs_target
    check (status <> 'duplicate' or duplicate_of is not null)
);

create index if not exists feedback_reports_status_created_idx
  on public.feedback_reports (status, created_at desc);
create index if not exists feedback_reports_user_created_idx
  on public.feedback_reports (user_id, created_at desc);

create table if not exists public.feedback_notes (
  id uuid primary key default gen_random_uuid(),
  report_id uuid not null references public.feedback_reports (id) on delete cascade,
  author_id uuid references auth.users (id) on delete set null,
  body text not null check (length(body) between 1 and 4000),
  created_at timestamptz not null default now()
);
create index if not exists feedback_notes_report_idx
  on public.feedback_notes (report_id, created_at);

create table if not exists public.feedback_status_history (
  id uuid primary key default gen_random_uuid(),
  report_id uuid not null references public.feedback_reports (id) on delete cascade,
  from_status text,
  to_status text not null,
  changed_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now()
);
create index if not exists feedback_status_history_report_idx
  on public.feedback_status_history (report_id, created_at);

create table if not exists public.feedback_attachments (
  id uuid primary key default gen_random_uuid(),
  report_id uuid not null references public.feedback_reports (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  storage_path text not null unique,
  kind text not null check (kind in ('image', 'video')),
  mime_type text not null,
  size_bytes bigint not null check (size_bytes > 0 and size_bytes <= 52428800),
  created_at timestamptz not null default now()
);
create index if not exists feedback_attachments_report_idx
  on public.feedback_attachments (report_id);

alter table public.feedback_reports enable row level security;
alter table public.feedback_notes enable row level security;
alter table public.feedback_status_history enable row level security;
alter table public.feedback_attachments enable row level security;

-- A submitter can read their own reports and attachments, nothing else.
-- Writes happen only in the security definer functions below.
create policy "Users read their own feedback reports"
  on public.feedback_reports for select to authenticated
  using (user_id = auth.uid());

create policy "Users read their own feedback attachments"
  on public.feedback_attachments for select to authenticated
  using (user_id = auth.uid());

revoke all on public.feedback_reports from anon, authenticated;
revoke all on public.feedback_notes from anon, authenticated;
revoke all on public.feedback_status_history from anon, authenticated;
revoke all on public.feedback_attachments from anon, authenticated;
grant select on public.feedback_reports to authenticated;
grant select on public.feedback_attachments to authenticated;

create or replace function public.touch_feedback_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

-- Readable number such as FB-0042. Set before insert so it is never null.
create or replace function public.set_feedback_reference()
returns trigger
language plpgsql
as $$
begin
  new.reference := 'FB-' || lpad(new.number::text, 4, '0');
  return new;
end;
$$;

create trigger feedback_reports_reference
  before insert on public.feedback_reports
  for each row execute function public.set_feedback_reference();

create unique index if not exists feedback_reports_reference_unique
  on public.feedback_reports (reference);

create trigger feedback_reports_touch
  before update on public.feedback_reports
  for each row execute function public.touch_feedback_updated_at();

-- Private bucket for screenshots and short screen recordings.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'feedback-media',
  'feedback-media',
  false,
  52428800,
  array['image/jpeg', 'image/png', 'image/webp', 'video/mp4', 'video/quicktime']
)
on conflict (id) do update
  set public = false,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

create policy "Testers upload their own feedback media"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'feedback-media'
    and (storage.foldername(name))[1] = auth.uid()::text
    and public.has_tester_seat()
  );

create policy "Testers read their own feedback media"
  on storage.objects for select to authenticated
  using (
    bucket_id = 'feedback-media'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "Admins read feedback media"
  on storage.objects for select to authenticated
  using (bucket_id = 'feedback-media' and public.can_manage_feedback());

-- Submit a report. Idempotent per (user, client_id) so an offline retry
-- never creates a duplicate.
create or replace function public.submit_feedback(
  p_category text,
  p_severity text,
  p_title text,
  p_description text,
  p_screen text default null,
  p_app_version text default null,
  p_build_number text default null,
  p_flavor text default null,
  p_platform text default null,
  p_os_version text default null,
  p_device_model text default null,
  p_locale text default null,
  p_contact_ok boolean default false,
  p_client_id uuid default null
)
returns table (id uuid, reference text)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_title text := btrim(coalesce(p_title, ''));
  v_description text := btrim(coalesce(p_description, ''));
  v_existing public.feedback_reports;
  v_row public.feedback_reports;
begin
  if v_user is null then
    raise exception 'Sign in to send feedback' using errcode = '28000';
  end if;
  if not public.has_tester_seat() then
    raise exception 'Feedback is open to beta testers only' using errcode = '42501';
  end if;
  if p_category not in ('bug', 'feature_idea', 'content_issue', 'performance', 'usability') then
    raise exception 'Unknown category' using errcode = '22023';
  end if;
  if p_severity not in ('blocking', 'major', 'minor') then
    raise exception 'Unknown severity' using errcode = '22023';
  end if;
  if length(v_title) not between 3 and 120 then
    raise exception 'Title must be 3 to 120 characters' using errcode = '22023';
  end if;
  if length(v_description) not between 10 and 4000 then
    raise exception 'Description must be 10 to 4000 characters' using errcode = '22023';
  end if;

  if p_client_id is not null then
    select * into v_existing
    from public.feedback_reports r
    where r.user_id = v_user and r.client_id = p_client_id;
    if found then
      return query select v_existing.id, v_existing.reference;
      return;
    end if;
  end if;

  if (
    select count(*) from public.feedback_reports r
    where r.user_id = v_user and r.created_at > now() - interval '24 hours'
  ) >= 20 then
    raise exception 'Daily feedback limit reached. Try again tomorrow.' using errcode = '54000';
  end if;

  -- Remember which account holds the seat, so the link survives an email change.
  update public.waitlist_signups w
  set user_id = v_user
  where w.user_id is null
    and w.status = 'approved'
    and w.email_key = lower(coalesce(auth.jwt() ->> 'email', ''))
    and not exists (select 1 from public.waitlist_signups o where o.user_id = v_user);

  insert into public.feedback_reports (
    user_id, client_id, source, category, severity, title, description,
    screen, app_version, build_number, flavor, platform, os_version,
    device_model, locale, contact_ok
  )
  values (
    v_user, p_client_id, 'beta_tester', p_category, p_severity, v_title, v_description,
    left(p_screen, 200), left(p_app_version, 40), left(p_build_number, 40),
    left(p_flavor, 20), left(p_platform, 20), left(p_os_version, 60),
    left(p_device_model, 80), left(p_locale, 20), coalesce(p_contact_ok, false)
  )
  returning * into v_row;

  insert into public.feedback_status_history (report_id, from_status, to_status, changed_by)
  values (v_row.id, null, 'received', v_user);

  return query select v_row.id, v_row.reference;
end;
$$;

-- Register an uploaded file against the caller's own report.
create or replace function public.add_feedback_attachment(
  p_report_id uuid,
  p_storage_path text,
  p_mime_type text,
  p_size_bytes bigint
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_kind text;
  v_id uuid;
begin
  if v_user is null or not public.has_tester_seat() then
    raise exception 'Feedback is open to beta testers only' using errcode = '42501';
  end if;
  if not exists (
    select 1 from public.feedback_reports r where r.id = p_report_id and r.user_id = v_user
  ) then
    raise exception 'Report not found' using errcode = 'P0002';
  end if;
  if (storage.foldername(p_storage_path))[1] is distinct from v_user::text then
    raise exception 'Invalid file path' using errcode = '22023';
  end if;
  if p_mime_type in ('image/jpeg', 'image/png', 'image/webp') then
    v_kind := 'image';
  elsif p_mime_type in ('video/mp4', 'video/quicktime') then
    v_kind := 'video';
  else
    raise exception 'Unsupported file type' using errcode = '22023';
  end if;
  if (
    select count(*) from public.feedback_attachments a where a.report_id = p_report_id
  ) >= 3 then
    raise exception 'A report can have up to 3 files' using errcode = '54000';
  end if;

  insert into public.feedback_attachments (report_id, user_id, storage_path, kind, mime_type, size_bytes)
  values (p_report_id, v_user, p_storage_path, v_kind, p_mime_type, p_size_bytes)
  returning id into v_id;
  return v_id;
end;
$$;

-- ----------------------------------------------------------------------
-- Dashboard functions. Owner/admin only; each re-checks the role itself.
-- ----------------------------------------------------------------------

create or replace function public.list_feedback_dashboard(
  p_status text default null,
  p_source text default null
)
returns table (
  id uuid,
  reference text,
  source text,
  category text,
  severity text,
  title text,
  status text,
  screen text,
  app_version text,
  platform text,
  submitter_email text,
  founder_number smallint,
  assigned_to uuid,
  assigned_email text,
  duplicate_of uuid,
  duplicate_reference text,
  attachment_count bigint,
  note_count bigint,
  created_at timestamptz,
  updated_at timestamptz
)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not public.can_manage_feedback() then
    raise exception 'Owner or admin access required' using errcode = '42501';
  end if;
  return query
  select r.id, r.reference, r.source, r.category, r.severity, r.title, r.status,
         r.screen, r.app_version, r.platform,
         u.email::text,
         (select w.founder_number from public.waitlist_signups w
           where w.user_id = r.user_id limit 1),
         r.assigned_to, a.email::text,
         r.duplicate_of, d.reference,
         (select count(*) from public.feedback_attachments x where x.report_id = r.id),
         (select count(*) from public.feedback_notes n where n.report_id = r.id),
         r.created_at, r.updated_at
  from public.feedback_reports r
  left join auth.users u on u.id = r.user_id
  left join auth.users a on a.id = r.assigned_to
  left join public.feedback_reports d on d.id = r.duplicate_of
  where (p_status is null or r.status = p_status)
    and (p_source is null or r.source = p_source)
  order by r.created_at desc
  limit 500;
end;
$$;

create or replace function public.get_feedback_dashboard(p_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_report jsonb;
begin
  if not public.can_manage_feedback() then
    raise exception 'Owner or admin access required' using errcode = '42501';
  end if;
  select to_jsonb(r) || jsonb_build_object(
           'submitter_email', u.email,
           'assigned_email', a.email,
           'duplicate_reference', d.reference,
           'founder_number', (select w.founder_number from public.waitlist_signups w
                               where w.user_id = r.user_id limit 1)
         )
    into v_report
  from public.feedback_reports r
  left join auth.users u on u.id = r.user_id
  left join auth.users a on a.id = r.assigned_to
  left join public.feedback_reports d on d.id = r.duplicate_of
  where r.id = p_id;
  if v_report is null then
    raise exception 'Report not found' using errcode = 'P0002';
  end if;
  return jsonb_build_object(
    'report', v_report,
    'notes', coalesce((
      select jsonb_agg(jsonb_build_object(
               'id', n.id, 'body', n.body, 'created_at', n.created_at,
               'author_email', au.email)
             order by n.created_at)
      from public.feedback_notes n
      left join auth.users au on au.id = n.author_id
      where n.report_id = p_id), '[]'::jsonb),
    'history', coalesce((
      select jsonb_agg(jsonb_build_object(
               'id', h.id, 'from_status', h.from_status, 'to_status', h.to_status,
               'created_at', h.created_at, 'changed_by_email', hu.email)
             order by h.created_at)
      from public.feedback_status_history h
      left join auth.users hu on hu.id = h.changed_by
      where h.report_id = p_id), '[]'::jsonb),
    'attachments', coalesce((
      select jsonb_agg(jsonb_build_object(
               'id', x.id, 'storage_path', x.storage_path, 'kind', x.kind,
               'mime_type', x.mime_type, 'size_bytes', x.size_bytes)
             order by x.created_at)
      from public.feedback_attachments x
      where x.report_id = p_id), '[]'::jsonb)
  );
end;
$$;

create or replace function public.set_feedback_status_dashboard(
  p_id uuid,
  p_status text,
  p_duplicate_of uuid default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_old text;
begin
  if not public.can_manage_feedback() then
    raise exception 'Owner or admin access required' using errcode = '42501';
  end if;
  if p_status not in (
    'received', 'triaged', 'investigating', 'planned',
    'resolved', 'closed', 'rejected', 'duplicate'
  ) then
    raise exception 'Unknown status' using errcode = '22023';
  end if;
  if p_status = 'duplicate' then
    if p_duplicate_of is null or p_duplicate_of = p_id then
      raise exception 'Choose the original report' using errcode = '22023';
    end if;
    if not exists (select 1 from public.feedback_reports where id = p_duplicate_of) then
      raise exception 'Original report not found' using errcode = 'P0002';
    end if;
  end if;

  select status into v_old from public.feedback_reports where id = p_id for update;
  if not found then
    raise exception 'Report not found' using errcode = 'P0002';
  end if;

  update public.feedback_reports
  set status = p_status,
      duplicate_of = case when p_status = 'duplicate' then p_duplicate_of else null end,
      resolved_at = case
        when p_status in ('resolved', 'closed') then coalesce(resolved_at, now())
        else null
      end
  where id = p_id;

  if v_old is distinct from p_status then
    insert into public.feedback_status_history (report_id, from_status, to_status, changed_by)
    values (p_id, v_old, p_status, auth.uid());
  end if;
end;
$$;

create or replace function public.add_feedback_note_dashboard(p_id uuid, p_body text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.can_manage_feedback() then
    raise exception 'Owner or admin access required' using errcode = '42501';
  end if;
  if length(btrim(coalesce(p_body, ''))) = 0 then
    raise exception 'Write a note first' using errcode = '22023';
  end if;
  if not exists (select 1 from public.feedback_reports where id = p_id) then
    raise exception 'Report not found' using errcode = 'P0002';
  end if;
  insert into public.feedback_notes (report_id, author_id, body)
  values (p_id, auth.uid(), btrim(p_body));
end;
$$;

-- The one line of text a tester sees from staff. Empty clears it.
create or replace function public.respond_feedback_dashboard(p_id uuid, p_response text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_text text := nullif(btrim(coalesce(p_response, '')), '');
begin
  if not public.can_manage_feedback() then
    raise exception 'Owner or admin access required' using errcode = '42501';
  end if;
  if v_text is not null and length(v_text) > 2000 then
    raise exception 'Keep the response under 2000 characters' using errcode = '22023';
  end if;
  update public.feedback_reports
  set tester_response = v_text,
      responded_at = case when v_text is null then null else now() end
  where id = p_id;
  if not found then
    raise exception 'Report not found' using errcode = 'P0002';
  end if;
end;
$$;

create or replace function public.assign_feedback_dashboard(p_id uuid, p_assignee uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.can_manage_feedback() then
    raise exception 'Owner or admin access required' using errcode = '42501';
  end if;
  if p_assignee is not null and not exists (
    select 1 from public.admin_members m
    where m.user_id = p_assignee and m.status = 'active'
  ) then
    raise exception 'Assignee must be an active admin' using errcode = '22023';
  end if;
  update public.feedback_reports set assigned_to = p_assignee where id = p_id;
  if not found then
    raise exception 'Report not found' using errcode = 'P0002';
  end if;
end;
$$;

create or replace function public.list_feedback_assignees_dashboard()
returns table (user_id uuid, email text)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not public.can_manage_feedback() then
    raise exception 'Owner or admin access required' using errcode = '42501';
  end if;
  return query
  select m.user_id, u.email::text
  from public.admin_members m
  join auth.users u on u.id = m.user_id
  where m.status = 'active' and m.role in ('owner', 'admin')
  order by u.email;
end;
$$;

-- Sidebar badge: reports nobody has triaged yet.
create or replace function public.feedback_needing_triage_dashboard()
returns integer
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not public.can_manage_feedback() then
    return 0;
  end if;
  return (select count(*)::integer from public.feedback_reports where status = 'received');
end;
$$;

revoke execute on function public.has_tester_seat() from public, anon;
revoke execute on function public.can_manage_feedback() from public, anon;
revoke execute on function public.submit_feedback(
  text, text, text, text, text, text, text, text, text, text, text, text, boolean, uuid
) from public, anon;
revoke execute on function public.add_feedback_attachment(uuid, text, text, bigint) from public, anon;
revoke execute on function public.list_feedback_dashboard(text, text) from public, anon;
revoke execute on function public.get_feedback_dashboard(uuid) from public, anon;
revoke execute on function public.set_feedback_status_dashboard(uuid, text, uuid) from public, anon;
revoke execute on function public.add_feedback_note_dashboard(uuid, text) from public, anon;
revoke execute on function public.respond_feedback_dashboard(uuid, text) from public, anon;
revoke execute on function public.assign_feedback_dashboard(uuid, uuid) from public, anon;
revoke execute on function public.list_feedback_assignees_dashboard() from public, anon;
revoke execute on function public.feedback_needing_triage_dashboard() from public, anon;

grant execute on function public.has_tester_seat() to authenticated;
grant execute on function public.can_manage_feedback() to authenticated;
grant execute on function public.submit_feedback(
  text, text, text, text, text, text, text, text, text, text, text, text, boolean, uuid
) to authenticated;
grant execute on function public.add_feedback_attachment(uuid, text, text, bigint) to authenticated;
grant execute on function public.list_feedback_dashboard(text, text) to authenticated;
grant execute on function public.get_feedback_dashboard(uuid) to authenticated;
grant execute on function public.set_feedback_status_dashboard(uuid, text, uuid) to authenticated;
grant execute on function public.add_feedback_note_dashboard(uuid, text) to authenticated;
grant execute on function public.respond_feedback_dashboard(uuid, text) to authenticated;
grant execute on function public.assign_feedback_dashboard(uuid, uuid) to authenticated;
grant execute on function public.list_feedback_assignees_dashboard() to authenticated;
grant execute on function public.feedback_needing_triage_dashboard() to authenticated;
