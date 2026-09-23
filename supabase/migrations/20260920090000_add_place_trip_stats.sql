-- New, optional place-level stats backing the restyled Map Home hero
-- card (board 1b's "PRIMARY TARGET / Your next best move" card,
-- lib/src/features/map_home/presentation/map_home_hero_card.dart) --
-- Area / Elevation / Duration, matching Figma node 235:5214/5448's
-- stats row.
--
-- Nullable and place-level, not county-level: these read like trip/
-- trail stats for a specific park or reserve, not a whole county's own
-- geography, and most places won't have them at first (only parks/
-- reserves/trails plausibly do) -- the client hides the stats row
-- entirely when all three are null rather than showing a placeholder.
-- See docs/07-data-models.md's "places" table for the full note.

alter table public.places
  add column if not exists area_km2 numeric(10, 2),
  add column if not exists elevation_m integer,
  add column if not exists visit_duration_minutes integer;
