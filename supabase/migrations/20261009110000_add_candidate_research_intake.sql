-- Research leads are intentionally private candidate records. A lead may name
-- a place, but it is never evidence for the public place profile.

alter table public.place_candidates
  alter column source_place_id drop not null,
  alter column type set default 'place',
  add column if not exists intake_source text,
  add column if not exists intake_source_url text,
  add column if not exists intake_key text,
  add column if not exists research_status text not null default 'not_requested'
    check (research_status in ('not_requested', 'pending_research', 'researched')),
  add column if not exists research_notes jsonb not null default '[]'::jsonb,
  add column if not exists research_sources jsonb not null default '[]'::jsonb,
  add column if not exists research_model text,
  add column if not exists researched_at timestamptz,
  add column if not exists researched_by uuid references auth.users (id) on delete set null;

create unique index if not exists place_candidates_intake_key_idx
  on public.place_candidates (intake_key)
  where intake_key is not null;

-- Candidate leads must use a role-checked RPC. The submitted site/page is
-- provenance only; reviewers later choose the evidence used for publication.
create or replace function public.create_place_candidate_leads_dashboard(
  p_source_name text,
  p_source_url text,
  p_county_id smallint,
  p_names text[]
)
returns table (
  requested_name text,
  candidate_id uuid,
  outcome text,
  matched_name text
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_role public.admin_role;
  v_source_name text := nullif(btrim(p_source_name), '');
  v_source_url text := nullif(btrim(p_source_url), '');
  v_name text;
  v_key text;
  v_existing uuid;
  v_existing_name text;
  v_candidate uuid;
  v_missing text[] := array['research', 'summary', 'coordinates', 'image'];
  v_blockers text[] := array['source'];
begin
  v_role := public.current_admin_role();
  if v_role not in ('owner', 'admin', 'editor') then
    raise exception 'Candidate intake requires owner, admin, or editor access'
      using errcode = '42501';
  end if;
  if v_source_name is null or v_source_url is null or v_source_url !~ '^https?://' then
    raise exception 'A source name and valid https URL are required' using errcode = '22023';
  end if;
  if p_county_id is null or not exists (select 1 from public.counties where id = p_county_id) then
    raise exception 'A valid county is required' using errcode = '22023';
  end if;
  if coalesce(cardinality(p_names), 0) not between 1 and 50 then
    raise exception 'Enter between 1 and 50 place names' using errcode = '22023';
  end if;

  for v_name in
    select distinct btrim(value)
    from unnest(p_names) value
    where length(btrim(value)) between 3 and 120
  loop
    v_key := md5(lower(v_source_url) || '|' || p_county_id::text || '|' || lower(v_name));

    select p.id, p.name into v_existing, v_existing_name
    from public.places p
    where p.county_id = p_county_id and lower(btrim(p.name)) = lower(v_name)
    limit 1;
    if v_existing is not null then
      return query select v_name, v_existing, 'already_published'::text, v_existing_name;
      continue;
    end if;

    select c.id, c.name into v_existing, v_existing_name
    from public.place_candidates c
    where c.county_id = p_county_id
      and lower(btrim(c.name)) = lower(v_name)
      and c.status in ('pending_review', 'published')
    limit 1;
    if v_existing is not null then
      return query select v_name, v_existing, 'already_queued'::text, v_existing_name;
      continue;
    end if;

    insert into public.place_candidates (
      county_id, name, type, intake_source, intake_source_url, intake_key,
      research_status, completeness, missing_fields, publish_blockers
    ) values (
      p_county_id, v_name, 'place', v_source_name, v_source_url, v_key,
      'pending_research', 0, v_missing, v_blockers
    ) returning id into v_candidate;

    return query select v_name, v_candidate, 'created'::text, null::text;
  end loop;
end;
$$;

-- This applies a browser-visible AI draft to a private candidate only. The
-- function revalidates the editor role and recomputes publication readiness;
-- it has no write path to public.places.
create or replace function public.apply_place_candidate_ai_draft_dashboard(
  p_candidate_id uuid,
  p_county_id smallint,
  p_draft jsonb,
  p_model text
)
returns public.place_candidates
language plpgsql
security definer
set search_path = public
as $$
declare
  v_role public.admin_role;
  v_candidate public.place_candidates;
  v_county_id smallint;
  v_type text;
  v_summary text;
  v_description text;
  v_source text;
  v_source_url text;
  v_licence text;
  v_lat double precision;
  v_lng double precision;
  v_images jsonb;
  v_profile jsonb;
  v_missing text[];
  v_blockers text[];
begin
  v_role := public.current_admin_role();
  if v_role not in ('owner', 'admin', 'editor') then
    raise exception 'Candidate research requires owner, admin, or editor access'
      using errcode = '42501';
  end if;
  if jsonb_typeof(p_draft) <> 'object' then
    raise exception 'AI draft is invalid' using errcode = '22023';
  end if;

  select * into v_candidate
  from public.place_candidates
  where id = p_candidate_id and status = 'pending_review'
  for update;
  if not found then
    raise exception 'Pending candidate % was not found', p_candidate_id using errcode = 'P0002';
  end if;

  v_county_id := coalesce(p_county_id, v_candidate.county_id);
  if v_county_id is null or not exists (select 1 from public.counties where id = v_county_id) then
    raise exception 'AI research did not identify a valid county' using errcode = '22023';
  end if;
  v_type := coalesce(nullif(btrim(p_draft ->> 'type'), ''), v_candidate.type, 'place');
  v_summary := nullif(btrim(p_draft ->> 'summary'), '');
  v_description := nullif(btrim(p_draft ->> 'description'), '');
  v_source := nullif(btrim(p_draft ->> 'source'), '');
  v_source_url := nullif(btrim(p_draft ->> 'source_url'), '');
  v_licence := nullif(btrim(p_draft ->> 'licence'), '');
  v_lat := nullif(p_draft ->> 'lat', '')::double precision;
  v_lng := nullif(p_draft ->> 'lng', '')::double precision;
  if (v_lat is not null and (v_lat < -90 or v_lat > 90))
    or (v_lng is not null and (v_lng < -180 or v_lng > 180)) then
    raise exception 'AI draft coordinates are invalid' using errcode = '22023';
  end if;
  if v_source_url is not null and v_source_url !~ '^https?://' then
    v_source_url := null;
  end if;

  select coalesce(jsonb_agg(jsonb_build_object(
    'image_url', image.image_url,
    'thumbnail_url', image.thumbnail_url
  ) order by image.sort_order, image.id), '[]'::jsonb)
  into v_images
  from public.place_candidate_images image
  where image.candidate_id = v_candidate.id;
  v_profile := jsonb_build_object('summary', v_summary, 'lat', v_lat, 'lng', v_lng, 'source', v_source);
  v_missing := public.selected_place_profile_missing_fields(v_profile, v_images);
  v_blockers := public.selected_place_publish_blockers(v_profile, v_images);

  update public.place_candidates
  set
    county_id = v_county_id,
    type = v_type,
    summary = v_summary,
    description = v_description,
    source = v_source,
    source_url = v_source_url,
    licence = v_licence,
    lat = v_lat,
    lng = v_lng,
    research_status = 'researched',
    research_notes = case when jsonb_typeof(p_draft -> 'notes') = 'array' then p_draft -> 'notes' else '[]'::jsonb end,
    research_sources = case when jsonb_typeof(p_draft -> 'sources') = 'array' then p_draft -> 'sources' else '[]'::jsonb end,
    research_model = nullif(btrim(p_model), ''),
    researched_at = now(),
    researched_by = auth.uid(),
    completeness = round((3 - cardinality(v_missing)) * 100.0 / 3.0)::smallint,
    missing_fields = v_missing,
    publish_blockers = v_blockers
  where id = v_candidate.id
  returning * into v_candidate;

  return v_candidate;
end;
$$;

-- Candidate-created places do not have a Dev UUID to preserve. Their own
-- candidate UUID becomes the new public place UUID once publication passes.
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
  v_place_id uuid;
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
    'summary', v_candidate.summary, 'lat', v_candidate.lat,
    'lng', v_candidate.lng, 'source', v_candidate.source
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
    id, place_id, sort_order, image_url, thumbnail_url, width, height, source,
    source_url, licence, licence_url, attribution, external_id, last_verified_at
  )
  select image.source_image_id, v_place.id, image.sort_order, image.image_url, image.thumbnail_url,
    image.width, image.height, image.source, image.source_url, image.licence, image.licence_url,
    image.attribution, image.external_id, image.last_verified_at
  from public.place_candidate_images image
  where image.candidate_id = v_candidate.id
  on conflict (id) do nothing;

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
    'id', candidate.id, 'source_place_id', candidate.source_place_id,
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
      'image_url', image.image_url, 'thumbnail_url', image.thumbnail_url, 'source', image.source,
      'source_url', image.source_url, 'licence', image.licence, 'licence_url', image.licence_url,
      'attribution', image.attribution, 'external_id', image.external_id,
      'last_verified_at', image.last_verified_at
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

