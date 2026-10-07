-- Scraped image assets remain private until an editor approves them. The
-- service-role Edge Function owns storage copies; these RPCs own review and
-- publication state only.

alter table public.place_candidate_images
  add column if not exists review_status text not null default 'not_required'
    check (review_status in ('not_required', 'pending', 'approved', 'rejected', 'failed')),
  add column if not exists review_note text,
  add column if not exists reviewed_at timestamptz,
  add column if not exists reviewed_by uuid references auth.users (id) on delete set null,
  add column if not exists stage_failure_reason text,
  add column if not exists staged_content_type text,
  add column if not exists staged_bytes integer;

update public.place_candidate_images image
set review_status = 'pending'
from public.place_candidates candidate
where candidate.id = image.candidate_id
  and candidate.origin = 'scraper'
  and image.review_status = 'not_required';

create or replace function public.set_scraper_candidate_image_review_status()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if new.scrape_image_key is not null and new.source_image_id is null then
    new.review_status := coalesce(nullif(new.review_status, 'not_required'), 'pending');
  end if;
  return new;
end;
$$;

drop trigger if exists set_scraper_candidate_image_review_status on public.place_candidate_images;
create trigger set_scraper_candidate_image_review_status
  before insert on public.place_candidate_images
  for each row execute function public.set_scraper_candidate_image_review_status();

create or replace function public.reset_scraper_candidate_image_stage()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if new.scrape_image_key is not null
     and new.remote_url is distinct from old.remote_url then
    new.staging_path := null;
    new.staged_at := null;
    new.staged_content_type := null;
    new.staged_bytes := null;
    new.stage_failure_reason := null;
    new.review_status := 'pending';
    new.review_note := null;
    new.reviewed_at := null;
    new.reviewed_by := null;
    new.approved_at := null;
    new.approved_by := null;
  end if;
  return new;
end;
$$;

drop trigger if exists reset_scraper_candidate_image_stage on public.place_candidate_images;
create trigger reset_scraper_candidate_image_stage
  before update on public.place_candidate_images
  for each row execute function public.reset_scraper_candidate_image_stage();

create index if not exists place_candidate_images_review_idx
  on public.place_candidate_images (candidate_id, review_status);

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
    'origin', candidate.origin,
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
      'image_url', case when candidate.origin = 'scraper' then null else image.image_url end,
      'thumbnail_url', case when candidate.origin = 'scraper' then null else image.thumbnail_url end,
      'is_staged', image.staging_path is not null,
      'staged_at', image.staged_at,
      'staged_content_type', image.staged_content_type,
      'staged_bytes', image.staged_bytes,
      'review_status', image.review_status,
      'review_note', image.review_note,
      'reviewed_at', image.reviewed_at,
      'stage_failure_reason', image.stage_failure_reason,
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

create or replace function public.review_scraped_candidate_image_dashboard(
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
  v_candidate public.place_candidates;
  v_blockers text[];
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

  select candidate.* into v_candidate
  from public.place_candidates candidate
  where candidate.id = p_candidate_id and candidate.origin = 'scraper' and candidate.status = 'pending_review'
  for update;
  if not found then
    raise exception 'Pending scraped candidate % was not found', p_candidate_id using errcode = 'P0002';
  end if;

  if p_review_status = 'approved' then
    select * into v_image from public.place_candidate_images
    where id = p_image_id and candidate_id = p_candidate_id and staging_path is not null
    for update;
    if not found then
      raise exception 'Only a staged candidate image can be approved' using errcode = '22023';
    end if;
  else
    select * into v_image from public.place_candidate_images
    where id = p_image_id and candidate_id = p_candidate_id
    for update;
    if not found then
      raise exception 'Candidate image % was not found', p_image_id using errcode = 'P0002';
    end if;
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

  v_blockers := array_remove(array_remove(v_candidate.publish_blockers, 'image review'), 'approved image');
  if exists (
    select 1 from public.place_candidate_images
    where candidate_id = p_candidate_id and review_status in ('pending', 'failed')
  ) then
    v_blockers := array_append(v_blockers, 'image review');
  end if;
  if not exists (
    select 1 from public.place_candidate_images
    where candidate_id = p_candidate_id and review_status = 'approved' and staging_path is not null
  ) then
    v_blockers := array_append(v_blockers, 'approved image');
  end if;

  update public.place_candidates
  set publish_blockers = v_blockers
  where id = p_candidate_id;
  return v_image;
end;
$$;

create or replace function public.publish_scraped_place_candidate_dashboard(
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
  where id = p_candidate_id and origin = 'scraper' and status = 'pending_review'
  for update;
  if not found then
    raise exception 'Pending scraped candidate % was not found', p_candidate_id using errcode = 'P0002';
  end if;
  if exists (
    select 1 from public.place_candidate_images
    where candidate_id = p_candidate_id and review_status in ('pending', 'failed')
  ) then
    raise exception 'Every staged candidate image must be reviewed before publishing' using errcode = '22023';
  end if;
  if exists (
    select 1
    from public.place_candidate_images image
    where image.candidate_id = p_candidate_id
      and image.review_status = 'approved'
      and image.staging_path is not null
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
    'summary', v_candidate.summary,
    'lat', v_candidate.lat,
    'lng', v_candidate.lng,
    'source', v_candidate.source
  );
  v_missing := public.selected_place_profile_missing_fields(v_profile, v_images);
  v_blockers := array_remove(array_remove(v_candidate.publish_blockers, 'image review'), 'approved image');
  v_blockers := v_blockers || public.selected_place_publish_blockers(v_profile, v_images);
  if cardinality(v_missing) > 0 or cardinality(v_blockers) > 0 then
    raise exception 'Candidate is not ready to publish. Missing: %, blockers: %', v_missing, v_blockers using errcode = '22023';
  end if;
  if v_candidate.county_id is null then
    raise exception 'Candidate county is required' using errcode = '22023';
  end if;

  insert into public.places (
    id, county_id, name, type, summary, description, location, source,
    source_url, licence, external_id, last_verified_at, content_origin, reviewed_at
  ) values (
    gen_random_uuid(), v_candidate.county_id, v_candidate.name, v_candidate.type,
    v_candidate.summary, v_candidate.description,
    st_setsrid(st_makepoint(v_candidate.lng, v_candidate.lat), 4326), v_candidate.source,
    v_candidate.source_url, v_candidate.licence, v_candidate.external_id,
    v_candidate.last_verified_at, 'candidate_review', now()
  ) returning * into v_place;

  insert into public.place_images (
    id, place_id, sort_order, image_url, thumbnail_url, source, source_url,
    licence, licence_url, attribution, external_id, last_verified_at
  )
  select
    image.id, v_place.id, image.sort_order,
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
  where id = p_candidate_id;
  return v_place;
end;
$$;

revoke all on function public.get_place_candidate_dashboard(uuid) from public;
revoke all on function public.review_scraped_candidate_image_dashboard(uuid, uuid, text, text) from public;
revoke all on function public.publish_scraped_place_candidate_dashboard(uuid, jsonb, text) from public;
grant execute on function public.get_place_candidate_dashboard(uuid) to authenticated;
grant execute on function public.review_scraped_candidate_image_dashboard(uuid, uuid, text, text) to authenticated;
grant execute on function public.publish_scraped_place_candidate_dashboard(uuid, jsonb, text) to authenticated;
