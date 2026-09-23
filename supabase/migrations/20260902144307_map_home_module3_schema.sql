-- Map Home Module 3 schema: the tables docs/07-data-models.md's "For you"
-- and "Side Quests" queries run against, plus the shared county/place
-- reference tables both queries join through. Table shapes and columns
-- follow that doc's SQL sketches as closely as possible -- this migration
-- does not invent new structure beyond what it specifies.
--
-- Not covered here (deliberately -- see docs/v1-scope-and-decisions.md's
-- Module 3 scoping note): seasons/leaderboard tables. Season-live stays
-- stubbed to false in the Map Home variant resolver until the
-- Leaderboards & Seasons feature (tracker PR #10) builds that schema.
--
-- Not covered here either: seeding real county/place data. These tables
-- are created empty; seeding `counties` from the geoBoundaries ADM1
-- dataset and `places` from the doc 03 content sources is a separate,
-- data-sourcing task, not a schema task.

-- ---------------------------------------------------------------------
-- Shared reference tables (doc 07 "Shared reference tables")
-- ---------------------------------------------------------------------

create table if not exists public.counties (
  id smallint primary key check (id between 1 and 47),
  name text not null,
  slug text not null unique,
  geometry extensions.geometry(MultiPolygon, 4326) not null,
  centroid extensions.geometry(Point, 4326) not null,
  rarity_pct numeric(5, 2),
  is_coastal boolean not null default false
);

alter table public.counties enable row level security;

create policy "Anyone signed in can read counties"
  on public.counties
  for select
  to authenticated
  using (true);

create table if not exists public.places (
  id uuid primary key default gen_random_uuid(),
  county_id smallint not null references public.counties (id),
  name text not null,
  type text not null,
  -- Split per doc 07's flagged note: a short one-line summary for list
  -- rows (Discover, CountyDetail, ArrivalPrompt) and a longer paragraph
  -- for PlaceDetail -- these were previously assumed to be one field.
  summary text,
  description text,
  location extensions.geometry(Point, 4326) not null,
  source text not null,
  licence text
);

alter table public.places enable row level security;

create policy "Anyone signed in can read places"
  on public.places
  for select
  to authenticated
  using (true);

-- ---------------------------------------------------------------------
-- County visits: doc 01's visit state machine (CANDIDATE is transient
-- and not stored -- a row is only written once a visit resolves to
-- explored or passed_through, or is queued offline as pending).
-- ---------------------------------------------------------------------

create table if not exists public.county_visits (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  county_id smallint not null references public.counties (id),
  state text not null check (state in ('explored', 'passed_through', 'pending')),
  entered_at timestamptz not null default now(),
  confirmed_at timestamptz,
  -- How many times this county has been passed through without
  -- converting to explored -- doc 07's personal-nudge query reads this
  -- directly (`pass_count >= 3`) rather than counting rows at query time.
  pass_count integer not null default 1
);

create index if not exists county_visits_user_id_idx on public.county_visits (user_id);
create index if not exists county_visits_user_county_idx
  on public.county_visits (user_id, county_id);

alter table public.county_visits enable row level security;

create policy "Users can read their own visits"
  on public.county_visits
  for select
  to authenticated
  using (auth.uid() = user_id);

create policy "Users can insert their own visits"
  on public.county_visits
  for insert
  to authenticated
  with check (auth.uid() = user_id);

create policy "Users can update their own visits"
  on public.county_visits
  for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ---------------------------------------------------------------------
-- Depth-rank progress (doc 02's ladder) -- doc 07's "held but not yet
-- Local Expert" For-you candidate reads this table's `rank` column.
-- ---------------------------------------------------------------------

create table if not exists public.county_depth_progress (
  user_id uuid not null references auth.users (id) on delete cascade,
  county_id smallint not null references public.counties (id),
  rank text not null default 'visitor',
  updated_at timestamptz not null default now(),
  primary key (user_id, county_id)
);

alter table public.county_depth_progress enable row level security;

create policy "Users can read their own depth progress"
  on public.county_depth_progress
  for select
  to authenticated
  using (auth.uid() = user_id);

create policy "Users can upsert their own depth progress"
  on public.county_depth_progress
  for insert
  to authenticated
  with check (auth.uid() = user_id);

create policy "Users can update their own depth progress"
  on public.county_depth_progress
  for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ---------------------------------------------------------------------
-- Wishlist (doc 03) -- doc 07's "saved but not ticked" For-you candidate.
-- ---------------------------------------------------------------------

create table if not exists public.wishlist_items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  county_id smallint not null references public.counties (id),
  place_id uuid references public.places (id),
  saved_at timestamptz not null default now(),
  ticked_at timestamptz
);

create index if not exists wishlist_items_user_id_idx on public.wishlist_items (user_id);

alter table public.wishlist_items enable row level security;

create policy "Users can read their own wishlist"
  on public.wishlist_items
  for select
  to authenticated
  using (auth.uid() = user_id);

create policy "Users can insert their own wishlist items"
  on public.wishlist_items
  for insert
  to authenticated
  with check (auth.uid() = user_id);

create policy "Users can update their own wishlist items"
  on public.wishlist_items
  for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ---------------------------------------------------------------------
-- Editorial quests and collections (doc 02/03) -- content authored by
-- the team, read-only from the client. Progress is per-user.
-- ---------------------------------------------------------------------

create table if not exists public.editorial_quests (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  required_count integer not null,
  starts_at timestamptz not null,
  ends_at timestamptz not null
);

alter table public.editorial_quests enable row level security;

create policy "Anyone signed in can read editorial quests"
  on public.editorial_quests
  for select
  to authenticated
  using (true);

create table if not exists public.editorial_quest_progress (
  quest_id uuid not null references public.editorial_quests (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  completed_count integer not null default 0,
  updated_at timestamptz not null default now(),
  primary key (quest_id, user_id)
);

alter table public.editorial_quest_progress enable row level security;

create policy "Users can read their own quest progress"
  on public.editorial_quest_progress
  for select
  to authenticated
  using (auth.uid() = user_id);

create policy "Users can upsert their own quest progress"
  on public.editorial_quest_progress
  for insert
  to authenticated
  with check (auth.uid() = user_id);

create policy "Users can update their own quest progress"
  on public.editorial_quest_progress
  for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create table if not exists public.collections (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  required_count integer not null
);

alter table public.collections enable row level security;

create policy "Anyone signed in can read collections"
  on public.collections
  for select
  to authenticated
  using (true);

create table if not exists public.collection_progress (
  collection_id uuid not null references public.collections (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  completed_count integer not null default 0,
  updated_at timestamptz not null default now(),
  primary key (collection_id, user_id)
);

alter table public.collection_progress enable row level security;

create policy "Users can read their own collection progress"
  on public.collection_progress
  for select
  to authenticated
  using (auth.uid() = user_id);

create policy "Users can upsert their own collection progress"
  on public.collection_progress
  for insert
  to authenticated
  with check (auth.uid() = user_id);

create policy "Users can update their own collection progress"
  on public.collection_progress
  for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
