-- Editors can add their own licensed image to an AI-researched candidate.
-- The file remains private in place-candidate-staging until it is explicitly
-- approved, then the Edge Function copies it to place-images while publishing.

alter table public.place_candidate_images
  drop constraint if exists place_candidate_images_identity_check;

alter table public.place_candidate_images
  add constraint place_candidate_images_identity_check
  check (
    source_image_id is not null
    or scrape_image_key is not null
    or staging_path is not null
  );

-- This internal helper is intentionally not granted to browser roles. It
-- makes an approved staged image count as a photo without exposing its path.
create or replace function public.recompute_place_candidate_readiness(
  p_candidate_id uuid
)
returns public.place_candidates
language plpgsql
security definer
set search_path = public
as $$
declare
  v_candidate public.place_candidates;
  v_has_approved_image boolean;
  v_has_waiting_image boolean;
  v_images jsonb;
  v_profile jsonb;
  v_missing text[];
  v_blockers text[];
begin
  select * into v_candidate
  from public.place_candidates
  where id = p_candidate_id
  for update;
  if not found then
    raise exception 'Candidate % was not found', p_candidate_id using errcode = 'P0002';
  end if;

  select exists (
    select 1 from public.place_candidate_images image
    where image.candidate_id = v_candidate.id
      and image.staging_path is not null
      and image.review_status = 'approved'
  ) into v_has_approved_image;

  select exists (
    select 1 from public.place_candidate_images image
    where image.candidate_id = v_candidate.id
      and image.staging_path is not null
      and image.review_status in ('pending', 'failed')
  ) into v_has_waiting_image;

  v_images := case when v_has_approved_image then
    jsonb_build_array(jsonb_build_object('image_url', 'approved-private-asset'))
  else '[]'::jsonb end;
  v_profile := jsonb_build_object(
    'summary', v_candidate.summary,
    'lat', v_candidate.lat,
    'lng', v_candidate.lng,
    'source', v_candidate.source
  );
  v_missing := public.selected_place_profile_missing_fields(v_profile, v_images);
  v_blockers := public.selected_place_publish_blockers(v_profile, v_images);
  if v_has_waiting_image then
    v_blockers := array_append(v_blockers, 'image review');
  end if;

  update public.place_candidates
  set completeness = round((3 - cardinality(v_missing)) * 100.0 / 3.0)::smallint,
      missing_fields = v_missing,
      publish_blockers = v_blockers
  where id = v_candidate.id
  returning * into v_candidate;
  return v_candidate;
end;
$$;

create or replace function public.refresh_place_candidate_image_readiness_dashboard(
  p_candidate_id uuid
)
returns public.place_candidates
language plpgsql
security definer
set search_path = public
as $$
declare
  v_role public.admin_role;
begin
  v_role := public.current_admin_role();
  if v_role not in ('owner', 'admin', 'editor') then
    raise exception 'Candidate image review requires owner, admin, or editor access'
      using errcode = '42501';
  end if;
  return public.recompute_place_candidate_readiness(p_candidate_id);
end;
$$;

create or replace function public.review_place_candidate_image_dashboard(
  p_candidate_id uuid,
  p_image_id uuid,
  p_review_status text,
  p_review_note text default null
)
returns public.place_candidate_images
language plpgsql
security definer
set search_path = public
as $$
declare
  v_role public.admin_role;
  v_image public.place_candidate_images;
begin
  v_role := public.current_admin_role();
  if v_role not in ('owner', 'admin', 'editor') then
    raise exception 'Image review requires owner, admin, or editor access' using errcode = '42501';
  end if;
  if p_review_status not in ('approved', 'rejected') then
    raise exception 'Image status must be approved or rejected' using errcode = '22023';
  end if;
  if p_review_status = 'rejected' and nullif(btrim(p_review_note), '') is null then
    raise exception 'A rejection note is required' using errcode = '22023';
  end if;

  select image.* into v_image
  from public.place_candidate_images image
  join public.place_candidates candidate on candidate.id = image.candidate_id
  where image.id = p_image_id
    and image.candidate_id = p_candidate_id
    and image.staging_path is not null
    and candidate.status = 'pending_review'
  for update;
  if not found then
    raise exception 'Pending staged candidate image % was not found', p_image_id using errcode = 'P0002';
  end if;

  update public.place_candidate_images
  set review_status = p_review_status,
      review_note = nullif(btrim(p_review_note), ''),
      reviewed_at = now(),
      reviewed_by = auth.uid(),
      approved_at = case when p_review_status = 'approved' then now() else null end,
      approved_by = case when p_review_status = 'approved' then auth.uid() else null end
  where id = v_image.id
  returning * into v_image;

  perform public.recompute_place_candidate_readiness(p_candidate_id);
  return v_image;
