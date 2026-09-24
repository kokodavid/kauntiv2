# Detection port plan (tracker row 5)

How v1's county tracking moves into v2: geofencing, the visit state
machine, the offline visit queue and the arrival nudge. Source is v1
`lib/src/features/detection` and `lib/src/features/offline` (about 2,100
lines) plus `counties/county_boundary_resolver.dart` and
`counties/county_boundaries.dart`.

Status: in progress (slice 1 on `codex/detection`). Update this file and `port-tracker.md` as
slices land.

## What v1 does

1. **OS geofencing** (`native_geofence`). One circle per county
   (`CountyPaths.centroids` + `geofenceRadiusMeters`). Only the current
   county and its neighbours are registered (`CountyPaths.neighborCodes`),
   re-registered on each crossing, because iOS caps an app at 20 regions.
2. **Background callback.** `geofenceCallbackDispatcher` runs in a fresh
   background isolate when the OS fires. It confirms the county with the
   polygon resolver (circles overlap; polygons with 500 m hysteresis
   decide), then records the crossing locally. No network in the callback.
3. **Visit state machine** (pure, `VisitStateMachine`). ENTER starts a
   candidate. EXIT resolves it: `explored` if dwell >= 2 h, `passed_through`
   if shorter, ignored if under the 2 min flap guard. Still-running
   candidates are checked opportunistically and resolve as `explored` once
   past the dwell threshold. A speed-sanity check (max 60 m/s) rejects
   impossible jumps. Dev builds use 2 min / 15 s timings.
