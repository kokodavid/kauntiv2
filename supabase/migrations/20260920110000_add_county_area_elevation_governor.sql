-- CountyDetail's v2 redesign (Figma node 235:7261) needs three more
-- per-county static facts the schema didn't carry yet: Area, Elevation
-- (its Area/Elevation/Population stat row) and Governor (its Source/
-- Established/Governor card). Same posture as
-- 20260903050000_add_county_facts_and_place_coords.sql's `capital`/
-- `population` columns: these are genuinely per-county facts this doc
-- set has no verified source for, so they're added as nullable columns,
-- left unseeded, and shown as "not on file yet" rather than guessed at
-- -- including Figma's own mock value for governor ("J.Name"), which is
-- an obvious placeholder, not a real name to seed with.

alter table public.counties
  add column if not exists area_km2 numeric,
  add column if not exists elevation_m numeric,
  add column if not exists governor_name text;
