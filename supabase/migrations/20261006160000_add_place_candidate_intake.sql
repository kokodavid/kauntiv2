-- Candidate intake is deliberately separate from public.places. App users can
-- read places, while candidates remain dashboard-only until the import path
-- proves the existing three-part profile is complete: summary, coordinates,
-- and at least one image.

alter table public.places
  drop constraint if exists places_content_origin_check;

alter table public.places
  add constraint places_content_origin_check
  check (content_origin in ('dashboard', 'seed_migration', 'selected_dev_import'));

create table public.place_candidates (
  id uuid primary key default gen_random_uuid(),
  source_place_id uuid not null unique,
  county_id smallint references public.counties (id),
  name text not null,
  type text not null,
  summary text,
  description text,
  lat double precision,
  lng double precision,
  source text,
  source_url text,
  licence text,
  external_id text,
  last_verified_at date,
  completeness smallint not null check (completeness between 0 and 100),
  missing_fields text[] not null default '{}',
  publish_blockers text[] not null default '{}',
  status text not null default 'pending_review'
    check (status in ('pending_review', 'rejected', 'published')),
  published_place_id uuid references public.places (id) on delete set null,
  review_note text,
  imported_at timestamptz not null default now(),
  reviewed_at timestamptz,
  reviewed_by uuid references auth.users (id) on delete set null,
  updated_at timestamptz not null default now()
);

create table public.place_candidate_images (
  id uuid primary key default gen_random_uuid(),
  candidate_id uuid not null references public.place_candidates (id) on delete cascade,
  source_image_id uuid not null unique,
  sort_order integer not null default 0,
  image_url text,
  thumbnail_url text,
  width integer,
  height integer,
  source text,
  source_url text,
  licence text,
  licence_url text,
  attribution text,
  external_id text,
  last_verified_at date
);

create index place_candidates_status_imported_idx
  on public.place_candidates (status, imported_at desc);

create index place_candidate_images_candidate_id_idx
  on public.place_candidate_images (candidate_id, sort_order);

alter table public.place_candidates enable row level security;
alter table public.place_candidate_images enable row level security;

create or replace function public.set_place_candidate_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists set_place_candidate_updated_at on public.place_candidates;

create trigger set_place_candidate_updated_at
  before update on public.place_candidates
  for each row execute function public.set_place_candidate_updated_at();

create or replace function public.selected_place_profile_missing_fields(
  p_place jsonb,
  p_images jsonb
)
returns text[]
language sql
immutable
set search_path = public
as $$
  select array_remove(array[
    case when nullif(btrim(p_place ->> 'summary'), '') is null then 'summary' end,
    case when nullif(p_place ->> 'lat', '') is null or nullif(p_place ->> 'lng', '') is null then 'coordinates' end,
    case when jsonb_array_length(coalesce(p_images, '[]'::jsonb)) = 0 then 'image' end
  ], null);
$$;

create or replace function public.selected_place_publish_blockers(
  p_place jsonb,
  p_images jsonb
)
returns text[]
language sql
immutable
set search_path = public
as $$
  select array_remove(array[
    case when nullif(btrim(p_place ->> 'source'), '') is null then 'source' end,
    case when exists (
      select 1
      from jsonb_array_elements(coalesce(p_images, '[]'::jsonb)) image
      where coalesce(image.value ->> 'image_url', '') like '%/storage/v1/object/%'
         or coalesce(image.value ->> 'thumbnail_url', '') like '%/storage/v1/object/%'
    ) then 'image transfer' end
  ], null);
$$;

