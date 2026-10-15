-- Place lifecycle: a stored publishing status, archiving instead of deleting,
-- and a removal-request queue for editors.
--
-- Until now `places` had no delete policy, so the dashboard's "Delete this
-- place" always failed, and the Draft / Needs review / Reviewed status was
-- derived in the browser (only reviewed_at was stored). This migration:
--   1. stores the status (status) and an archived flag (archived_at, ...),
--   2. hides archived places from everyone who is not a dashboard member
--      (so the app stops showing them),
--   3. adds role-checked functions: owner/admin archive, restore and decide
--      removal requests; editors request removal; owner alone hard-deletes
--      an already archived place.
-- Visibility of draft / needs-review places in the app is NOT changed here.

-- 1. Columns ---------------------------------------------------------------
alter table public.places
  add column if not exists status text,
  add column if not exists archived_at timestamptz,
  add column if not exists archived_by uuid references auth.users (id) on delete set null,
  add column if not exists archive_reason text;

-- Backfill using the same rules the dashboard used to derive the status.
update public.places p
set status = case
  when p.reviewed_at is not null then 'reviewed'
  when p.content_origin = 'seed_migration' then 'needs_review'
  when p.summary is null
    or p.lat is null
    or p.lng is null
    or not exists (select 1 from public.place_images i where i.place_id = p.id) then 'draft'
  else 'needs_review'
end
where p.status is null;

alter table public.places
  alter column status set default 'draft',
  alter column status set not null;

alter table public.places
  drop constraint if exists places_status_check;
alter table public.places
  add constraint places_status_check check (status in ('draft', 'needs_review', 'reviewed'));

create index if not exists places_archived_at_idx on public.places (archived_at)
  where archived_at is not null;

comment on column public.places.status is
  'Publishing status set from the dashboard: draft, needs_review or reviewed. reviewed_at is kept in step with it.';
comment on column public.places.archived_at is
  'Set when an owner/admin removes the place. Archived places are hidden from the app; only dashboard members can read them.';

-- 2. Archived places are hidden from non-admins ----------------------------
drop policy if exists "Anyone signed in can read places" on public.places;

create policy "Signed in users read live places, admins read all"
  on public.places
  for select
  to authenticated
  using (archived_at is null or public.current_admin_role() is not null);

-- 3. Removal requests --------------------------------------------------------
create table if not exists public.place_removal_requests (
  id uuid primary key default gen_random_uuid(),
  place_id uuid not null references public.places (id) on delete cascade,
  requested_by uuid not null references auth.users (id) on delete cascade,
  reason text not null check (char_length(btrim(reason)) between 3 and 1000),
  status text not null default 'pending' check (status in ('pending', 'approved', 'declined')),
  decided_by uuid references auth.users (id) on delete set null,
  decided_at timestamptz,
  decision_note text,
  created_at timestamptz not null default now()
);

create unique index if not exists place_removal_requests_one_pending
  on public.place_removal_requests (place_id)
  where status = 'pending';

alter table public.place_removal_requests enable row level security;

create policy "Dashboard members read removal requests"
  on public.place_removal_requests
  for select
  to authenticated
  using (public.current_admin_role() is not null);

-- No insert/update/delete policies: all writes go through the functions below.
revoke all on public.place_removal_requests from anon, authenticated;
grant select on public.place_removal_requests to authenticated;

-- 4. Status ------------------------------------------------------------------
create or replace function public.set_place_status_dashboard(
  p_place_id uuid,
  p_status text
)
returns public.places
language plpgsql
security definer
set search_path = public
as $$
declare
  v_place public.places;
begin
  if public.current_admin_role() not in ('owner', 'admin', 'editor') then
    raise exception 'Changing a place status requires owner, admin, or editor access'
      using errcode = '42501';
  end if;
  if p_status not in ('draft', 'needs_review', 'reviewed') then
    raise exception 'Unknown status %', p_status using errcode = '22023';
  end if;

  update public.places
  set status = p_status,
      reviewed_at = case
        when p_status = 'reviewed' then coalesce(reviewed_at, now())
        else null
      end
  where id = p_place_id
  returning * into v_place;

  if not found then
    raise exception 'Place % was not found', p_place_id using errcode = 'P0002';
  end if;
  return v_place;
end;
$$;

-- Keep the older function consistent with the stored status.
create or replace function public.set_place_reviewed_dashboard(
  p_place_id uuid,
  p_reviewed boolean
)
returns public.places
language plpgsql
security definer
set search_path = public
as $$
declare
  v_place public.places;
begin
  if public.current_admin_role() not in ('owner', 'admin', 'editor') then
    raise exception 'Marking a place reviewed requires owner, admin, or editor access'
      using errcode = '42501';
  end if;
  if p_place_id is null then
    raise exception 'Place id is required' using errcode = '22023';
  end if;

  update public.places
  set reviewed_at = case when p_reviewed then now() else null end,
      status = case when p_reviewed then 'reviewed' else 'needs_review' end
  where id = p_place_id
  returning * into v_place;

  if not found then
    raise exception 'Place % was not found', p_place_id using errcode = 'P0002';
  end if;
  return v_place;
end;
$$;

-- 5. Archive / restore -------------------------------------------------------
create or replace function public.archive_place_dashboard(
  p_place_id uuid,
  p_reason text default null
)
returns public.places
language plpgsql
security definer
set search_path = public
as $$
declare
  v_place public.places;
