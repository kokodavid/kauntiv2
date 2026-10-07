-- Candidate moderation remains server-owned: dashboard clients can request
-- review actions but cannot directly read or mutate candidate tables.

alter table public.places
  drop constraint if exists places_content_origin_check;

alter table public.places
  add constraint places_content_origin_check
  check (content_origin in ('dashboard', 'seed_migration', 'selected_dev_import', 'candidate_review'));

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
    raise exception 'Candidate review requires owner, admin, or editor access'
      using errcode = '42501';
  end if;

  select jsonb_build_object(
    'id', candidate.id,
    'source_place_id', candidate.source_place_id,
    'county_id', candidate.county_id,
    'county_name', county.name,
    'name', candidate.name,
    'type', candidate.type,
    'summary', candidate.summary,
    'description', candidate.description,
    'lat', candidate.lat,
    'lng', candidate.lng,
    'source', candidate.source,
    'source_url', candidate.source_url,
    'licence', candidate.licence,
    'external_id', candidate.external_id,
    'last_verified_at', candidate.last_verified_at,
    'completeness', candidate.completeness,
    'missing_fields', candidate.missing_fields,
    'publish_blockers', candidate.publish_blockers,
    'status', candidate.status,
    'review_note', candidate.review_note,
    'imported_at', candidate.imported_at,
    'reviewed_at', candidate.reviewed_at,
    'images', coalesce(images.items, '[]'::jsonb)
  ) into v_result
  from public.place_candidates candidate
  left join public.counties county on county.id = candidate.county_id
  left join lateral (
    select jsonb_agg(jsonb_build_object(
      'id', image.id,
      'source_image_id', image.source_image_id,
      'sort_order', image.sort_order,
      'image_url', image.image_url,
      'thumbnail_url', image.thumbnail_url,
      'source', image.source,
      'source_url', image.source_url,
      'licence', image.licence,
      'licence_url', image.licence_url,
      'attribution', image.attribution,
      'external_id', image.external_id,
      'last_verified_at', image.last_verified_at
    ) order by image.sort_order, image.id) as items
    from public.place_candidate_images image
    where image.candidate_id = candidate.id
  ) images on true
  where candidate.id = p_candidate_id;

  if v_result is null then
    raise exception 'Candidate % was not found', p_candidate_id using errcode = 'P0002';
  end if;

  return v_result;
end;
$$;

create or replace function public.update_place_candidate_dashboard(
  p_candidate_id uuid,
  p_county_id smallint,
  p_name text,
  p_type text,
  p_summary text,
  p_description text,
  p_source text,
  p_source_url text,
  p_licence text,
  p_last_verified_at date,
  p_lat double precision,
  p_lng double precision
)
returns public.place_candidates
language plpgsql
security definer
set search_path = public
as $$
declare
  v_role public.admin_role;
  v_images jsonb;
  v_profile jsonb;
  v_missing text[];
  v_blockers text[];
  v_candidate public.place_candidates;
begin
  v_role := public.current_admin_role();
  if v_role not in ('owner', 'admin', 'editor') then
    raise exception 'Candidate editing requires owner, admin, or editor access'
      using errcode = '42501';
  end if;

  if p_candidate_id is null then
    raise exception 'Candidate id is required' using errcode = '22023';
  end if;
  if p_county_id is null or not exists (select 1 from public.counties where id = p_county_id) then
    raise exception 'A valid county is required' using errcode = '22023';
  end if;
  if nullif(btrim(p_name), '') is null or nullif(btrim(p_type), '') is null then
    raise exception 'Name and type are required' using errcode = '22023';
  end if;
  if (p_lat is not null and (p_lat < -90 or p_lat > 90))
    or (p_lng is not null and (p_lng < -180 or p_lng > 180)) then
    raise exception 'Coordinates are invalid' using errcode = '22023';
  end if;
  if p_last_verified_at is not null and p_last_verified_at > current_date then
    raise exception 'Last verified date cannot be in the future' using errcode = '22023';
  end if;

  select coalesce(jsonb_agg(jsonb_build_object(
    'image_url', image.image_url,
    'thumbnail_url', image.thumbnail_url
  ) order by image.sort_order, image.id), '[]'::jsonb)
  into v_images
  from public.place_candidate_images image
  where image.candidate_id = p_candidate_id;

  v_profile := jsonb_build_object(
    'summary', nullif(btrim(p_summary), ''),
    'lat', p_lat,
    'lng', p_lng,
    'source', nullif(btrim(p_source), '')
  );
  v_missing := public.selected_place_profile_missing_fields(v_profile, v_images);
  v_blockers := public.selected_place_publish_blockers(v_profile, v_images);

  update public.place_candidates
  set
    county_id = p_county_id,
    name = btrim(p_name),
    type = btrim(p_type),
    summary = nullif(btrim(p_summary), ''),
    description = nullif(btrim(p_description), ''),
    source = nullif(btrim(p_source), ''),
    source_url = nullif(btrim(p_source_url), ''),
    licence = nullif(btrim(p_licence), ''),
    last_verified_at = p_last_verified_at,
    lat = p_lat,
    lng = p_lng,
    completeness = round((3 - cardinality(v_missing)) * 100.0 / 3.0)::smallint,
    missing_fields = v_missing,
    publish_blockers = v_blockers
  where id = p_candidate_id
    and status = 'pending_review'
  returning * into v_candidate;

  if not found then
    raise exception 'Pending candidate % was not found', p_candidate_id using errcode = 'P0002';
  end if;

  return v_candidate;
