-- Map Home's redesigned county peek sheet (Figma node 235:6111 "Homepage",
-- Unclaimed/Claimed/Passed/Home states) adds an Area/Elevation/Duration
-- stats row to the sheet itself, matching CountyDetail's own stat-row
-- recipe. Area and Elevation already exist on `counties`
-- (20260920110000_add_county_area_elevation_governor.sql) -- Duration is
-- the one new fact, and it's genuinely per-county (a rough "how long to
-- see this county" figure), not the place-level
-- `places.visit_duration_minutes` from 20260920090000_add_place_trip_stats
-- .sql, which is trip/trail-specific to one park or reserve.
--
-- Same posture as every other unsourced county fact so far: nullable,
-- left unseeded, and the client shows "Not on file yet" rather than a
-- guessed value -- including anything Figma's own mockup showed, which
-- was illustrative, not a sourced fact.

alter table public.counties
  add column if not exists duration_minutes integer;
