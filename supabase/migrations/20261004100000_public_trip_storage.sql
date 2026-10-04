-- Public Trips pilot: all storage is private; RPCs return allowlisted projections.
create schema if not exists public_trip_private;
revoke all on schema public_trip_private from public, anon, authenticated;

alter table public.app_feature_flags
  drop constraint app_feature_flags_feature_key_check;
alter table public.app_feature_flags add constraint app_feature_flags_feature_key_check
  check (feature_key in ('county_news', 'public_trips_read', 'public_trips_publish'));
insert into public.app_feature_flags (feature_key, enabled) values
  ('public_trips_read', false), ('public_trips_publish', false);

-- One row per user who has prepared a public trip: an opaque author ID for
-- blocking (never the auth ID) and a publishing suspension. Publishing
-- eligibility itself is Pro (public.has_pro_at), not membership here.
create table public.public_trip_authors (
  user_id uuid primary key references auth.users(id) on delete cascade,
  author_id uuid not null unique default gen_random_uuid(),
  suspended boolean not null default false
);

create table public.public_trip_publications (
  id uuid primary key default gen_random_uuid(),
  journey_id uuid not null unique references public.journeys(id) on delete cascade,
  owner_id uuid not null references auth.users(id) on delete cascade,
  generation integer not null default 1,
  next_revision integer not null default 1,
  active_revision integer,
  hidden boolean not null default false
);
create index public_trip_owner_idx on public.public_trip_publications(owner_id);

create table public.public_trip_revisions (
  publication_id uuid not null references public.public_trip_publications(id) on delete cascade,
  revision integer not null,
  generation integer not null,
  status text not null default 'prepared'
    check (status in ('prepared', 'submitted', 'approved', 'rejected', 'revoked', 'superseded')),
  source_hash text not null,
  content_hash text not null,
  sanitizer_version integer not null default 1,
  title text not null check (length(title) between 1 and 80),
  -- Calendar date of the trip start (Africa/Nairobi); never a time.
  trip_date date not null,
  -- Owner-only: requested moments/photos dropped for being in hidden areas.
  excluded jsonb not null default '{}'::jsonb,
  transport_mode text not null check (transport_mode in ('drive', 'walk')),
  route jsonb not null,
  distance_m numeric not null check (distance_m >= 1000),
  counties jsonb not null,
  start_trim_m integer not null check (start_trim_m between 500 and 50000),
  end_trim_m integer not null check (end_trim_m between 500 and 50000),
  prepared_at timestamptz not null default now(),
  expires_at timestamptz not null default (now() + interval '24 hours'),
  submitted_at timestamptz,
  reviewed_at timestamptz,
  review_reason text check (length(review_reason) <= 500),
  primary key (publication_id, revision)
);

create table public.public_trip_consents (
  publication_id uuid not null,
  revision integer not null,
  terms_version text not null,
  content_hash text not null,
  accepted_at timestamptz not null default now(),
  primary key (publication_id, revision),
  foreign key (publication_id, revision)
    references public.public_trip_revisions(publication_id, revision) on delete cascade
);

-- Moments chosen for a revision. Positions and values are derived on the
-- server from the owner's own points; no source point IDs are stored.
create table public.public_trip_revision_moments (
  publication_id uuid not null,
  revision integer not null,
  ordinal integer not null,
  kind text not null check (kind in
    ('county_crossing', 'elevation_peak', 'top_speed', 'long_stop', 'recording_break')),
  latitude numeric(8, 5) not null,
  longitude numeric(8, 5) not null,
  value jsonb not null default '{}'::jsonb,
  primary key (publication_id, revision, ordinal),
  foreign key (publication_id, revision)
    references public.public_trip_revisions(publication_id, revision) on delete cascade
);

