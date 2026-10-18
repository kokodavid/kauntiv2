-- My photos (Profile): everything the signed-in user needs to see and manage
-- their own place-photo submissions across all places.
--
--   * result_seen_at: when the user last looked at a reviewed submission. A
--     reviewed row with no result_seen_at is "unseen" and drives the blue dot
--     on Profile, on My photos and on the place page chip.
--   * dismissed_at: a Not published row the user has cleared. Rejected rows
--     also stop showing 30 days after they were reviewed.
--   * withdraw: the user takes back a photo that is still waiting. The row is
--     deleted here; the app then removes the two private files (the user
--     already has delete rights on their own folder).
-- All writes go through these functions; the table still has no client write
-- policy.

alter table public.place_photo_submissions
  add column if not exists dismissed_at timestamptz,
  add column if not exists result_seen_at timestamptz;

drop function if exists public.my_place_photo_submissions(uuid);

create function public.my_place_photo_submissions(
  p_place_id uuid default null
)
returns table (
  id uuid,
  place_id uuid,
  place_name text,
  county_name text,
  status text,
  reject_reason text,
  caption text,
  thumb_path text,
  published_thumbnail_url text,
  shown boolean,
  unseen boolean,
  created_at timestamptz,
  reviewed_at timestamptz
)
language sql
stable
security definer
set search_path = public
as $$
  select
    s.id,
    s.place_id,
    p.name,
    c.name,
    s.status,
    s.reject_reason,
    s.caption,
    case when s.status = 'pending' then s.thumb_path else null end,
    i.thumbnail_url,
    (s.status <> 'approved' or s.image_id is not null),
    (s.status <> 'pending' and s.result_seen_at is null),
    s.created_at,
    s.reviewed_at
  from public.place_photo_submissions s
  join public.places p on p.id = s.place_id
  left join public.counties c on c.id = p.county_id
  left join public.place_images i on i.id = s.image_id
  where s.user_id = auth.uid()
    and (p_place_id is null or s.place_id = p_place_id)
    and s.dismissed_at is null
    and not (
      s.status = 'rejected'
      and coalesce(s.reviewed_at, s.created_at) < now() - interval '30 days'
    )
  order by s.created_at desc
  limit 100;
$$;

revoke all on function public.my_place_photo_submissions(uuid) from public, anon;
grant execute on function public.my_place_photo_submissions(uuid) to authenticated;

create or replace function public.unseen_place_photo_count()
returns integer
language sql
stable
security definer
set search_path = public
as $$
  select count(*)::integer
  from public.place_photo_submissions s
  where s.user_id = auth.uid()
    and s.status <> 'pending'
    and s.result_seen_at is null
    and s.dismissed_at is null
    and not (
      s.status = 'rejected'
      and coalesce(s.reviewed_at, s.created_at) < now() - interval '30 days'
    );
$$;

revoke all on function public.unseen_place_photo_count() from public, anon;
grant execute on function public.unseen_place_photo_count() to authenticated;

create or replace function public.mark_place_photo_results_seen()
returns void
language sql
security definer
set search_path = public
as $$
  update public.place_photo_submissions
  set result_seen_at = now()
  where user_id = auth.uid()
    and status <> 'pending'
    and result_seen_at is null;
$$;

revoke all on function public.mark_place_photo_results_seen() from public, anon;
grant execute on function public.mark_place_photo_results_seen() to authenticated;

create or replace function public.dismiss_place_photo_submission(p_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Sign in first' using errcode = '42501';
  end if;
  update public.place_photo_submissions
  set dismissed_at = now(),
      result_seen_at = coalesce(result_seen_at, now())
  where id = p_id
    and user_id = auth.uid()
    and status = 'rejected';
  if not found then
    raise exception 'Photo not found' using errcode = 'P0002';
  end if;
end;
$$;

revoke all on function public.dismiss_place_photo_submission(uuid) from public, anon;
grant execute on function public.dismiss_place_photo_submission(uuid) to authenticated;

-- Returns the private file paths so the app can remove them.
create or replace function public.withdraw_place_photo_submission(p_id uuid)
returns table (storage_path text, thumb_path text)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_row public.place_photo_submissions;
begin
  if auth.uid() is null then
    raise exception 'Sign in first' using errcode = '42501';
  end if;
  select * into v_row
  from public.place_photo_submissions s
  where s.id = p_id and s.user_id = auth.uid()
  for update;
  if not found then
    raise exception 'Photo not found' using errcode = 'P0002';
  end if;
  if v_row.status <> 'pending' then
    raise exception 'This photo was already reviewed' using errcode = '55000';
  end if;
  delete from public.place_photo_submissions s where s.id = p_id;
  return query select v_row.storage_path, v_row.thumb_path;
end;
$$;

revoke all on function public.withdraw_place_photo_submission(uuid) from public, anon;
grant execute on function public.withdraw_place_photo_submission(uuid) to authenticated;