end;
$$;

-- The browser never supplies public URLs. The asset Edge Function copies the
-- approved files, then passes only those copied URLs to this guarded RPC.
create or replace function public.publish_staged_place_candidate_dashboard(
  p_candidate_id uuid,
  p_public_images jsonb,
  p_review_note text default null
)
returns public.places
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_role public.admin_role;
  v_candidate public.place_candidates;
  v_images jsonb;
  v_profile jsonb;
  v_missing text[];
  v_blockers text[];
  v_place public.places;
  v_place_id uuid;
begin
  v_role := public.current_admin_role();
  if v_role not in ('owner', 'admin', 'editor') then
    raise exception 'Candidate publishing requires owner, admin, or editor access' using errcode = '42501';
  end if;
  if jsonb_typeof(p_public_images) <> 'array' or jsonb_array_length(p_public_images) = 0 then
    raise exception 'At least one approved public image is required' using errcode = '22023';
  end if;

  select * into v_candidate
  from public.place_candidates
  where id = p_candidate_id
    and origin in ('scraper', 'research_lead')
    and status = 'pending_review'
  for update;
  if not found then
    raise exception 'Pending staged candidate % was not found', p_candidate_id using errcode = 'P0002';
  end if;
  if exists (
    select 1 from public.place_candidate_images image
    where image.candidate_id = p_candidate_id
      and image.staging_path is not null
      and image.review_status in ('pending', 'failed')
  ) then
    raise exception 'Every staged candidate image must be reviewed before publishing' using errcode = '22023';
  end if;
  if exists (
    select 1 from public.place_candidate_images image
    where image.candidate_id = p_candidate_id
      and image.staging_path is not null
      and image.review_status = 'approved'
      and not exists (
        select 1 from jsonb_array_elements(p_public_images) supplied
        where (supplied.value ->> 'candidate_image_id')::uuid = image.id
          and nullif(supplied.value ->> 'image_url', '') is not null
      )
  ) then
    raise exception 'Every approved image must be copied before publishing' using errcode = '22023';
  end if;
  if exists (
    select 1 from jsonb_array_elements(p_public_images) supplied
    left join public.place_candidate_images image
      on image.id = (supplied.value ->> 'candidate_image_id')::uuid
    where image.id is null
       or image.candidate_id <> p_candidate_id
       or image.review_status <> 'approved'
       or image.staging_path is null
  ) then
    raise exception 'Public image list contains an unapproved candidate asset' using errcode = '22023';
  end if;

  select coalesce(jsonb_agg(jsonb_build_object(
    'image_url', supplied.value ->> 'image_url',
    'thumbnail_url', coalesce(supplied.value ->> 'thumbnail_url', supplied.value ->> 'image_url')
  )), '[]'::jsonb)
  into v_images
  from jsonb_array_elements(p_public_images) supplied;
  v_profile := jsonb_build_object(
    'summary', v_candidate.summary, 'lat', v_candidate.lat,
    'lng', v_candidate.lng, 'source', v_candidate.source
  );
  v_missing := public.selected_place_profile_missing_fields(v_profile, v_images);
  v_blockers := public.selected_place_publish_blockers(v_profile, v_images);
  if cardinality(v_missing) > 0 or cardinality(v_blockers) > 0 then
    raise exception 'Candidate is not ready to publish. Missing: %, blockers: %', v_missing, v_blockers using errcode = '22023';
  end if;
  if v_candidate.county_id is null then
    raise exception 'Candidate county is required' using errcode = '22023';
  end if;

  v_place_id := coalesce(v_candidate.source_place_id, v_candidate.id);
  insert into public.places (
    id, county_id, name, type, summary, description, location, source,
    source_url, licence, external_id, last_verified_at, content_origin, reviewed_at
  ) values (
    v_place_id, v_candidate.county_id, v_candidate.name, v_candidate.type,
    v_candidate.summary, v_candidate.description,
    st_setsrid(st_makepoint(v_candidate.lng, v_candidate.lat), 4326), v_candidate.source,
    v_candidate.source_url, v_candidate.licence, v_candidate.external_id,
    v_candidate.last_verified_at, 'candidate_review', now()
  ) on conflict (id) do nothing
  returning * into v_place;
  if v_place is null then
    select * into v_place from public.places where id = v_place_id;
  end if;

  insert into public.place_images (
    id, place_id, sort_order, image_url, thumbnail_url, source, source_url,
    licence, licence_url, attribution, external_id, last_verified_at
  )
  select image.id, v_place.id, image.sort_order,
    supplied.value ->> 'image_url', coalesce(supplied.value ->> 'thumbnail_url', supplied.value ->> 'image_url'),
    image.source, image.source_url, image.licence, image.licence_url,
    image.attribution, image.external_id, image.last_verified_at
  from jsonb_array_elements(p_public_images) supplied
  join public.place_candidate_images image
    on image.id = (supplied.value ->> 'candidate_image_id')::uuid;

  update public.place_candidates
  set status = 'published', published_place_id = v_place.id,
      review_note = nullif(btrim(p_review_note), ''), reviewed_at = now(), reviewed_by = auth.uid(),
      missing_fields = v_missing, publish_blockers = v_blockers, completeness = 100
  where id = v_candidate.id;
  return v_place;