begin
  if public.current_admin_role() not in ('owner', 'admin') then
    raise exception 'Removing a place requires owner or admin access'
      using errcode = '42501';
  end if;

  update public.places
  set archived_at = now(),
      archived_by = auth.uid(),
      archive_reason = nullif(btrim(coalesce(p_reason, '')), '')
  where id = p_place_id and archived_at is null
  returning * into v_place;

  if not found then
    raise exception 'Place % was not found or is already archived', p_place_id
      using errcode = 'P0002';
  end if;

  -- Close any open request for this place.
  update public.place_removal_requests
  set status = 'approved', decided_by = auth.uid(), decided_at = now(),
      decision_note = 'Place removed directly by an admin'
  where place_id = p_place_id and status = 'pending';

  return v_place;
end;
$$;

create or replace function public.restore_place_dashboard(p_place_id uuid)
returns public.places
language plpgsql
security definer
set search_path = public
as $$
declare
  v_place public.places;
begin
  if public.current_admin_role() not in ('owner', 'admin') then
    raise exception 'Restoring a place requires owner or admin access'
      using errcode = '42501';
  end if;

  update public.places
  set archived_at = null, archived_by = null, archive_reason = null
  where id = p_place_id and archived_at is not null
  returning * into v_place;

  if not found then
    raise exception 'Place % was not found or is not archived', p_place_id
      using errcode = 'P0002';
  end if;
  return v_place;
end;
$$;

-- 6. Removal requests --------------------------------------------------------
create or replace function public.request_place_removal(
  p_place_id uuid,
  p_reason text
)
returns public.place_removal_requests
language plpgsql
security definer
set search_path = public
as $$
declare
  v_request public.place_removal_requests;
begin
  if public.current_admin_role() not in ('owner', 'admin', 'editor') then
    raise exception 'Requesting removal requires owner, admin, or editor access'
      using errcode = '42501';
  end if;
  if not exists (select 1 from public.places where id = p_place_id and archived_at is null) then
    raise exception 'Place % was not found', p_place_id using errcode = 'P0002';
  end if;
  if char_length(btrim(coalesce(p_reason, ''))) < 3 then
    raise exception 'Tell the admins why this place should be removed'
      using errcode = '22023';
  end if;

  begin
    insert into public.place_removal_requests (place_id, requested_by, reason)
    values (p_place_id, auth.uid(), btrim(p_reason))
    returning * into v_request;
  exception when unique_violation then
    raise exception 'A removal request for this place is already waiting for review'
      using errcode = '23505';
  end;

  return v_request;
end;
$$;

create or replace function public.decide_place_removal(
  p_request_id uuid,
  p_approve boolean,
  p_note text default null
)
returns public.place_removal_requests
language plpgsql
security definer
set search_path = public
as $$
declare
  v_request public.place_removal_requests;
begin
  if public.current_admin_role() not in ('owner', 'admin') then
    raise exception 'Deciding a removal request requires owner or admin access'
      using errcode = '42501';
  end if;

  select * into v_request
  from public.place_removal_requests
  where id = p_request_id and status = 'pending'
  for update;

  if not found then
    raise exception 'That request was not found or has already been decided'
      using errcode = 'P0002';
  end if;

  if p_approve then
    update public.places
    set archived_at = coalesce(archived_at, now()),
        archived_by = coalesce(archived_by, auth.uid()),
        archive_reason = coalesce(archive_reason, v_request.reason)
    where id = v_request.place_id;
  end if;

  update public.place_removal_requests
  set status = case when p_approve then 'approved' else 'declined' end,
      decided_by = auth.uid(),
      decided_at = now(),
      decision_note = nullif(btrim(coalesce(p_note, '')), '')
  where id = p_request_id
  returning * into v_request;

  return v_request;
end;
$$;

-- 7. Permanent delete (owner only, archived places only) ---------------------
create or replace function public.delete_place_permanently(p_place_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if public.current_admin_role() <> 'owner' then
    raise exception 'Only an owner can permanently delete a place'
      using errcode = '42501';
  end if;
  if not exists (select 1 from public.places where id = p_place_id and archived_at is not null) then
    raise exception 'Archive the place first; only archived places can be permanently deleted'
      using errcode = '22023';
  end if;

  delete from public.places where id = p_place_id;
end;
$$;

-- 8. Grants --------------------------------------------------------------------
revoke all on function public.set_place_status_dashboard(uuid, text) from public;
revoke all on function public.archive_place_dashboard(uuid, text) from public;
revoke all on function public.restore_place_dashboard(uuid) from public;
revoke all on function public.request_place_removal(uuid, text) from public;
revoke all on function public.decide_place_removal(uuid, boolean, text) from public;
revoke all on function public.delete_place_permanently(uuid) from public;

grant execute on function public.set_place_status_dashboard(uuid, text) to authenticated;
grant execute on function public.archive_place_dashboard(uuid, text) to authenticated;
grant execute on function public.restore_place_dashboard(uuid) to authenticated;
grant execute on function public.request_place_removal(uuid, text) to authenticated;
grant execute on function public.decide_place_removal(uuid, boolean, text) to authenticated;
grant execute on function public.delete_place_permanently(uuid) to authenticated;
