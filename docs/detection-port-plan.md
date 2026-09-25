# Detection port plan (tracker row 5)

How v1's county tracking moves into v2: geofencing, the visit state
machine, the offline visit queue and the arrival nudge. Source is v1
`lib/src/features/detection` and `lib/src/features/offline` (about 2,100
lines) plus `counties/county_boundary_resolver.dart` and
`counties/county_boundaries.dart`.

Status: in progress (slices 1-7 on `main` via #3; needs a device test). Update this file and `port-tracker.md` as
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
| `app/` | lifecycle hook that drives `DetectionController` on start / resume / timer; wiring around the tab shell (`app/app_shell.dart`) |

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
2. **Local store + repository.** Done: drift database (`detection_queue`,
   schema 2, unchanged from v1 so upgrading phones keep unsynced visits),
   `DetectionRepository` (owner binding, handleEvent, reconcile from a fix,
   still-candidate resolution, speed sanity, sign-out clear) split with a
   `detection_repository_reads.dart` part, `CountyDistance` in
   `core/counties/`, and `@riverpod` providers (database, repository,
   `visitTimings` overridden from the flavor in `buildAppRoot`). Tests with
   an in-memory drift database, including the v1 schema-1 upgrade.
3. **Sync queue.** Done: `VisitSyncQueue` (oldest first, owner-only,
   15 s → 15 min backoff that stops the drain, a day's wait for permanent
   rejections, user-change guard, shared concurrent drains) with an
   injectable upload and `VisitSyncQueue.supabase` for `sync_county_visit`.
   `VisitSync` notifier drains and reloads Explore's board; its count lets
   other screens react. v1's confirmed-visits cache (`AppOffline`) is left
   for the offline slice. Map Home still loads through a plain loader, so
   it reloads on its next load until it moves to Riverpod.
4. **Native geofencing.** Code done, device test pending: `native_geofence`
   ^1.3.1; Android boot / wake-lock permissions, the plugin's receivers and
   foreground service; iOS plugin registrant for the background engine (v1
   needed no background mode: region monitoring relaunches the app).
   `GeofenceService` (rolling window: county + neighbours, max 9 regions)
   and `geofenceCallbackDispatcher` (background isolate, local writes only,
   polygon lookup when the event carries a fix). Timings are now
   `VisitTimings.current` (dev in debug builds, production in release) in
   both isolates, instead of v1's flavor switch that the background isolate
   couldn't see. Known v1 gap kept: the callback doesn't re-register the
   window, so a second crossing while the app stays closed can be missed
   until the next foreground cycle.
5. **Foreground cycle.** Done: `DetectionController` (keep-alive notifier)
   runs fix → first-run bootstrap (county from the fix, else home county;
   synthetic ENTER only when that's where the phone is) → reconcile →
   capture candidates → dwell resolution → upload → re-register the window,
   and keeps a `DetectionSnapshot` for the arrival sheet. The fix reader is
   a provider so tests can fake it. `DetectionLifecycle` (presentation)
   wraps the signed-in shell in `app.dart` and runs a cycle on start, on
   resume and every 15 s in front. Map Home still reloads on its own
   schedule (plain loader); Explore reloads after a crossing or upload.
6. **Permissions.** Done. Onboarding already asks for foreground then
   "Always" (Android `locationAlways` after `locationWhenInUse`, iOS
   `requestAlwaysLocationAuthorization`) and only continues once granted;
   a cold start without it goes back to that page. Mid-session,
   `DetectionController` checks background location first on every cycle
   (`DetectionPermission`, a data wrapper over the permission service).
   When it's gone: geofences are removed once, no fix is read, the queue
   still uploads, and `DetectionSnapshot.backgroundLocationOff` is set.
   Home shows v1's "Automatic detection paused" label as a chip on the map
   that opens the OS settings; the next resume re-checks and re-registers.
   Not ported: v1's manual-mode board and "Log a visit" (no manual logging
   in v2 yet).
7. **Arrival nudge.** Done. `ArrivalNudgeRules` (domain) picks the
   newest active candidate that isn't the home county and hasn't shown
   the sheet (key `county@enteredAt`, v1's format). `ArrivalNudgeHistory`
   keeps the shown keys in shared preferences under v1's key (capped at
   200), so an upgraded phone doesn't re-show old crossings.
   `PendingArrivalNudge` is offered the candidates at the end of each
   cycle and loads the county first, so the sheet opens complete; a failed
   load is retried next cycle. `DetectionLifecycle` shows the sheet over
   whichever tab is open (v1 listened on Home, which stays mounted) and
   marks it shown. The sheet uses the v2 cards: v1's heading
   ("You've crossed into X", "N worth the detour."), the county as the
   shared `AppFeatureCard` ("YOU'RE HERE", photo, HQ, blurb, area and
   elevation; tap for County Detail), then "Places to visit": up to four
   shared `AppPlaceRow`s (saved first, save toggles through Explore's saved
   places) and "All N places in X →", the privacy note, Dismiss.
   `AppPlaceRow` and `AppSaveIcon` moved to `core/widgets` so Explore and
   the sheet share them. Left: call
   `ArrivalNudgeHistory.clear()` on sign-out, with the rest of that wiring.
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