end;
$$;

create or replace function public.get_place_candidate_dashboard(p_candidate_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_role public.admin_role;
  v_result jsonb;
begin
  v_role := public.current_admin_role();
  if v_role not in ('owner', 'admin', 'editor') then
    raise exception 'Candidate review requires owner, admin, or editor access' using errcode = '42501';
  end if;
  select jsonb_build_object(
    'id', candidate.id, 'origin', candidate.origin, 'source_place_id', candidate.source_place_id,
    'county_id', candidate.county_id, 'county_name', county.name,
    'name', candidate.name, 'type', candidate.type, 'summary', candidate.summary,
    'description', candidate.description, 'lat', candidate.lat, 'lng', candidate.lng,
    'source', candidate.source, 'source_url', candidate.source_url, 'licence', candidate.licence,
    'external_id', candidate.external_id, 'last_verified_at', candidate.last_verified_at,
    'completeness', candidate.completeness, 'missing_fields', candidate.missing_fields,
    'publish_blockers', candidate.publish_blockers, 'status', candidate.status,
    'review_note', candidate.review_note, 'imported_at', candidate.imported_at,
    'reviewed_at', candidate.reviewed_at, 'intake_source', candidate.intake_source,
    'intake_source_url', candidate.intake_source_url, 'research_status', candidate.research_status,
    'research_notes', candidate.research_notes, 'research_sources', candidate.research_sources,
    'research_model', candidate.research_model, 'researched_at', candidate.researched_at,
    'images', coalesce(images.items, '[]'::jsonb)
  ) into v_result
  from public.place_candidates candidate
  left join public.counties county on county.id = candidate.county_id
  left join lateral (
    select jsonb_agg(jsonb_build_object(
      'id', image.id, 'source_image_id', image.source_image_id, 'sort_order', image.sort_order,
      'image_url', case when image.staging_path is null then image.image_url else null end,
      'thumbnail_url', case when image.staging_path is null then image.thumbnail_url else null end,
      'is_staged', image.staging_path is not null, 'staged_at', image.staged_at,
      'staged_content_type', image.staged_content_type, 'staged_bytes', image.staged_bytes,
      'review_status', image.review_status, 'review_note', image.review_note,
      'reviewed_at', image.reviewed_at, 'stage_failure_reason', image.stage_failure_reason,
      'source', image.source, 'source_url', image.source_url, 'licence', image.licence,
      'licence_url', image.licence_url, 'attribution', image.attribution,
      'external_id', image.external_id, 'last_verified_at', image.last_verified_at
    ) order by image.sort_order, image.id) as items
    from public.place_candidate_images image where image.candidate_id = candidate.id
  ) images on true
  where candidate.id = p_candidate_id;
  if v_result is null then
    raise exception 'Candidate % was not found', p_candidate_id using errcode = 'P0002';
  end if;
  return v_result;
end;
$$;

revoke all on function public.recompute_place_candidate_readiness(uuid) from public;
revoke all on function public.refresh_place_candidate_image_readiness_dashboard(uuid) from public;
revoke all on function public.review_place_candidate_image_dashboard(uuid, uuid, text, text) from public;
revoke all on function public.publish_staged_place_candidate_dashboard(uuid, jsonb, text) from public;
revoke all on function public.get_place_candidate_dashboard(uuid) from public;
grant execute on function public.refresh_place_candidate_image_readiness_dashboard(uuid) to authenticated;
grant execute on function public.review_place_candidate_image_dashboard(uuid, uuid, text, text) to authenticated;
grant execute on function public.publish_staged_place_candidate_dashboard(uuid, jsonb, text) to authenticated;
grant execute on function public.get_place_candidate_dashboard(uuid) to authenticated;
