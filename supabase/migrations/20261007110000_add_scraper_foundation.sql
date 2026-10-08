-- Scraper foundation: a source registry, run log, candidate identity for
-- scraped records, candidate revisions, and private candidate assets.
--
-- Scrapers can only ever reach `public.place_candidates` through the
-- service-role RPCs below. Nothing here writes to `public.places`, and the
-- existing dashboard publish RPC refuses scraper candidates until the
-- reviewed-asset publish workflow exists (see the guard at the end).

-- ---------------------------------------------------------------------------
-- Source registry and runs
-- ---------------------------------------------------------------------------

create table public.scrape_sources (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique check (slug ~ '^[a-z0-9][a-z0-9_-]*$'),
  name text not null,
  kind text not null check (kind in ('wikidata', 'openstreetmap', 'wikimedia_commons')),
  -- Gates scheduled runs only; a person can still start a manual run.
  enabled boolean not null default false,
  config jsonb not null default '{}'::jsonb,
  licence_policy text,
  max_items_per_run integer not null default 200 check (max_items_per_run > 0),
  -- Where the next run resumes. Only advanced by a successful live run.
  checkpoint jsonb not null default '{}'::jsonb,
  checkpoint_updated_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.scrape_runs (
  id uuid primary key default gen_random_uuid(),
  source_id uuid not null references public.scrape_sources (id) on delete cascade,
  status text not null default 'running'
    check (status in ('running', 'succeeded', 'partial', 'failed')),
  triggered_by text not null default 'schedule' check (triggered_by in ('schedule', 'manual')),
  dry_run boolean not null default false,
  started_at timestamptz not null default now(),
  finished_at timestamptz,
  checkpoint_before jsonb,
  checkpoint_after jsonb,
  items_seen integer not null default 0,
  created_count integer not null default 0,
  updated_count integer not null default 0,
  revision_count integer not null default 0,
  unchanged_count integer not null default 0,
  duplicate_count integer not null default 0,
  rejected_count integer not null default 0,
  error_count integer not null default 0,
  errors jsonb not null default '[]'::jsonb,
  error_summary text
);

-- At most one live run per source: overlapping runs are impossible.
create unique index scrape_runs_one_running_idx
  on public.scrape_runs (source_id) where status = 'running';
create index scrape_runs_source_started_idx
  on public.scrape_runs (source_id, started_at desc);

alter table public.scrape_sources enable row level security;
alter table public.scrape_runs enable row level security;

create trigger set_scrape_source_updated_at
  before update on public.scrape_sources
  for each row execute function public.set_place_candidate_updated_at();

-- ---------------------------------------------------------------------------
-- Candidate identity for scraped records
-- ---------------------------------------------------------------------------

alter table public.place_candidates
  alter column source_place_id drop not null,
  add column origin text not null default 'dev_import'
    check (origin in ('dev_import', 'scraper')),
  add column scrape_source_id uuid references public.scrape_sources (id),
  add column source_item_key text,
  add column content_hash text,
  add column last_scrape_run_id uuid references public.scrape_runs (id) on delete set null,
  -- Equals updated_at right after a scraper write; a later human edit moves
  -- updated_at past it, which is how an edited candidate is recognised.
  add column content_synced_at timestamptz;

alter table public.place_candidates
  add constraint place_candidates_identity_check check (
    (origin = 'dev_import'
      and source_place_id is not null
      and scrape_source_id is null
      and source_item_key is null)
    or
    (origin = 'scraper'
      and source_place_id is null
      and scrape_source_id is not null
      and source_item_key is not null)
  );

-- Authoritative dedupe: one candidate per (source, item key).
create unique index place_candidates_scraper_item_idx
  on public.place_candidates (scrape_source_id, source_item_key)
  where origin = 'scraper';

-- ---------------------------------------------------------------------------
-- Candidate images: private assets
-- ---------------------------------------------------------------------------

alter table public.place_candidate_images
  alter column source_image_id drop not null,
  add column scrape_image_key text,
  add column remote_url text,
  add column staging_path text,
  add column staged_at timestamptz,
  add column approved_at timestamptz,
  add column approved_by uuid references auth.users (id) on delete set null;

alter table public.place_candidate_images
  add constraint place_candidate_images_identity_check
  check (source_image_id is not null or scrape_image_key is not null);

create unique index place_candidate_images_scrape_key_idx
  on public.place_candidate_images (candidate_id, scrape_image_key)
  where scrape_image_key is not null;

-- Private bucket with no policies: only the service role can read or write
-- it. The dashboard previews staged images through signed URLs.
insert into storage.buckets (id, name, public)
values ('place-candidate-staging', 'place-candidate-staging', false)
on conflict (id) do update set public = false;

-- ---------------------------------------------------------------------------
-- Revisions: scraper updates that must not overwrite an editor's work
-- ---------------------------------------------------------------------------

create table public.place_candidate_revisions (
  id uuid primary key default gen_random_uuid(),
  candidate_id uuid not null references public.place_candidates (id) on delete cascade,
  scrape_run_id uuid references public.scrape_runs (id) on delete set null,
  content_hash text not null,
  proposed jsonb not null,
  status text not null default 'pending' check (status in ('pending', 'accepted', 'dismissed')),
  created_at timestamptz not null default now(),
  resolved_at timestamptz,
  resolved_by uuid references auth.users (id) on delete set null,
  unique (candidate_id, content_hash)
);

create index place_candidate_revisions_pending_idx
  on public.place_candidate_revisions (candidate_id) where status = 'pending';

alter table public.place_candidate_revisions enable row level security;

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

create or replace function public.scraper_normalize_name(p_name text)
returns text
language sql
immutable
set search_path = public
as $$
  select btrim(regexp_replace(lower(coalesce(p_name, '')), '[^[:alnum:]]+', ' ', 'g'));
$$;

-- Hash of the content an editor would review. Coordinates are rounded so
-- sub-metre noise at the source does not look like a change.
create or replace function public.scraper_content_hash(p_item jsonb)
returns text
language sql
immutable
set search_path = public
as $$
  select encode(sha256(convert_to(jsonb_build_object(
    'name', btrim(coalesce(p_item ->> 'name', '')),
    'type', btrim(coalesce(p_item ->> 'type', '')),
    'summary', btrim(coalesce(p_item ->> 'summary', '')),
    'description', btrim(coalesce(p_item ->> 'description', '')),
    'lat', round(nullif(p_item ->> 'lat', '')::numeric, 5),
    'lng', round(nullif(p_item ->> 'lng', '')::numeric, 5),
    'source', btrim(coalesce(p_item ->> 'source', '')),
    'source_url', btrim(coalesce(p_item ->> 'source_url', '')),
    'licence', btrim(coalesce(p_item ->> 'licence', '')),
    'images', coalesce((
      select jsonb_agg(jsonb_build_object(
        'key', image.value ->> 'key',
        'remote_url', image.value ->> 'remote_url',
        'licence', image.value ->> 'licence',
        'attribution', image.value ->> 'attribution'
      ) order by image.value ->> 'key')
      from jsonb_array_elements(coalesce(p_item -> 'images', '[]'::jsonb)) image
    ), '[]'::jsonb)
  )::text, 'utf8')), 'hex');
$$;

-- ---------------------------------------------------------------------------
-- Run lifecycle (service role only)
-- ---------------------------------------------------------------------------

create or replace function public.start_scrape_run(
  p_source_slug text,
  p_triggered_by text default 'schedule',
  p_dry_run boolean default false
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_source public.scrape_sources;
  v_run public.scrape_runs;
begin
  if p_triggered_by not in ('schedule', 'manual') then
    raise exception 'triggered_by must be schedule or manual' using errcode = '22023';
  end if;

  select * into v_source from public.scrape_sources where slug = p_source_slug for update;
  if not found then
    raise exception 'Unknown scrape source %', p_source_slug using errcode = 'P0002';
  end if;
  if p_triggered_by = 'schedule' and not v_source.enabled then
    raise exception 'Scrape source % is disabled', p_source_slug using errcode = '55000';
  end if;

  -- A run that never reported back (runner crash) must not block the source.
  update public.scrape_runs
  set status = 'failed', finished_at = now(), error_summary = 'Timed out without finishing'
  where source_id = v_source.id and status = 'running'
    and started_at < now() - interval '3 hours';

  begin
    insert into public.scrape_runs (source_id, triggered_by, dry_run, checkpoint_before)
    values (v_source.id, p_triggered_by, p_dry_run, v_source.checkpoint)
    returning * into v_run;
  exception when unique_violation then
    raise exception 'A run for % is already in progress', p_source_slug using errcode = '55P03';
  end;

  return jsonb_build_object(
    'run_id', v_run.id,
    'source', jsonb_build_object(
      'slug', v_source.slug, 'kind', v_source.kind, 'config', v_source.config,
      'max_items_per_run', v_source.max_items_per_run, 'licence_policy', v_source.licence_policy
    ),
    'checkpoint', v_source.checkpoint,
    'dry_run', p_dry_run
  );
end;
$$;

create or replace function public.finish_scrape_run(
  p_run_id uuid,
  p_status text,
  p_checkpoint jsonb default null,
  p_error_summary text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_run public.scrape_runs;
begin
  if p_status not in ('succeeded', 'partial', 'failed') then
    raise exception 'Invalid final status %', p_status using errcode = '22023';
  end if;

  update public.scrape_runs
  set status = p_status, finished_at = now(), checkpoint_after = p_checkpoint,
      error_summary = left(p_error_summary, 1000)
  where id = p_run_id and status = 'running'
  returning * into v_run;
  if not found then
    raise exception 'Running scrape run % was not found', p_run_id using errcode = 'P0002';
  end if;

  -- Only a clean live run moves the cursor; a failed or dry run retries from
  -- the same place next time.
  if p_status = 'succeeded' and not v_run.dry_run and p_checkpoint is not null then
    update public.scrape_sources
    set checkpoint = p_checkpoint, checkpoint_updated_at = now()
    where id = v_run.source_id;
  end if;
end;
$$;

-- ---------------------------------------------------------------------------
-- Ingest
-- ---------------------------------------------------------------------------

-- One item. Called inside a sub-transaction by ingest_scrape_items so a bad
-- item cannot abort the batch. Returns {outcome, ...}.
create or replace function public.scraper_ingest_item(
  p_run public.scrape_runs,
  p_source public.scrape_sources,
  p_item jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_key text := btrim(coalesce(p_item ->> 'key', ''));
  v_name text := btrim(coalesce(p_item ->> 'name', ''));
  v_type text := btrim(coalesce(p_item ->> 'type', ''));
  v_lat double precision;
  v_lng double precision;
  v_point geometry;
  v_county_id smallint;
  v_hint smallint;
  v_norm text;
  v_hash text;
  v_images jsonb;
  v_profile jsonb;
  v_missing text[];
  v_blockers text[];
  v_completeness smallint;
  v_candidate public.place_candidates;
  v_dupe_name text;
  v_near_name text;
  v_candidate_id uuid;
begin
  if v_key = '' or length(v_key) > 300 then
    return jsonb_build_object('outcome', 'rejected', 'reason', 'invalid_key');
  end if;
  if v_name = '' or length(v_name) > 200 or v_type = '' or length(v_type) > 60 then
    return jsonb_build_object('outcome', 'rejected', 'reason', 'invalid_name_or_type');
  end if;

  begin
    v_lat := (p_item ->> 'lat')::double precision;
    v_lng := (p_item ->> 'lng')::double precision;
  exception when others then
    return jsonb_build_object('outcome', 'rejected', 'reason', 'invalid_coordinates');
  end;
  if v_lat is null or v_lng is null then
    return jsonb_build_object('outcome', 'rejected', 'reason', 'no_coordinates');
  end if;
  if v_lat not between -90 and 90 or v_lng not between -180 and 180 then
    return jsonb_build_object('outcome', 'rejected', 'reason', 'invalid_coordinates');
  end if;

  -- The county comes from the boundary polygons, not from the source.
  v_point := st_setsrid(st_makepoint(v_lng, v_lat), 4326);
  select id into v_county_id from public.counties where st_covers(geometry, v_point) limit 1;
  if v_county_id is null then
    return jsonb_build_object('outcome', 'rejected', 'reason', 'outside_kenya');
  end if;
  if nullif(p_item ->> 'county_id', '') is not null then
    v_hint := (p_item ->> 'county_id')::smallint;
    if v_hint <> v_county_id then
      return jsonb_build_object(
        'outcome', 'rejected', 'reason', 'county_mismatch',
        'detail', format('assigned %s, coordinates are in %s', v_hint, v_county_id)
      );
    end if;
  end if;

  -- Images without a licence and attribution cannot be reviewed, so they
  -- are dropped rather than carried into the queue.
  select coalesce(jsonb_agg(image.value order by image.value ->> 'key'), '[]'::jsonb)
  into v_images
  from jsonb_array_elements(coalesce(p_item -> 'images', '[]'::jsonb)) image
  where nullif(btrim(image.value ->> 'key'), '') is not null
    and nullif(btrim(image.value ->> 'remote_url'), '') is not null
    and nullif(btrim(image.value ->> 'licence'), '') is not null
    and nullif(btrim(image.value ->> 'attribution'), '') is not null;
  if jsonb_array_length(v_images) > 10 then
    v_images := (select jsonb_agg(value) from (
      select value from jsonb_array_elements(v_images) limit 10
    ) first_ten);
  end if;
  p_item := jsonb_set(p_item, '{images}', v_images);

  v_hash := public.scraper_content_hash(p_item);
  v_norm := public.scraper_normalize_name(v_name);

  select * into v_candidate
  from public.place_candidates
  where origin = 'scraper' and scrape_source_id = p_source.id and source_item_key = v_key
  for update;

  if found then
    if v_candidate.content_hash = v_hash then
      return jsonb_build_object('outcome', 'unchanged');
    end if;
    if v_candidate.status <> 'pending_review' then
      return jsonb_build_object('outcome', 'skipped_reviewed', 'status', v_candidate.status);
    end if;

    -- Edited by a person since the last scraper write: propose, don't overwrite.
    if v_candidate.updated_at > coalesce(v_candidate.content_synced_at, '-infinity'::timestamptz) then
      if p_run.dry_run then
        return jsonb_build_object('outcome', 'revision');
      end if;
      update public.place_candidate_revisions
      set status = 'dismissed', resolved_at = now()
      where candidate_id = v_candidate.id and status = 'pending' and content_hash <> v_hash;
      insert into public.place_candidate_revisions (candidate_id, scrape_run_id, content_hash, proposed)
      values (v_candidate.id, p_run.id, v_hash, p_item)
      on conflict (candidate_id, content_hash) do nothing;
      return jsonb_build_object('outcome', 'revision', 'candidate_id', v_candidate.id);
    end if;

    -- Untouched since the scraper wrote it: refresh in place below.
    v_candidate_id := v_candidate.id;
  else
    -- Already a public place from this source item, or the same place by name.
    select p.name into v_dupe_name
    from public.places p
    where (p.source = coalesce(nullif(btrim(p_item ->> 'source'), ''), p_source.name)
           and p.external_id = coalesce(nullif(btrim(p_item ->> 'external_id'), ''), v_key))
       or (p.county_id = v_county_id and public.scraper_normalize_name(p.name) = v_norm)
       or (public.scraper_normalize_name(p.name) = v_norm
           and st_dwithin(p.location::geography, v_point::geography, 150))
    limit 1;
    if v_dupe_name is not null then
      return jsonb_build_object('outcome', 'duplicate', 'of', 'place', 'name', v_dupe_name);
    end if;

    select c.name into v_dupe_name
    from public.place_candidates c
    where c.county_id = v_county_id and public.scraper_normalize_name(c.name) = v_norm
    limit 1;
    if v_dupe_name is not null then
      return jsonb_build_object('outcome', 'duplicate', 'of', 'candidate', 'name', v_dupe_name);
    end if;
  end if;

  v_profile := jsonb_build_object(
    'summary', p_item ->> 'summary', 'lat', v_lat, 'lng', v_lng,
    'source', coalesce(nullif(btrim(p_item ->> 'source'), ''), p_source.name)
  );
  v_missing := public.selected_place_profile_missing_fields(v_profile, v_images);
  v_blockers := coalesce(
    public.selected_place_publish_blockers(v_profile, jsonb_build_array()), '{}'::text[]
  );
  -- Staged images still need a person to approve them before publication.
  if jsonb_array_length(v_images) > 0 then
    v_blockers := array_append(v_blockers, 'image review');
  end if;

  select p.name into v_near_name
  from public.places p
  where st_dwithin(p.location::geography, v_point::geography, 100)
  limit 1;
  if v_near_name is not null then
    v_blockers := array_append(v_blockers, 'possible duplicate: ' || v_near_name);
  end if;
  v_completeness := round((3 - cardinality(v_missing)) * 100.0 / 3.0)::smallint;

  if p_run.dry_run then
    return jsonb_build_object(
      'outcome', case when v_candidate_id is null then 'created' else 'updated' end
    );
  end if;

  if v_candidate_id is null then
    insert into public.place_candidates (
      origin, scrape_source_id, source_item_key, county_id, name, type, summary, description,
      lat, lng, source, source_url, licence, external_id, last_verified_at,
      completeness, missing_fields, publish_blockers, content_hash, last_scrape_run_id,
      content_synced_at
    ) values (
      'scraper', p_source.id, v_key, v_county_id, v_name, v_type,
      nullif(btrim(p_item ->> 'summary'), ''), nullif(btrim(p_item ->> 'description'), ''),
      v_lat, v_lng, coalesce(nullif(btrim(p_item ->> 'source'), ''), p_source.name),
      nullif(btrim(p_item ->> 'source_url'), ''), nullif(btrim(p_item ->> 'licence'), ''),
      coalesce(nullif(btrim(p_item ->> 'external_id'), ''), v_key),
      nullif(p_item ->> 'last_verified_at', '')::date,
      v_completeness, v_missing, v_blockers, v_hash, p_run.id, now()
    ) returning id into v_candidate_id;
  else
    update public.place_candidates
    set county_id = v_county_id, name = v_name, type = v_type,
        summary = nullif(btrim(p_item ->> 'summary'), ''),
        description = nullif(btrim(p_item ->> 'description'), ''),
        lat = v_lat, lng = v_lng,
        source = coalesce(nullif(btrim(p_item ->> 'source'), ''), p_source.name),
        source_url = nullif(btrim(p_item ->> 'source_url'), ''),
        licence = nullif(btrim(p_item ->> 'licence'), ''),
        last_verified_at = nullif(p_item ->> 'last_verified_at', '')::date,
        completeness = v_completeness, missing_fields = v_missing,
        publish_blockers = v_blockers, content_hash = v_hash,
        last_scrape_run_id = p_run.id, content_synced_at = now()
    where id = v_candidate_id;
  end if;

  insert into public.place_candidate_images (
    candidate_id, scrape_image_key, sort_order, remote_url, thumbnail_url, width, height,
    source, source_url, licence, licence_url, attribution, external_id, last_verified_at
  )
  select
    v_candidate_id, btrim(image.value ->> 'key'), (image.ordinality - 1)::integer,
    image.value ->> 'remote_url', image.value ->> 'thumbnail_url',
    nullif(image.value ->> 'width', '')::integer, nullif(image.value ->> 'height', '')::integer,
    coalesce(nullif(btrim(image.value ->> 'source'), ''), p_source.name),
    nullif(btrim(image.value ->> 'source_url'), ''), btrim(image.value ->> 'licence'),
    nullif(btrim(image.value ->> 'licence_url'), ''), btrim(image.value ->> 'attribution'),
    nullif(btrim(image.value ->> 'key'), ''), nullif(image.value ->> 'last_verified_at', '')::date
  from jsonb_array_elements(v_images) with ordinality as image(value, ordinality)
  on conflict (candidate_id, scrape_image_key) where scrape_image_key is not null do update
  set sort_order = excluded.sort_order, remote_url = excluded.remote_url,
      thumbnail_url = excluded.thumbnail_url, width = excluded.width, height = excluded.height,
      source_url = excluded.source_url, licence = excluded.licence,
      licence_url = excluded.licence_url, attribution = excluded.attribution;

  return jsonb_build_object(
    'outcome', case when v_candidate.id is null then 'created' else 'updated' end,
    'candidate_id', v_candidate_id
  );
end;
$$;

create or replace function public.ingest_scrape_items(p_run_id uuid, p_items jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_run public.scrape_runs;
  v_source public.scrape_sources;
  v_item jsonb;
  v_result jsonb;
  v_results jsonb := '[]'::jsonb;
  v_errors jsonb := '[]'::jsonb;
  v_created integer := 0;
  v_updated integer := 0;
  v_revisions integer := 0;
  v_unchanged integer := 0;
  v_duplicates integer := 0;
  v_rejected integer := 0;
  v_failed integer := 0;
begin
  if jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) > 100 then
    raise exception 'items must be an array of at most 100 entries' using errcode = '22023';
  end if;

  select * into v_run from public.scrape_runs where id = p_run_id and status = 'running' for update;
  if not found then
    raise exception 'Running scrape run % was not found', p_run_id using errcode = 'P0002';
  end if;
  select * into v_source from public.scrape_sources where id = v_run.source_id;

  for v_item in select value from jsonb_array_elements(p_items) loop
    begin
      v_result := public.scraper_ingest_item(v_run, v_source, v_item);
    exception when others then
      v_result := jsonb_build_object('outcome', 'error', 'detail', left(sqlerrm, 300));
    end;
    v_result := v_result || jsonb_build_object('key', v_item ->> 'key');
    v_results := v_results || jsonb_build_array(v_result);

    case v_result ->> 'outcome'
      when 'created' then v_created := v_created + 1;
      when 'updated' then v_updated := v_updated + 1;
      when 'revision' then v_revisions := v_revisions + 1;
      when 'unchanged', 'skipped_reviewed' then v_unchanged := v_unchanged + 1;
      when 'duplicate' then v_duplicates := v_duplicates + 1;
      when 'rejected' then v_rejected := v_rejected + 1;
      else
        v_failed := v_failed + 1;
        v_errors := v_errors || jsonb_build_array(v_result);
    end case;
  end loop;

  update public.scrape_runs
  set items_seen = items_seen + jsonb_array_length(p_items),
      created_count = created_count + v_created,
      updated_count = updated_count + v_updated,
      revision_count = revision_count + v_revisions,
      unchanged_count = unchanged_count + v_unchanged,
      duplicate_count = duplicate_count + v_duplicates,
      rejected_count = rejected_count + v_rejected,
      error_count = error_count + v_failed,
      -- Keep the log bounded.
      errors = (select coalesce(jsonb_agg(e), '[]'::jsonb) from (
        select e from jsonb_array_elements(errors || v_errors) e limit 50
      ) capped)
  where id = p_run_id;

  return v_results;
end;
$$;

revoke all on function public.scraper_ingest_item(public.scrape_runs, public.scrape_sources, jsonb) from public;
revoke all on function public.start_scrape_run(text, text, boolean) from public;
revoke all on function public.finish_scrape_run(uuid, text, jsonb, text) from public;
revoke all on function public.ingest_scrape_items(uuid, jsonb) from public;
grant execute on function public.start_scrape_run(text, text, boolean) to service_role;
grant execute on function public.finish_scrape_run(uuid, text, jsonb, text) to service_role;
grant execute on function public.ingest_scrape_items(uuid, jsonb) to service_role;

-- ---------------------------------------------------------------------------
-- Guard: scraper candidates are not published by the existing RPC
-- ---------------------------------------------------------------------------
-- The existing publish RPC copies candidate image URLs straight into
-- place_images and uses source_place_id as the place id. Neither is right for
-- a scraped candidate (private, unapproved assets and no source place), so it
-- is refused until the reviewed-asset publish workflow replaces this guard.

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

  if v_candidate.origin = 'scraper' then
    raise exception 'Scraped candidates are published through the reviewed-asset workflow'
      using errcode = '0A000';
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

revoke all on function public.publish_place_candidate_dashboard(uuid, text) from public;
grant execute on function public.publish_place_candidate_dashboard(uuid, text) to authenticated;