4. **Local store** (drift, database `detection_queue`, schema 2): active
   candidates, the pending sync queue, the current county, and the owning
   user (so one account never syncs another's visits).
5. **Sync queue.** Drains `pending_sync_ops` to `sync_county_visit`
   (county, outcome, entered_at; never coordinates) with exponential
   backoff, a day's backoff for permanent rejections, and a guard against
   the signed-in user changing mid-drain.
6. **Foreground orchestration** (`GeofenceLifecycleObserver`). On start,
   resume and every 15 s while foregrounded: capture candidates for the
   arrival sheet, resolve elapsed dwells, drain the queue, reconcile the
   current county from a foreground fix, re-register the window.
7. **Arrival nudge.** "You crossed into X" sheet on Map Home (v1
   `county_arrival_sheet.dart`), shown once per crossing, with history in
   local storage.
8. **Offline extras.** A confirmed-visits cache (`AppOffline`), an offline
   status strip, and legacy visit recovery.

## What v2 already has

- Database: `county_visits`, `record_county_visit`, `sync_county_visit`
  (idempotent offline sync, migration `20260907000000`),
  `counties.neighbor_codes`, geofence radii.
- `CountyPaths.neighborCodes`, `geofenceRadiusMeters`, `centroids`.
- `assets/geo/kenya_counties.geojson` (the same polygons, for the map).
- Foreground location read (`AppCurrentLocation`) and permission service
  (`hasForegroundLocation`; iOS `requestAlwaysLocationAuthorization`).
- Android `ACCESS_BACKGROUND_LOCATION` and the iOS "Always" strings.

Missing: everything in "What v1 does", plus the Android geofence
receivers/services and `RECEIVE_BOOT_COMPLETED` / `WAKE_LOCK`, and the iOS
background location mode.

## v2 shape

| Layer | Files (proposed) |
|---|---|
| `core/counties/` | `county_boundaries.dart` (static polygons, long-file exemption), `county_boundary_resolver.dart` |
| `features/detection/domain/` | `visit_models.dart`, `visit_rules.dart` (the pure state machine, timings passed in) |
| `features/detection/data/` | `local/detection_database.dart` (+ `.g.dart`), `detection_repository.dart`, `visit_sync_queue.dart`, `geofence_service.dart`, `geofence_callback.dart`, `arrival_nudge_history.dart` |
| `features/detection/application/` | `@riverpod` providers: database, repository, sync queue, geofence service; `DetectionController` notifier that runs the foreground cycle; `pendingArrivalNudge` notifier |
| `features/detection/presentation/` | arrival sheet |
| `app/` | lifecycle hook that drives `DetectionController` on start / resume / timer; wiring into `AppTabShell` |

Rules this has to respect:

- `drift`, `native_geofence` and `supabase_flutter` stay in `data/`
  (`io-outside-data`).
- The background isolate has no `ProviderScope`: the callback builds plain
  data classes directly (as v1 does). Providers only wrap them for the UI.
- No `setState` state machine in `app/`: the foreground cycle lives in a
  notifier; the widget only forwards lifecycle events.
- Generated drift and Riverpod files are committed.
- Files stay under 300 lines; `county_boundaries.dart` is static data and
  needs a `LONG_FILE_EXEMPTIONS` entry (a guarded rules change, CODEOWNERS).

## Slices

Each slice is one PR-sized commit with tests and a tracker update.

1. **Pure rules.** Done: `visit_models`, `visit_rules` (dwell, flap
   guard, still-candidate check, speed sanity; timings passed in as
   `VisitTimings` instead of v1's static environment switch), boundary
   resolver + polygons in `core/counties/`. Tests ported from v1 plus
   outside-Kenya and hysteresis cases.
2. **Local store + repository.** Drift database and `DetectionRepository`
   (owner binding, handleEvent, reconcileCurrentLocation, still-candidate
   resolution, queued visits). Keep the database name `detection_queue`
   and schema 2 so a phone upgrading from a v1 build keeps its unsynced
   visits. Tests with an in-memory drift database.
3. **Sync queue.** `VisitSyncQueue` against `supabaseClientProvider`,
   backoff and rejection rules, user-change guard. After a successful
   drain, invalidate Explore's board (and reload Map Home) so a new badge
   shows without a restart. Tests with fakes.
4. **Native geofencing.** Add `native_geofence`; Android manifest
   receivers/services, boot receiver and permissions; iOS background
   location mode. `GeofenceService` (rolling window) and the background
   callback. Device test: register, cross a boundary with a mock route.
5. **Foreground cycle.** `DetectionController` (capture candidates →
   resolve dwells → drain → reconcile current county → re-register), run
   on start, resume and a 15 s foreground timer; stops when backgrounded.
   Seed the current county from the first fix after onboarding.
6. **Permissions.** Already in v2: onboarding asks for foreground then
   "Always" (Android `locationAlways` after `locationWhenInUse`, iOS
   `requestAlwaysLocationAuthorization`) and only continues once granted.
   Left: re-check on resume if the user later downgrades to "While using",
   and stop geofencing cleanly when that happens.
7. **Arrival nudge.** Port the arrival sheet onto Map Home with the shared
   type scale, once per crossing, history cleared on sign-out.
8. **Offline extras.** Offline status strip and legacy visit recovery, or
   fold into the broader offline work if that lands first.

Sign-out must clear candidates, the queue owner and nudge history (v1
`clearAllLocalState`), wired where v2's sign-out lands.

## Decisions (settled 2026-09-24)

1. **Polygons:** v1's generated Dart constant, in
   `core/counties/county_boundaries.dart`, with a long-file exemption.
2. **Timings:** v1's: 2 h dwell / 2 min flap guard; dev 2 min / 15 s.
3. **Background permission:** already asked in onboarding (see slice 6).
4. **Arrival sheet:** port v1's design, on the shared type scale.

## Privacy (doc 05)

Coordinates never leave the phone. The background callback and the
foreground cycle use a fix only to decide which county the phone is in;
only `county_id`, `outcome` and `entered_at` are synced. Nothing about
location is stored beyond the current county code and candidate start
times in the local database.

## Testing

- Unit: rules, resolver, repository (in-memory drift), sync queue (fakes).
- Widget: arrival sheet, permission page states.
- Device: Android emulator mock routes (GPX) for crossings and dwell with
  dev timings; a real drive across at least one county line on Android and
  iOS before marking row 5 Done. Check reboot re-registration and a crossing
  while the app is killed.
