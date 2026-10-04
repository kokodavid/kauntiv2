create function public.get_public_trip(p_publication_id uuid)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare v_result jsonb;
begin
  perform public_trip_private.assert_member('read');
  perform public_trip_private.rate_limit('detail',60,'minute');
  select public_trip_private.projection(p.id,p.active_revision) into v_result
    from public.public_trip_publications p where p.id = p_publication_id
      and public_trip_private.can_view(p.id);
  return v_result;
end $$;

-- A ranked list for the Home row: trips starting within 150 km of the chosen
-- county's centroid (never live coordinates), most unclaimed counties first.
-- Deduplication, author caps and pagination are Phase 2.
create function public.public_trips_for_you(p_county_code smallint, p_limit integer default 10)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare v_user uuid := public_trip_private.assert_member('read'); v_result jsonb;
begin
  perform public_trip_private.rate_limit('recommendation',60,'minute');
  if p_county_code is null or not exists (select 1 from public.counties where id = p_county_code) then
    raise exception 'Choose a valid county' using errcode = '22023';
  end if;
  if p_limit is null or p_limit not between 1 and 20 then
    raise exception 'Invalid page size' using errcode = '22023';
  end if;
  select coalesce(jsonb_agg(q.item order by q.unclaimed desc, q.reviewed_at desc, q.id), '[]'::jsonb)
    into v_result
  from (
    select public_trip_private.projection(p.id,r.revision)
      || jsonb_build_object('unclaimed_counties',score.unclaimed) as item,
      score.unclaimed, r.reviewed_at, p.id
    from public.public_trip_publications p
    join public.public_trip_revisions r on r.publication_id = p.id and r.revision = p.active_revision
    join public.counties c on c.id = p_county_code
    cross join lateral (
      select count(*) as unclaimed from jsonb_array_elements(r.counties) co
      where not exists (select 1 from public.county_visits v where v.user_id = v_user
        and v.county_id = (co->>'code')::smallint and v.state = 'explored')
    ) score
    where p.owner_id <> v_user and public_trip_private.can_view(p.id)
      and extensions.st_dwithin(c.centroid::extensions.geography,
        extensions.st_setsrid(extensions.st_makepoint(
          (r.route#>>'{coordinates,0,0,0}')::double precision,
          (r.route#>>'{coordinates,0,0,1}')::double precision),4326)::extensions.geography,150000)
    order by score.unclaimed desc, r.reviewed_at desc, p.id limit p_limit
  ) q;
  return v_result;
end $$;

create function public.block_public_trip_author(p_author_id uuid,p_blocked boolean)
returns void language plpgsql security definer set search_path = '' as $$
begin
  -- Blocking and unblocking stay available during a feature outage.
  if auth.uid() is null then raise exception 'Sign in required' using errcode = '42501'; end if;
  if p_author_id is null or p_blocked is null or not exists (
    select 1 from public.public_trip_authors where author_id = p_author_id
  ) then raise exception 'Author unavailable' using errcode = '22023'; end if;
  perform public_trip_private.rate_limit('block',60,'minute');
  if p_blocked then
    insert into public.public_trip_author_blocks(viewer_id,author_id) values (auth.uid(),p_author_id)
      on conflict do nothing;
  else
    delete from public.public_trip_author_blocks where viewer_id = auth.uid() and author_id = p_author_id;
  end if;
end $$;

create function public.report_public_trip(p_publication_id uuid,p_reason text,p_details text default null)
returns uuid language plpgsql security definer set search_path = '' as $$
declare v_user uuid := auth.uid(); v_revision integer; v_author uuid; v_report uuid;
begin
  -- Accept reports even when discovery is switched off, without returning route data.
  if v_user is null or exists (select 1 from public.user_moderation_status
    where user_id = v_user and status = 'suspended') then
    raise exception 'Sign in with an eligible account' using errcode = '42501';
  end if;
  if p_reason is null or p_reason not in ('privacy','restricted_access','misleading','abuse','other')
    or length(p_details) > 500 then raise exception 'Invalid report' using errcode = '22023'; end if;
  select p.active_revision,m.author_id into v_revision,v_author from public.public_trip_publications p
    join public.public_trip_authors m on m.user_id = p.owner_id where p.id = p_publication_id;
  if v_revision is null then raise exception 'Publication unavailable' using errcode = '22023'; end if;
  select id into v_report from public.public_trip_reports where publication_id = p_publication_id
    and reporter_id = v_user and revision = v_revision;
  if found then return v_report; end if;
  perform public_trip_private.rate_limit('report',10,'day');
  insert into public.public_trip_reports(publication_id,revision,reporter_id,author_id,reason,details)
    values (p_publication_id,v_revision,v_user,v_author,p_reason,p_details)
    on conflict (publication_id,reporter_id,revision) do update set publication_id = excluded.publication_id
    returning id into v_report;
  return v_report;
end $$;

create function public.list_public_trip_reports_dashboard(p_limit integer default 20)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare v_result jsonb;
begin
  perform public_trip_private.assert_admin();
  if p_limit is null or p_limit not between 1 and 50 then raise exception 'Invalid page size' using errcode = '22023'; end if;
  select coalesce(jsonb_agg(to_jsonb(q)),'[]'::jsonb) into v_result from (
    select id,publication_id,revision,reason,details,created_at from public.public_trip_reports
      where state = 'open' order by created_at,id limit p_limit
  ) q;
  return v_result;
end $$;

create function public.resolve_public_trip_report_dashboard(p_report_id uuid)
returns void language plpgsql security definer set search_path = '' as $$
declare v_report public.public_trip_reports;
begin
  perform public_trip_private.assert_admin();
  update public.public_trip_reports set state = 'resolved',resolved_at = now()
    where id = p_report_id returning * into v_report;
  if not found then raise exception 'Report unavailable' using errcode = '22023'; end if;
  insert into public.public_trip_moderation_events(actor_id,publication_id,revision,action)
    values (auth.uid(),v_report.publication_id,v_report.revision,'report_resolved');
end $$;

revoke all on function public.get_public_trip(uuid),public.public_trips_for_you(smallint,integer),
  public.block_public_trip_author(uuid,boolean),public.report_public_trip(uuid,text,text),
  public.list_public_trip_reports_dashboard(integer),public.resolve_public_trip_report_dashboard(uuid)
  from public, anon, authenticated;
grant execute on function public.get_public_trip(uuid),public.public_trips_for_you(smallint,integer),
  public.block_public_trip_author(uuid,boolean),public.report_public_trip(uuid,text,text),
  public.list_public_trip_reports_dashboard(integer),public.resolve_public_trip_report_dashboard(uuid)
  to authenticated;
