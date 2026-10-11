-- What kinds of places a traveller likes, asked once during setup
-- (step 2 "What do you like to see?") and editable later from Settings.
-- `interests` holds the chosen category keys (nature, water, coast, ...);
-- `preferences_completed` records that the question was answered or
-- skipped, so setup never asks twice. Both live on `profiles`, which
-- already has owner-only select/insert/update RLS, so a plain client
-- upsert is enough (security plan: RPCs only for more than simple
-- user-owned preference rows).
alter table public.profiles
  add column if not exists interests text[] not null default '{}',
  add column if not exists preferences_completed boolean not null default false;

-- Only known category keys, so a stale or hostile client cannot store
-- arbitrary text. Keep in step with PlaceInterest in the app.
alter table public.profiles
  drop constraint if exists profiles_interests_known;
alter table public.profiles
  add constraint profiles_interests_known check (
    interests <@ array[
      'nature', 'water', 'coast', 'culture',
      'wild', 'food', 'views', 'relax'
    ]::text[]
  );