-- This RPC is for the trusted selected-place import tool. It is intentionally
-- unavailable to dashboard/browser clients: all human review happens through
-- later dashboard RPCs, and the app never receives candidate records.
create or replace function public.import_selected_dev_place(
  p_place jsonb,
  p_images jsonb default '[]'::jsonb
)
returns table (
  destination text,
  place_id uuid,
  candidate_id uuid,
  completeness smallint,
  missing_fields text[],
  publish_blockers text[]
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_source_place_id uuid := (p_place ->> 'id')::uuid;
  v_county_id smallint := (p_place ->> 'county_id')::smallint;
  v_lat double precision := (p_place ->> 'lat')::double precision;
  v_lng double precision := (p_place ->> 'lng')::double precision;
  v_missing text[] := public.selected_place_profile_missing_fields(p_place, p_images);
  v_blockers text[] := public.selected_place_publish_blockers(p_place, p_images);
  v_completeness smallint := round((3 - cardinality(v_missing)) * 100.0 / 3.0)::smallint;
  v_candidate_id uuid;
  v_candidate_is_pending boolean;
begin
  if v_source_place_id is null or v_county_id is null
    or nullif(btrim(p_place ->> 'name'), '') is null
    or nullif(btrim(p_place ->> 'type'), '') is null then
    raise exception 'Selected place must include id, county_id, name, and type'
      using errcode = '22023';
  end if;

  if (v_lat is not null and (v_lat < -90 or v_lat > 90))
    or (v_lng is not null and (v_lng < -180 or v_lng > 180)) then
    raise exception 'Selected place coordinates are invalid' using errcode = '22023';
  end if;

  if cardinality(v_missing) = 0 and cardinality(v_blockers) = 0 then
    insert into public.places (
      id, county_id, name, type, summary, description, location, source,
      source_url, licence, external_id, last_verified_at, content_origin, reviewed_at
    ) values (
      v_source_place_id, v_county_id, btrim(p_place ->> 'name'), btrim(p_place ->> 'type'),
      nullif(btrim(p_place ->> 'summary'), ''), nullif(btrim(p_place ->> 'description'), ''),
      st_setsrid(st_makepoint(v_lng, v_lat), 4326), nullif(btrim(p_place ->> 'source'), ''),
      nullif(btrim(p_place ->> 'source_url'), ''), nullif(btrim(p_place ->> 'licence'), ''),
      nullif(btrim(p_place ->> 'external_id'), ''), nullif(p_place ->> 'last_verified_at', '')::date,
      'selected_dev_import', now()
    ) on conflict (id) do nothing;

    insert into public.place_images (
      id, place_id, sort_order, image_url, thumbnail_url, width, height, source,
      source_url, licence, licence_url, attribution, external_id, last_verified_at
    )
    select
      (image.value ->> 'id')::uuid, v_source_place_id,
      coalesce((image.value ->> 'sort_order')::integer, 0), image.value ->> 'image_url',
      image.value ->> 'thumbnail_url', (image.value ->> 'width')::integer,
      (image.value ->> 'height')::integer, image.value ->> 'source', image.value ->> 'source_url',
      image.value ->> 'licence', image.value ->> 'licence_url', image.value ->> 'attribution',
      image.value ->> 'external_id', nullif(image.value ->> 'last_verified_at', '')::date
    from jsonb_array_elements(coalesce(p_images, '[]'::jsonb)) image
    on conflict (id) do nothing;

    return query select 'published'::text, v_source_place_id, null::uuid, 100::smallint, '{}'::text[], '{}'::text[];
    return;
  end if;

  insert into public.place_candidates (
    source_place_id, county_id, name, type, summary, description, lat, lng,
    source, source_url, licence, external_id, last_verified_at, completeness, missing_fields, publish_blockers
  ) values (
    v_source_place_id, v_county_id, btrim(p_place ->> 'name'), btrim(p_place ->> 'type'),
    nullif(btrim(p_place ->> 'summary'), ''), nullif(btrim(p_place ->> 'description'), ''), v_lat, v_lng,
    nullif(btrim(p_place ->> 'source'), ''), nullif(btrim(p_place ->> 'source_url'), ''),
    nullif(btrim(p_place ->> 'licence'), ''), nullif(btrim(p_place ->> 'external_id'), ''),
    nullif(p_place ->> 'last_verified_at', '')::date, v_completeness, v_missing, v_blockers
  ) on conflict (source_place_id) do update set
    county_id = excluded.county_id, name = excluded.name, type = excluded.type,
    summary = excluded.summary, description = excluded.description, lat = excluded.lat, lng = excluded.lng,
    source = excluded.source, source_url = excluded.source_url, licence = excluded.licence,
    external_id = excluded.external_id, last_verified_at = excluded.last_verified_at,
    completeness = excluded.completeness, missing_fields = excluded.missing_fields,
    publish_blockers = excluded.publish_blockers
  where public.place_candidates.status = 'pending_review'
  returning id into v_candidate_id;

  if v_candidate_id is null then
    select id, status = 'pending_review'
    into v_candidate_id, v_candidate_is_pending
    from public.place_candidates
    where source_place_id = v_source_place_id;
  else
    v_candidate_is_pending := true;
  end if;

  if not v_candidate_is_pending then
    return query select 'candidate'::text, null::uuid, v_candidate_id, v_completeness, v_missing, v_blockers;
    return;
  end if;

  insert into public.place_candidate_images (
    candidate_id, source_image_id, sort_order, image_url, thumbnail_url, width, height,
    source, source_url, licence, licence_url, attribution, external_id, last_verified_at
  )
  select
    v_candidate_id, (image.value ->> 'id')::uuid, coalesce((image.value ->> 'sort_order')::integer, 0),
    image.value ->> 'image_url', image.value ->> 'thumbnail_url', (image.value ->> 'width')::integer,
    (image.value ->> 'height')::integer, image.value ->> 'source', image.value ->> 'source_url',
    image.value ->> 'licence', image.value ->> 'licence_url', image.value ->> 'attribution',
    image.value ->> 'external_id', nullif(image.value ->> 'last_verified_at', '')::date
  from jsonb_array_elements(coalesce(p_images, '[]'::jsonb)) image
  on conflict (source_image_id) do update set
    candidate_id = excluded.candidate_id, sort_order = excluded.sort_order,
    image_url = excluded.image_url, thumbnail_url = excluded.thumbnail_url,
    width = excluded.width, height = excluded.height, source = excluded.source,
    source_url = excluded.source_url, licence = excluded.licence,
    licence_url = excluded.licence_url, attribution = excluded.attribution,
    external_id = excluded.external_id, last_verified_at = excluded.last_verified_at;

  return query select 'candidate'::text, null::uuid, v_candidate_id, v_completeness, v_missing, v_blockers;
end;
$$;

revoke all on function public.import_selected_dev_place(jsonb, jsonb) from public;
grant execute on function public.import_selected_dev_place(jsonb, jsonb) to service_role;

-- Candidate rows have no browser RLS policy. This limited projection is the
-- dashboard's only read path, and its role check keeps source records out of
-- the app and ordinary authenticated users.
create or replace function public.list_place_candidates_dashboard(
  p_status text default 'pending_review'
)
returns table (
  id uuid,
  source_place_id uuid,
  county_name text,
  name text,
  type text,
  summary text,
  completeness smallint,
  missing_fields text[],
  publish_blockers text[],
  status text,
  imported_at timestamptz,
  thumbnail_url text,
  image_count bigint
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_role public.admin_role;
begin
  v_role := public.current_admin_role();
  if v_role not in ('owner', 'admin', 'editor') then
    raise exception 'Candidate review requires owner, admin, or editor access'
      using errcode = '42501';
  end if;

  if p_status not in ('pending_review', 'rejected', 'published') then
    raise exception 'Unknown candidate status' using errcode = '22023';
  end if;

  return query
  select
    candidate.id,
    candidate.source_place_id,
    county.name,
    candidate.name,
    candidate.type,
    candidate.summary,
    candidate.completeness,
    candidate.missing_fields,
    candidate.publish_blockers,
    candidate.status,
    candidate.imported_at,
    image.thumbnail_url,
    coalesce(images.image_count, 0)
  from public.place_candidates candidate
  left join public.counties county on county.id = candidate.county_id
  left join lateral (
    select candidate_image.thumbnail_url
    from public.place_candidate_images candidate_image
    where candidate_image.candidate_id = candidate.id
    order by candidate_image.sort_order, candidate_image.id
    limit 1
  ) image on true
  left join lateral (
    select count(*)::bigint as image_count
    from public.place_candidate_images candidate_image
    where candidate_image.candidate_id = candidate.id
  ) images on true
  where candidate.status = p_status
  order by candidate.imported_at desc, candidate.name;
end;
$$;

revoke all on function public.list_place_candidates_dashboard(text) from public;
grant execute on function public.list_place_candidates_dashboard(text) to authenticated;