-- Photos chosen for a revision. Viewers only ever get sanitized copies
-- (status 'ready'), stored in the private public-trip-media bucket by the
-- sanitization worker. Deleting the source photo deletes this row, which
-- removes it from the public trip immediately.
create table public.public_trip_revision_photos (
  id uuid primary key default gen_random_uuid(),
  publication_id uuid not null,
  revision integer not null,
  ordinal integer not null,
  source_media_id uuid not null references public.journey_media(id) on delete cascade,
  latitude numeric(8, 5) not null,
  longitude numeric(8, 5) not null,
  status text not null default 'pending' check (status in ('pending', 'ready', 'failed')),
  sanitized_path text unique check (length(sanitized_path) between 1 and 300),
  width integer check (width between 1 and 4096),
  height integer check (height between 1 and 4096),
  failure_reason text check (length(failure_reason) <= 200),
  updated_at timestamptz not null default now(),
  unique (publication_id, revision, ordinal),
  unique (publication_id, revision, source_media_id),
  foreign key (publication_id, revision)
    references public.public_trip_revisions(publication_id, revision) on delete cascade
);
create index public_trip_photo_source_idx on public.public_trip_revision_photos(source_media_id);

-- Owner share defaults. Changing them never alters existing revisions.
create table public.public_trip_share_preferences (
  user_id uuid primary key references auth.users(id) on delete cascade,
  county_crossing boolean not null default true,
  elevation_peak boolean not null default true,
  top_speed boolean not null default false,
  long_stop boolean not null default false,
  recording_break boolean not null default false,
  photos boolean not null default false,
  trim_m integer not null default 500 check (trim_m in (500, 1000, 2000)),
  updated_at timestamptz not null default now()
);

create table public.public_trip_author_blocks (
  viewer_id uuid not null references auth.users(id) on delete cascade,
  author_id uuid not null references public.public_trip_authors(author_id) on delete cascade,
  primary key (viewer_id, author_id)
);

create table public.public_trip_reports (
  id uuid primary key default gen_random_uuid(),
  publication_id uuid references public.public_trip_publications(id) on delete set null,
  revision integer not null,
  reporter_id uuid references auth.users(id) on delete set null,
  author_id uuid,
  reason text not null check (reason in ('privacy', 'restricted_access', 'misleading', 'abuse', 'other')),
  details text check (length(details) <= 500),
  state text not null default 'open' check (state in ('open', 'resolved')),
  created_at timestamptz not null default now(),
  resolved_at timestamptz,
  unique (publication_id, reporter_id, revision)
);

create table public.public_trip_moderation_events (
  id bigint generated always as identity primary key,
  actor_id uuid references auth.users(id) on delete set null,
  publication_id uuid,
  revision integer,
  action text not null,
  created_at timestamptz not null default now()
);

create table public_trip_private.requests (
  user_id uuid not null references auth.users(id) on delete cascade,
  request_id uuid not null,
  operation text not null,
  input_hash text not null,
  publication_id uuid references public.public_trip_publications(id) on delete cascade,
  revision integer,
  created_at timestamptz not null default now(),
  primary key (user_id, request_id)
);
create table public_trip_private.rate_limits (
  user_id uuid not null references auth.users(id) on delete cascade,
  operation text not null,
  window_start timestamptz not null,
  calls integer not null,
  primary key (user_id, operation, window_start)
);

-- No direct client policies or grants, even for approved rows. Definer RPCs
-- explicitly check flags, roles, cohorts, blocks and exact publication state.
do $$
declare t text;
begin
  foreach t in array array['public_trip_authors', 'public_trip_publications',
    'public_trip_revisions', 'public_trip_consents', 'public_trip_author_blocks',
    'public_trip_reports', 'public_trip_moderation_events', 'public_trip_revision_moments',
    'public_trip_revision_photos', 'public_trip_share_preferences'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('revoke all on table public.%I from public, anon, authenticated', t);
  end loop;
end $$;
revoke all on all tables in schema public_trip_private from public, anon, authenticated;

-- Sanitized public photos: private bucket with no client policies. Only the
-- worker (service role) writes, and viewers get bytes through an
-- access-checked delivery path, never a public URL.
do $$
begin
  if to_regclass('storage.buckets') is not null then
    insert into storage.buckets (id, name, public)
    values ('public-trip-media', 'public-trip-media', false)
    on conflict (id) do update set public = false;
  end if;
end $$;
