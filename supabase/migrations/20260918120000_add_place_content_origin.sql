-- Places inserted by the dev seed migrations (20260902203000_seed_dev_places.sql,
-- 20260909210000_seed_dev_county_gap_places.sql) and places entered through the
-- dashboard's "Add place" form were otherwise indistinguishable at a glance.
-- The only existing signal was that every seeded row carries a non-null
-- external_id (its Wikidata/OpenStreetMap/GeoNames identifier), while every
-- dashboard row leaves external_id null (see the comment in
-- 20260914120000_add_place_creation_dashboard_rpc.sql). This turns that
-- implicit signal into an explicit, filterable column so the dashboard can
-- show and filter on it without the team needing to know the null-check.

alter table public.places
  add column if not exists content_origin text not null default 'dashboard'
    check (content_origin in ('dashboard', 'seed_migration'));

-- Backfill: adding the column above already defaulted every existing row to
-- 'dashboard'. Re-tag the ones that actually came from a seed migration.
update public.places
  set content_origin = 'seed_migration'
  where external_id is not null
    and content_origin <> 'seed_migration';

comment on column public.places.content_origin is
  'dashboard: created via create_place_dashboard_entry. seed_migration: inserted by a supabase/migrations seed script (dev_places / county_gap_places) and pending editorial review.';