drop function if exists public.list_place_candidates_dashboard(text);
create function public.list_place_candidates_dashboard(p_status text default 'pending_review')
returns table (
  id uuid, source_place_id uuid, county_name text, name text, type text, summary text,
  completeness smallint, missing_fields text[], publish_blockers text[], status text,
  imported_at timestamptz, thumbnail_url text, image_count bigint, intake_source text,
  research_status text
)
language plpgsql
security definer
set search_path = public
as $$
declare v_role public.admin_role;
begin
  v_role := public.current_admin_role();
  if v_role not in ('owner', 'admin', 'editor') then
    raise exception 'Candidate review requires owner, admin, or editor access' using errcode = '42501';
  end if;
  if p_status not in ('pending_review', 'rejected', 'published') then
    raise exception 'Unknown candidate status' using errcode = '22023';
  end if;
  return query
  select candidate.id, candidate.source_place_id, county.name, candidate.name, candidate.type,
    candidate.summary, candidate.completeness, candidate.missing_fields, candidate.publish_blockers,
    candidate.status, candidate.imported_at, image.thumbnail_url, coalesce(images.image_count, 0),
    candidate.intake_source, candidate.research_status
  from public.place_candidates candidate
  left join public.counties county on county.id = candidate.county_id
  left join lateral (
    select candidate_image.thumbnail_url from public.place_candidate_images candidate_image
    where candidate_image.candidate_id = candidate.id
    order by candidate_image.sort_order, candidate_image.id limit 1
  ) image on true
  left join lateral (
    select count(*)::bigint as image_count from public.place_candidate_images candidate_image
    where candidate_image.candidate_id = candidate.id
  ) images on true
  where candidate.status = p_status
  order by candidate.imported_at desc, candidate.name;
end;
$$;

revoke all on function public.create_place_candidate_leads_dashboard(text, text, smallint, text[]) from public;
revoke all on function public.apply_place_candidate_ai_draft_dashboard(uuid, smallint, jsonb, text) from public;
revoke all on function public.publish_place_candidate_dashboard(uuid, text) from public;
revoke all on function public.get_place_candidate_dashboard(uuid) from public;
revoke all on function public.list_place_candidates_dashboard(text) from public;
grant execute on function public.create_place_candidate_leads_dashboard(text, text, smallint, text[]) to authenticated;
grant execute on function public.apply_place_candidate_ai_draft_dashboard(uuid, smallint, jsonb, text) to authenticated;
grant execute on function public.publish_place_candidate_dashboard(uuid, text) to authenticated;
grant execute on function public.get_place_candidate_dashboard(uuid) to authenticated;
grant execute on function public.list_place_candidates_dashboard(text) to authenticated;
