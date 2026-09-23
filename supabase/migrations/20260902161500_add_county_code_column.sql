-- A human-readable, zero-padded county code ("047" for Nairobi), separate
-- from counties.id (a bare integer that already equals this same code --
-- see the counties seed migration and CountyPath.code in
-- lib/src/counties/county_paths.dart).
--
-- Generated always as, not a separately-maintained column: id is already
-- guaranteed to be the official code, so county_code is purely a display
-- format of that same value and can never drift out of sync with it.
alter table public.counties
  add column if not exists county_code text
    generated always as (lpad(id::text, 3, '0')) stored;

alter table public.counties
  add constraint counties_county_code_unique unique (county_code);
