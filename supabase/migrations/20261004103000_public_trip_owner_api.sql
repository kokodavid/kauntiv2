-- p_moments: [{"kind": ..., "sequence_number": n}] chosen by the owner from
-- the replay's moments. p_photo_ids: journey_media IDs. Positions and values
-- come from the server's own points; anything in a hidden part of the route
-- is dropped and reported back to the owner under 'excluded'.
create function public.prepare_public_trip(
  p_journey_id uuid, p_request_id uuid, p_title text,
  p_moments jsonb default '[]'::jsonb, p_photo_ids uuid[] default '{}'::uuid[],
  p_start_trim_m integer default 500, p_end_trim_m integer default 500
) returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  v_user uuid := public_trip_private.assert_member('publish');
  v_journey public.journeys; v_pub public.public_trip_publications;
  v_request public_trip_private.requests; v_data jsonb; v_input text; v_hash text; v_source text;
  v_date date; v_moments jsonb; v_photos jsonb; v_skipped_moments jsonb; v_skipped_photos jsonb;
begin
  if p_request_id is null or p_journey_id is null or p_title is null
    or length(btrim(p_title)) not between 1 and 80 or p_title ~ '[[:cntrl:]]' then
    raise exception 'Valid request and title are required' using errcode = '22023';
  end if;
  if p_moments is null or jsonb_typeof(p_moments) <> 'array' or jsonb_array_length(p_moments) > 30
    or exists (select 1 from jsonb_array_elements(p_moments) m
      where jsonb_typeof(m) <> 'object'
        or coalesce(m->>'kind', '') not in
          ('county_crossing', 'elevation_peak', 'top_speed', 'long_stop', 'recording_break')
        or coalesce(m->>'sequence_number', '') !~ '^[0-9]{1,9}$') then
    raise exception 'Moments must be up to 30 known kinds with a point' using errcode = '22023';
  end if;
  if p_photo_ids is null or cardinality(p_photo_ids) > 10
    or exists (select 1 from unnest(p_photo_ids) i where i is null) then
    raise exception 'Up to 10 photos can be published' using errcode = '22023';
  end if;
  perform pg_advisory_xact_lock(hashtextextended(v_user::text,4104));
  select * into v_journey from public.journeys where id = p_journey_id and user_id = v_user for update;
  if not found then raise exception 'Journey unavailable' using errcode = '42501'; end if;
  if v_journey.ended_at > now() or v_journey.transport_mode is null
    or v_journey.transport_mode not in ('drive','walk') then
    raise exception 'Only completed driving or walking trips can be submitted' using errcode = '22023';
  end if;
  if exists (select 1 from unnest(p_photo_ids) i where not exists (
      select 1 from public.journey_media m
      where m.id = i and m.journey_id = p_journey_id and m.user_id = v_user)) then
    raise exception 'Photo unavailable' using errcode = '22023';
  end if;
  v_input := encode(sha256(convert_to(jsonb_build_array(p_journey_id,p_title,p_moments,
    to_jsonb(p_photo_ids),p_start_trim_m,p_end_trim_m)::text,'UTF8')),'hex');
  select * into v_request from public_trip_private.requests where user_id = v_user and request_id = p_request_id;
  if found then
    if v_request.operation <> 'prepare' or v_request.input_hash <> v_input then
      raise exception 'Request ID already used for different input' using errcode = '22023';
    end if;
    if not exists (select 1 from public.public_trip_revisions r
      join public.public_trip_publications p on p.id = r.publication_id
      where p.id = v_request.publication_id and r.revision = v_request.revision
        and r.generation = p.generation and not p.hidden
        and r.status in ('prepared','submitted','approved') and r.expires_at > now()) then
      raise exception 'Candidate expired or revoked; prepare again' using errcode = '22023';
    end if;
    return public_trip_private.owner_projection(v_request.publication_id,v_request.revision);
  end if;
  perform public_trip_private.rate_limit('prepare',5,'hour');
  insert into public.public_trip_authors(user_id) values (v_user) on conflict (user_id) do nothing;
  insert into public.public_trip_publications(journey_id,owner_id)
    values (p_journey_id,v_user) on conflict (journey_id) do nothing;
  select * into v_pub from public.public_trip_publications where journey_id = p_journey_id for update;
  if v_pub.owner_id <> v_user or v_pub.hidden then
    raise exception 'Publication unavailable' using errcode = '42501';
  end if;
  v_data := public_trip_private.sanitize_route(p_journey_id,p_start_trim_m,p_end_trim_m);
  v_source := public_trip_private.source_hash(p_journey_id);
  v_date := (v_journey.started_at at time zone 'Africa/Nairobi')::date;

  with requested as (
    select distinct m->>'kind' as kind, (m->>'sequence_number')::integer as seq
    from jsonb_array_elements(p_moments) m
  ), placed as (
    select r.kind, r.seq, pt.latitude, pt.longitude, pt.altitude_m, pt.speed_mps,
      pt.sequence_number is not null and exists (
        select 1 from jsonb_array_elements(v_data->'retained') g
        where r.seq between (g->>0)::integer and (g->>1)::integer) as visible
    from requested r
    left join public.journey_points pt on pt.journey_id = p_journey_id and pt.sequence_number = r.seq
  ) select
      coalesce(jsonb_agg(jsonb_build_object('kind', kind,
        'latitude', round(latitude, 5), 'longitude', round(longitude, 5),
        'value', case kind
          when 'county_crossing' then coalesce((select jsonb_build_object('code', c.id, 'name', c.name)
            from public.counties c where extensions.st_intersects(c.geometry,
              extensions.st_setsrid(extensions.st_makepoint(longitude, latitude), 4326))
            order by c.id limit 1), '{}'::jsonb)
          when 'elevation_peak' then case when altitude_m is null then '{}'::jsonb
            else jsonb_build_object('elevation_m', round(altitude_m)) end
          when 'top_speed' then case when speed_mps is null then '{}'::jsonb
            else jsonb_build_object('speed_mps', round(speed_mps, 1)) end
          else '{}'::jsonb end) order by seq, kind) filter (where visible), '[]'::jsonb),
      coalesce(jsonb_agg(jsonb_build_object('kind', kind, 'sequence_number', seq)
        order by seq, kind) filter (where not visible), '[]'::jsonb)
    into v_moments, v_skipped_moments
  from placed;

  -- A photo is placed at the route point nearest its capture time, not at
  -- its own GPS fix, so it always sits on the public line.
  with chosen as (
    select m.id, m.captured_at, near.sequence_number as seq, near.latitude, near.longitude
    from public.journey_media m
    cross join lateral (
      select p.sequence_number, p.latitude, p.longitude from public.journey_points p
      where p.journey_id = p_journey_id
      order by abs(extract(epoch from p.recorded_at - m.captured_at)), p.sequence_number limit 1
    ) near
    where m.id = any(p_photo_ids) and m.journey_id = p_journey_id
  ), placed as (
    select c.*, exists (select 1 from jsonb_array_elements(v_data->'retained') g
      where c.seq between (g->>0)::integer and (g->>1)::integer) as visible
    from chosen c
  ) select
      coalesce(jsonb_agg(jsonb_build_object('media_id', id, 'latitude', round(latitude, 5),
        'longitude', round(longitude, 5)) order by captured_at, id) filter (where visible), '[]'::jsonb),
      coalesce(jsonb_agg(to_jsonb(id) order by captured_at, id) filter (where not visible), '[]'::jsonb)
    into v_photos, v_skipped_photos
  from placed;

  v_hash := encode(sha256(convert_to(jsonb_build_array(v_data,btrim(p_title),
    v_journey.transport_mode,v_date,v_moments,v_photos,p_start_trim_m,p_end_trim_m,2)::text,'UTF8')),'hex');
  -- Only one review candidate at a time; the currently approved copy stays immutable.
  update public.public_trip_revisions set status = 'superseded'
    where publication_id = v_pub.id and status in ('prepared','submitted');
  insert into public.public_trip_revisions(publication_id,revision,generation,source_hash,content_hash,
    title,trip_date,excluded,transport_mode,route,distance_m,counties,start_trim_m,end_trim_m)
  values (v_pub.id,v_pub.next_revision,v_pub.generation,v_source,v_hash,btrim(p_title),v_date,
    jsonb_build_object('moments',v_skipped_moments,'photo_ids',v_skipped_photos),
    v_journey.transport_mode,v_data->'route',(v_data->>'distance_m')::numeric,v_data->'counties',p_start_trim_m,p_end_trim_m);
  insert into public.public_trip_revision_moments(publication_id,revision,ordinal,kind,latitude,longitude,value)
    select v_pub.id,v_pub.next_revision,e.ord,e.m->>'kind',(e.m->>'latitude')::numeric,
      (e.m->>'longitude')::numeric,e.m->'value'
    from jsonb_array_elements(v_moments) with ordinality e(m, ord);
  insert into public.public_trip_revision_photos(publication_id,revision,ordinal,source_media_id,latitude,longitude)
    select v_pub.id,v_pub.next_revision,e.ord,(e.m->>'media_id')::uuid,(e.m->>'latitude')::numeric,
      (e.m->>'longitude')::numeric
    from jsonb_array_elements(v_photos) with ordinality e(m, ord);
  update public.public_trip_publications set next_revision = next_revision + 1 where id = v_pub.id;
  insert into public_trip_private.requests(user_id,request_id,operation,input_hash,publication_id,revision)
    values (v_user,p_request_id,'prepare',v_input,v_pub.id,v_pub.next_revision);
  return public_trip_private.owner_projection(v_pub.id,v_pub.next_revision);