end;
$$;

create or replace function public.reject_place_candidate_dashboard(
  p_candidate_id uuid,
  p_review_note text
)
returns public.place_candidates
language plpgsql
security definer
set search_path = public
as $$
declare
  v_role public.admin_role;
  v_candidate public.place_candidates;
begin
  v_role := public.current_admin_role();
  if v_role not in ('owner', 'admin', 'editor') then
    raise exception 'Candidate review requires owner, admin, or editor access'
      using errcode = '42501';
  end if;
  if nullif(btrim(p_review_note), '') is null then
    raise exception 'A rejection note is required' using errcode = '22023';
  end if;

  update public.place_candidates
  set status = 'rejected', review_note = btrim(p_review_note), reviewed_at = now(), reviewed_by = auth.uid()
  where id = p_candidate_id and status = 'pending_review'
  returning * into v_candidate;

  if not found then
    raise exception 'Pending candidate % was not found', p_candidate_id using errcode = 'P0002';
  end if;
  return v_candidate;
end;
$$;

create or replace function public.publish_place_candidate_dashboard(
  p_candidate_id uuid,
  p_review_note text default null
)
returns public.places
language plpgsql
security definer
set search_path = public
as $$
declare
  v_role public.admin_role;
  v_candidate public.place_candidates;
  v_images jsonb;
  v_profile jsonb;
  v_missing text[];
  v_blockers text[];
  v_place public.places;
begin
  v_role := public.current_admin_role();
  if v_role not in ('owner', 'admin', 'editor') then
    raise exception 'Candidate publishing requires owner, admin, or editor access'
      using errcode = '42501';
  end if;

  select * into v_candidate
  from public.place_candidates
  where id = p_candidate_id and status = 'pending_review'
  for update;
  if not found then
    raise exception 'Pending candidate % was not found', p_candidate_id using errcode = 'P0002';
  end if;

  select coalesce(jsonb_agg(jsonb_build_object(
    'image_url', image.image_url,
    'thumbnail_url', image.thumbnail_url
  ) order by image.sort_order, image.id), '[]'::jsonb)
  into v_images
  from public.place_candidate_images image
  where image.candidate_id = v_candidate.id;
  v_profile := jsonb_build_object(
    'summary', v_candidate.summary,
    'lat', v_candidate.lat,
    'lng', v_candidate.lng,
    'source', v_candidate.source
  );
  v_missing := public.selected_place_profile_missing_fields(v_profile, v_images);
  v_blockers := public.selected_place_publish_blockers(v_profile, v_images);
  if cardinality(v_missing) > 0 or cardinality(v_blockers) > 0 then
    raise exception 'Candidate is not ready to publish. Missing: %, blockers: %', v_missing, v_blockers
      using errcode = '22023';
  end if;
  if v_candidate.county_id is null then
    raise exception 'Candidate county is required' using errcode = '22023';
  end if;

  insert into public.places (
    id, county_id, name, type, summary, description, location, source,
    source_url, licence, external_id, last_verified_at, content_origin, reviewed_at
  ) values (
    v_candidate.source_place_id, v_candidate.county_id, v_candidate.name, v_candidate.type,
    v_candidate.summary, v_candidate.description,
    st_setsrid(st_makepoint(v_candidate.lng, v_candidate.lat), 4326), v_candidate.source,
    v_candidate.source_url, v_candidate.licence, v_candidate.external_id,
    v_candidate.last_verified_at, 'candidate_review', now()
  ) on conflict (id) do nothing
  returning * into v_place;

  if v_place is null then
    select * into v_place from public.places where id = v_candidate.source_place_id;
  end if;

  insert into public.place_images (
    id, place_id, sort_order, image_url, thumbnail_url, width, height, source,
    source_url, licence, licence_url, attribution, external_id, last_verified_at
  )
  select
    image.source_image_id, v_place.id, image.sort_order, image.image_url, image.thumbnail_url,
    image.width, image.height, image.source, image.source_url, image.licence, image.licence_url,
    image.attribution, image.external_id, image.last_verified_at
  from public.place_candidate_images image
  where image.candidate_id = v_candidate.id
  on conflict (id) do nothing;

  update public.place_candidates
  set
    status = 'published',
    published_place_id = v_place.id,
    review_note = nullif(btrim(p_review_note), ''),
    reviewed_at = now(),
    reviewed_by = auth.uid(),
    missing_fields = v_missing,
    publish_blockers = v_blockers,
    completeness = 100
  where id = v_candidate.id;

  return v_place;
end;
$$;

revoke all on function public.get_place_candidate_dashboard(uuid) from public;
revoke all on function public.update_place_candidate_dashboard(uuid, smallint, text, text, text, text, text, text, text, date, double precision, double precision) from public;
revoke all on function public.reject_place_candidate_dashboard(uuid, text) from public;
revoke all on function public.publish_place_candidate_dashboard(uuid, text) from public;

grant execute on function public.get_place_candidate_dashboard(uuid) to authenticated;
grant execute on function public.update_place_candidate_dashboard(uuid, smallint, text, text, text, text, text, text, text, date, double precision, double precision) to authenticated;
grant execute on function public.reject_place_candidate_dashboard(uuid, text) to authenticated;
grant execute on function public.publish_place_candidate_dashboard(uuid, text) to authenticated;
