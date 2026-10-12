-- Suspending an author hides all their public trips at once and blocks new
-- submissions. Publishing eligibility otherwise comes from Pro.
create function public.set_public_trip_author_suspended_dashboard(p_user_id uuid,p_suspended boolean)
returns void language plpgsql security definer set search_path = '' as $$
begin
  perform public_trip_private.assert_admin();
  if p_user_id is null or p_suspended is null then
    raise exception 'Explicit author and suspension required' using errcode = '22023';
  end if;
  insert into public.public_trip_authors(user_id,suspended) values (p_user_id,p_suspended)
    on conflict (user_id) do update set suspended = excluded.suspended;
  insert into public.public_trip_moderation_events(actor_id,action)
    values (auth.uid(),case when p_suspended then 'author_suspended' else 'author_unsuspended' end);
end $$;

create function public.set_public_trip_flags_dashboard(p_read_enabled boolean,p_publish_enabled boolean)
returns void language plpgsql security definer set search_path = '' as $$
begin
  perform public_trip_private.assert_admin(true);
  if p_read_enabled is null or p_publish_enabled is null then
    raise exception 'Explicit feature flags required' using errcode = '22023';
  end if;
  update public.app_feature_flags set
    enabled = case when feature_key = 'public_trips_read' then p_read_enabled else p_publish_enabled end,
    updated_at = now(),updated_by = auth.uid()
    where feature_key in ('public_trips_read','public_trips_publish');
  insert into public.public_trip_moderation_events(actor_id,action) values (auth.uid(),'flags_changed');
end $$;

create function public.review_public_trip(
  p_publication_id uuid,p_revision integer,p_content_hash text,p_decision text,p_reason text default null
) returns jsonb language plpgsql security definer set search_path = '' as $$
declare v_pub public.public_trip_publications; v_rev public.public_trip_revisions;
begin
  perform public_trip_private.assert_admin();
  if p_decision is null or p_decision not in ('approve','reject') or length(p_reason) > 500
    or (p_decision = 'reject' and length(btrim(coalesce(p_reason,''))) = 0) then
    raise exception 'Valid review decision and reason required' using errcode = '22023';
  end if;
  select * into v_pub from public.public_trip_publications where id = p_publication_id for update;
  if not found or v_pub.hidden then raise exception 'Publication unavailable' using errcode = '42501'; end if;
  select * into v_rev from public.public_trip_revisions where publication_id = v_pub.id and revision = p_revision for update;
  if not found or v_rev.generation <> v_pub.generation or p_content_hash is distinct from v_rev.content_hash
    or v_rev.source_hash is distinct from public_trip_private.source_hash(v_pub.journey_id) then
    raise exception 'Review candidate changed or was withdrawn' using errcode = '22023';
  end if;
  if (v_rev.status = 'approved' and p_decision = 'approve' and v_pub.active_revision = p_revision)
    or (v_rev.status = 'rejected' and p_decision = 'reject') then
    return public_trip_private.owner_projection(v_pub.id,p_revision);
  end if;
  if v_rev.status <> 'submitted' or not exists (select 1 from public.public_trip_consents
    where publication_id = v_pub.id and revision = p_revision and content_hash = v_rev.content_hash) then
    raise exception 'Only consented submitted revisions can be reviewed' using errcode = '22023';
  end if;
  if p_decision = 'approve' then
    if not exists (select 1 from public.app_feature_flags where feature_key = 'public_trips_publish' and enabled)
      or exists (select 1 from public.public_trip_authors a where a.user_id = v_pub.owner_id and a.suspended)
      or exists (select 1 from public.user_moderation_status s
        where s.user_id = v_pub.owner_id and s.status = 'suspended') then
      raise exception 'Publishing unavailable for this author' using errcode = '42501';
    end if;
    update public.public_trip_revisions set status = 'superseded'
      where publication_id = v_pub.id and revision = v_pub.active_revision;
    update public.public_trip_publications set active_revision = p_revision where id = v_pub.id;
  end if;
  update public.public_trip_revisions set status = case when p_decision = 'approve' then 'approved' else 'rejected' end,
    reviewed_at = now(),review_reason = p_reason where publication_id = v_pub.id and revision = p_revision;
  insert into public.public_trip_moderation_events(actor_id,publication_id,revision,action)
    values (auth.uid(),v_pub.id,p_revision,p_decision);
  return public_trip_private.owner_projection(v_pub.id,p_revision);
end $$;

create function public.set_public_trip_hidden_dashboard(p_publication_id uuid,p_hidden boolean)
returns void language plpgsql security definer set search_path = '' as $$
begin
  perform public_trip_private.assert_admin();
  if p_hidden is null then raise exception 'Explicit visibility required' using errcode = '22023'; end if;
  update public.public_trip_publications set hidden = p_hidden,
    active_revision = case when p_hidden then null else active_revision end,
    generation = generation + case when p_hidden then 1 else 0 end where id = p_publication_id;
  if not found then raise exception 'Publication unavailable' using errcode = '22023'; end if;
  if p_hidden then
    update public.public_trip_revisions set status = 'revoked' where publication_id = p_publication_id;
  end if;
  -- Unhiding does not republish: the owner must submit a fresh revision.
  insert into public.public_trip_moderation_events(actor_id,publication_id,action)
    values (auth.uid(),p_publication_id,case when p_hidden then 'hide' else 'allow_resubmission' end);
end $$;

create function public.list_public_trip_reviews_dashboard(p_limit integer default 20,p_before timestamptz default null)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare v_result jsonb;
begin
  perform public_trip_private.assert_admin();
  if p_limit is null or p_limit not between 1 and 50 then raise exception 'Invalid page size' using errcode = '22023'; end if;
  select coalesce(jsonb_agg(item order by submitted_at desc),'[]'::jsonb) into v_result from (
    select public_trip_private.owner_projection(r.publication_id,r.revision)
      || jsonb_build_object('submitted_at',r.submitted_at) as item,r.submitted_at
    from public.public_trip_revisions r join public.public_trip_publications p on p.id = r.publication_id
    where r.status = 'submitted' and not p.hidden and r.generation = p.generation
      and (p_before is null or r.submitted_at < p_before)
    order by r.submitted_at desc limit p_limit
  ) q;
  return v_result;
end $$;

revoke all on function public.set_public_trip_author_suspended_dashboard(uuid,boolean),
  public.set_public_trip_flags_dashboard(boolean,boolean),public.review_public_trip(uuid,integer,text,text,text),
  public.set_public_trip_hidden_dashboard(uuid,boolean),public.list_public_trip_reviews_dashboard(integer,timestamptz)
  from public, anon, authenticated;
grant execute on function public.set_public_trip_author_suspended_dashboard(uuid,boolean),
  public.set_public_trip_flags_dashboard(boolean,boolean),public.review_public_trip(uuid,integer,text,text,text),
  public.set_public_trip_hidden_dashboard(uuid,boolean),public.list_public_trip_reviews_dashboard(integer,timestamptz)
  to authenticated;
