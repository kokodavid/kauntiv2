-- Public Trips: what the moderation dashboard needs on top of the review,
-- hide, suspend, report and flag operations that already exist. All of it is
-- moderator-only; nothing here is reachable by app users.

-- A non-raising role check, usable in policies and for the dashboard to decide
-- what to show. Same rule as assert_admin: an active, unscoped owner, admin or
-- moderator who is not suspended.
create function public.can_moderate_public_trips()
returns boolean language sql stable security definer set search_path = '' as $$
  select auth.uid() is not null and exists (
    select 1 from public.admin_members m where m.user_id = auth.uid()
      and m.status = 'active' and m.county_scope is null
      and m.role::text in ('owner', 'admin', 'moderator')
      and not exists (select 1 from public.user_moderation_status s
        where s.user_id = m.user_id and s.status = 'suspended'));
$$;
revoke all on function public.can_moderate_public_trips() from public, anon;
grant execute on function public.can_moderate_public_trips() to authenticated;

-- Reviewers must see the sanitized photos they are approving. The bucket stays
-- private with no policy for app users; moderators alone may read it (the
-- dashboard asks for short-lived signed URLs).
do $$
begin
  if to_regclass('storage.objects') is not null then
    execute $p$create policy "Moderators read sanitized public trip photos"
      on storage.objects for select to authenticated
      using (bucket_id = 'public-trip-media' and public.can_moderate_public_trips())$p$;
  end if;
end $$;

-- Sanitized photo files for one revision (ready photos only).
create function public.list_public_trip_review_photos_dashboard(p_publication_id uuid, p_revision integer)
returns jsonb language plpgsql security definer set search_path = '' as $$
begin
  perform public_trip_private.assert_admin();
  return coalesce((select jsonb_agg(jsonb_build_object('id', ph.id, 'path', ph.sanitized_path,
      'width', ph.width, 'height', ph.height, 'latitude', ph.latitude, 'longitude', ph.longitude)
      order by ph.ordinal)
    from public.public_trip_revision_photos ph
    where ph.publication_id = p_publication_id and ph.revision = p_revision
      and ph.status = 'ready' and ph.sanitized_path is not null), '[]'::jsonb);
end $$;

-- The review queue now also tells the reviewer who is behind a submission.
create or replace function public.list_public_trip_reviews_dashboard(p_limit integer default 20,p_before timestamptz default null)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare v_result jsonb;
begin
  perform public_trip_private.assert_admin();
  if p_limit is null or p_limit not between 1 and 50 then raise exception 'Invalid page size' using errcode = '22023'; end if;
  select coalesce(jsonb_agg(item order by submitted_at desc),'[]'::jsonb) into v_result from (
    select public_trip_private.owner_projection(r.publication_id,r.revision)
      || jsonb_build_object('submitted_at',r.submitted_at,
        'moderation', jsonb_build_object('owner_id',p.owner_id,'owner_email',u.email::text,
          'author_suspended',a.suspended,'has_live_revision',p.active_revision is not null,
          'open_reports',(select count(*) from public.public_trip_reports rp
            where rp.publication_id = p.id and rp.state = 'open'))) as item,r.submitted_at
    from public.public_trip_revisions r
    join public.public_trip_publications p on p.id = r.publication_id
    join public.public_trip_authors a on a.user_id = p.owner_id
    left join auth.users u on u.id = p.owner_id
    where r.status = 'submitted' and not p.hidden and r.generation = p.generation
      and (p_before is null or r.submitted_at < p_before)
    order by r.submitted_at desc limit p_limit
  ) q;
  return v_result;
end $$;