end $$;

create function public.submit_public_trip(p_publication_id uuid,p_revision integer,p_content_hash text,p_terms_version text)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare v_user uuid := public_trip_private.assert_member('publish');
  v_pub public.public_trip_publications; v_rev public.public_trip_revisions;
begin
  perform pg_advisory_xact_lock(hashtextextended(v_user::text,4104));
  select * into v_pub from public.public_trip_publications where id = p_publication_id and owner_id = v_user for update;
  if not found or v_pub.hidden then raise exception 'Publication unavailable' using errcode = '42501'; end if;
  select * into v_rev from public.public_trip_revisions where publication_id = v_pub.id and revision = p_revision for update;
  if not found or p_terms_version is distinct from 'public-trips-v1'
    or p_content_hash is distinct from v_rev.content_hash or v_rev.generation <> v_pub.generation
    or v_rev.status not in ('prepared','submitted','approved')
    or v_rev.source_hash is distinct from public_trip_private.source_hash(v_pub.journey_id) then
    raise exception 'Review the latest candidate and terms' using errcode = '22023';
  end if;
  if v_rev.status in ('submitted','approved') then
    return public_trip_private.owner_projection(v_pub.id,p_revision);
  end if;
  if v_rev.expires_at <= now() then raise exception 'Candidate expired' using errcode = '22023'; end if;
  if exists (select 1 from public.public_trip_revision_photos ph where ph.publication_id = v_pub.id
    and ph.revision = p_revision and ph.status <> 'ready') then
    raise exception 'Photos are still being prepared, or one failed; prepare again without it'
      using errcode = '55000';
  end if;
  if (select count(*) from public.public_trip_publications p where p.owner_id = v_user
    and p.id <> v_pub.id and (p.active_revision is not null or exists (
      select 1 from public.public_trip_revisions r where r.publication_id = p.id and r.status = 'submitted'))) >= 3 then
    raise exception 'Pilot publication limit reached' using errcode = '54000';
  end if;
  insert into public.public_trip_consents(publication_id,revision,terms_version,content_hash)
    values (v_pub.id,p_revision,p_terms_version,p_content_hash);
  update public.public_trip_revisions set status = 'submitted',submitted_at = now()
    where publication_id = v_pub.id and revision = p_revision;
  return public_trip_private.owner_projection(v_pub.id,p_revision);
