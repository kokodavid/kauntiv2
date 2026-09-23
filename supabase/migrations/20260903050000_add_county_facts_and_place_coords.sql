-- CountyDetail (board 15e) needs two things the schema didn't carry yet:
--
-- 1. Per-county static facts for the About card's quick-facts row
--    (capital / year established / population, doc 06). `capital` and
--    `population` are genuinely per-county facts this doc set has no
--    verified source for -- rather than guess at 47 county headquarters
--    and population figures and risk shipping wrong ones, they're added
--    as nullable columns, left unseeded, and shown as "not on file yet"
--    -- the same posture `counties.rarity_pct` already established.
--    `year_established` is different: every one of Kenya's 47 counties
--    became one on the same date (the 2010 constitution's devolution,
--    operational from March 2013), so it's not a per-row fact to source
--    -- seeded here for every row rather than left null.
--
-- 2. `places.lat`/`lng` -- PlaceDetail's Get Directions CTA needs real
--    coordinates to deep-link to Google Maps, and PostgREST can't call
--    ST_X/ST_Y inline in a select list. Generated columns over the
--    existing `location` point (same pattern as doc 07's
--    `counties.county_code` sketch) expose them as plain selectable
--    columns without duplicating the source of truth.

alter table public.counties
  add column if not exists capital text,
  add column if not exists year_established smallint,
  add column if not exists population bigint;

update public.counties set year_established = 2013;

alter table public.places
  add column if not exists lat double precision
    generated always as (extensions.ST_Y(location)) stored,
  add column if not exists lng double precision
    generated always as (extensions.ST_X(location)) stored;
