# Place CSV Import Backend

Migration: `supabase/migrations/20261109120000_place_csv_import.sql`.
Apply to the intended environment before deploying the dashboard import UI.
RPC: `import_places_csv_dashboard(p_rows jsonb)` returns record_number,
place_id, name and created/skipped_existing outcome for each record.

The RPC requires active owner/admin/editor membership. PUBLIC and anonymous
execution are revoked; authenticated execution still checks membership. It
validates payload size, count, allowed fields, text sizes, required identity,
county IDs, active types, coordinates, dates, source URLs and visit duration.
The existing create_place_dashboard_entry RPC builds PostGIS geometry and
retains the existing editorial creation architecture. All new records are
explicitly forced to draft with reviewed_at null. No publishing input is accepted.

Batch writes are atomic and imports serialize through a transaction advisory
lock. Existing source/external IDs or same-name/county matches are skipped,
including archived places; existing records are not changed. Separate manual
creation outside this importer is not serialized by its lock. It is still
important to use stable source/external IDs for repeatable imports.

No production migration was applied as part of implementation. No mobile code,
Edge Function or new secret is needed. Rollback the dashboard UI if necessary;
this additive RPC can remain installed without changing user records.

## Tests

`scripts/check-place-csv-sql.mjs` runs PGlite fixtures supplied with PGLITE_MODULE
or a local @electric-sql/pglite installation. The fixture SQL under supabase/tests
must never be run against a live database. It substitutes the underlying
single-place creator so the transaction/validation tests do not require PostGIS.
Real PostGIS geometry creation is reused unchanged, not exercised by that stub.
Checks include draft contents, repeated imports, name duplicates across sources,
atomic rollback on a later invalid row, unknown fields/types/counties, invalid
coordinates/URLs/dates, empty/oversized batches, archived/reviewed preservation
and viewer/moderator/unknown/anonymous denial.

No Flutter/Dart commands were run. Full CSV format and UI workflow are documented
in the dashboard repository's docs/place-csv-import.md.
