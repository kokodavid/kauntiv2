# Country Club Place Type

## Scope

`country_club` is an active place type with labels Country club / Country clubs,
icon `golf_course`, display order 220, and plural alias `country clubs`.
The mobile application uses the existing `other` family color. No new interest
mapping, check-in radius, navigation, or authentication behavior is introduced.

The dashboard reads place types and aliases from the database, including the CSV
importer, so it does not need a frontend deployment for this addition. Reload an
already-open place form to refresh its type references. Existing mobile builds
already preserve unknown category labels; the explicit filter and golf icon
require shipping the changed mobile source.

## Database

Migration: `20261109130000_country_club_place_type.sql`.
It only adds a type and alias, is idempotent, and does not import or publish places.
Applied to production `wlxonnbqwtovofjdlgjo` and recorded in its migration ledger.
Development was not changed.

The production ledger included migrations absent from the isolated verification
snapshot, so a broad `db push` was deliberately not used. Only this migration's SQL was executed via
the linked database query command, followed by recording this version as applied.
No existing migration history was reverted or repaired away.

## Prepared Dataset

The original 39-row country-clubs CSV is unchanged. The prepared copy contains
32 sourced coordinates and retains the seven supplied property pins. All 39
records pass the production dashboard's CSV parser. A separate audit CSV records
coordinate sources, precision limitations, and five county-map discrepancies.
Migaa Golf Clubhouse is renamed Migaa Golf Club because the sourced point locates
the course property, not the clubhouse. Source/external IDs remain unchanged.

These are draft-import pins, not surveyed visitor entrances or check-in evidence.
Review access conditions, entrances, county assignments, and attribution before
publishing. In particular, check Fairmont, Nyahururu, Thika Sports Club, and the
coastal-boundary cases at Vipingo Beach Club and Mombasa Golf Club. Original county
IDs are retained rather than silently replacing disputed administrative labels.

## Verification

- Production query confirms active type, labels, icon, alias, order and migration.
- Structured CSV round-trip: 39 rows, 32 filled coordinate pairs, zero parser errors.
- Coordinates compared with the application's county polygons using Turf.
- Domain migration-parity regression extended; synchronous icon/color test added.
- No asynchronous state, session, loading or navigation changes. Category/style
  lookup is synchronous, so no new intermediate fallback state is introduced.
- Flutter/Dart commands were not run, per standing instructions. Device/emulator
  transitions and visual flash checks remain unverified; no device claim is made.