-- Browse what is live or hidden, so a moderator can hide a published trip
-- (or allow a hidden one to be submitted again) without waiting for a report.
create function public.list_public_trip_publications_dashboard(p_state text default 'live',p_limit integer default 20)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare v_result jsonb;
begin
  perform public_trip_private.assert_admin();
  if p_state is null or p_state not in ('live','hidden') or p_limit is null or p_limit not between 1 and 50 then
    raise exception 'Invalid state or page size' using errcode = '22023';
  end if;
  select coalesce(jsonb_agg(to_jsonb(q) order by q.sort_at desc),'[]'::jsonb) into v_result from (
    select p.id as publication_id,r.revision,r.title,r.trip_date,r.transport_mode,r.distance_m,r.counties,
      p.hidden,p.active_revision is not null as live,p.owner_id,u.email::text as owner_email,
      qp.display_name as author_name,a.suspended as author_suspended,
      (select count(*) from public.public_trip_reports rp where rp.publication_id = p.id and rp.state = 'open') as open_reports,
      coalesce(r.reviewed_at,r.prepared_at) as sort_at
    from public.public_trip_publications p
    join public.public_trip_authors a on a.user_id = p.owner_id
    left join auth.users u on u.id = p.owner_id
    left join public.quest_public_profiles qp on qp.user_id = p.owner_id
    join lateral (select * from public.public_trip_revisions x where x.publication_id = p.id
      order by (x.revision = p.active_revision) desc,x.revision desc limit 1) r on true
    where case p_state when 'live' then p.active_revision is not null and not p.hidden else p.hidden end
    order by coalesce(r.reviewed_at,r.prepared_at) desc limit p_limit
  ) q;
  return v_result;
end $$;

-- Reports now carry enough context to act on without a lookup. The reporter's
-- identity is still never returned.
create or replace function public.list_public_trip_reports_dashboard(p_limit integer default 20)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare v_result jsonb;
begin
  perform public_trip_private.assert_admin();
  if p_limit is null or p_limit not between 1 and 50 then raise exception 'Invalid page size' using errcode = '22023'; end if;
  select coalesce(jsonb_agg(to_jsonb(q) order by q.created_at,q.id),'[]'::jsonb) into v_result from (
    select rp.id,rp.publication_id,rp.revision,rp.reason,rp.details,rp.created_at,
      r.title,p.hidden,p.active_revision is not null as live,p.owner_id,u.email::text as owner_email,
      qp.display_name as author_name,a.suspended as author_suspended
    from public.public_trip_reports rp
    left join public.public_trip_publications p on p.id = rp.publication_id
    left join public.public_trip_revisions r on r.publication_id = rp.publication_id and r.revision = rp.revision
    left join public.public_trip_authors a on a.user_id = p.owner_id
    left join auth.users u on u.id = p.owner_id
    left join public.quest_public_profiles qp on qp.user_id = p.owner_id
    where rp.state = 'open' order by rp.created_at,rp.id limit p_limit
  ) q;
  return v_result;
end $$;

-- Audit trail, newest first; page with p_before = the last id seen.
create function public.list_public_trip_moderation_events_dashboard(
  p_limit integer default 50,p_before bigint default null,p_publication_id uuid default null)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare v_result jsonb;
begin
  perform public_trip_private.assert_admin();
  if p_limit is null or p_limit not between 1 and 100 then raise exception 'Invalid page size' using errcode = '22023'; end if;
  select coalesce(jsonb_agg(to_jsonb(q) order by q.id desc),'[]'::jsonb) into v_result from (
    select e.id,e.action,e.publication_id,e.revision,e.created_at,e.actor_id,u.email::text as actor_email,
      (select r.title from public.public_trip_revisions r
        where r.publication_id = e.publication_id and r.revision = e.revision) as title
    from public.public_trip_moderation_events e left join auth.users u on u.id = e.actor_id
    where (p_before is null or e.id < p_before)
      and (p_publication_id is null or e.publication_id = p_publication_id)
    order by e.id desc limit p_limit
  ) q;
  return v_result;
end $$;

revoke all on function public.list_public_trip_review_photos_dashboard(uuid,integer),
  public.list_public_trip_publications_dashboard(text,integer),
  public.list_public_trip_moderation_events_dashboard(integer,bigint,uuid) from public, anon, authenticated;
grant execute on function public.list_public_trip_review_photos_dashboard(uuid,integer),
  public.list_public_trip_publications_dashboard(text,integer),
  public.list_public_trip_moderation_events_dashboard(integer,bigint,uuid) to authenticated;