end $$;

create function public.withdraw_public_trip(p_publication_id uuid,p_request_id uuid)
returns void language plpgsql security definer set search_path = '' as $$
declare v_user uuid := auth.uid(); v_request public_trip_private.requests;
begin
  if v_user is null or p_request_id is null then raise exception 'Sign in required' using errcode = '42501'; end if;
  perform pg_advisory_xact_lock(hashtextextended(v_user::text,4104));
  if not exists (select 1 from public.public_trip_publications where id = p_publication_id and owner_id = v_user) then
    raise exception 'Publication unavailable' using errcode = '42501';
  end if;
  select * into v_request from public_trip_private.requests where user_id = v_user and request_id = p_request_id;
  if found then
    if v_request.operation <> 'withdraw' or v_request.publication_id <> p_publication_id then
      raise exception 'Request ID already used' using errcode = '22023';
    end if;
    return;
  end if;
  update public.public_trip_publications set generation = generation + 1,active_revision = null
    where id = p_publication_id;
  update public.public_trip_revisions set status = 'revoked' where publication_id = p_publication_id;
  insert into public_trip_private.requests(user_id,request_id,operation,input_hash,publication_id)
    values (v_user,p_request_id,'withdraw',p_publication_id::text,p_publication_id);
end $$;

create function public.my_public_trip(p_journey_id uuid)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare v_pub public.public_trip_publications;
begin
  if auth.uid() is null then raise exception 'Sign in required' using errcode = '42501'; end if;
  select * into v_pub from public.public_trip_publications where journey_id = p_journey_id and owner_id = auth.uid();
  if not found then return null; end if;
  return coalesce(public_trip_private.owner_projection(v_pub.id,v_pub.next_revision - 1),
    jsonb_build_object('id',v_pub.id,'status','revoked'))
    || jsonb_build_object('active_revision',v_pub.active_revision,'hidden',v_pub.hidden);
end $$;

revoke all on function public.prepare_public_trip(uuid,uuid,text,jsonb,uuid[],integer,integer),
  public.submit_public_trip(uuid,integer,text,text), public.withdraw_public_trip(uuid,uuid),
  public.my_public_trip(uuid) from public, anon, authenticated;
grant execute on function public.prepare_public_trip(uuid,uuid,text,jsonb,uuid[],integer,integer),
  public.submit_public_trip(uuid,integer,text,text), public.withdraw_public_trip(uuid,uuid),
  public.my_public_trip(uuid) to authenticated;
