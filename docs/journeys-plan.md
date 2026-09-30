# Journeys: implementation plan

Status: steps 1-2 merged (#5-#7; locked-screen device check still open).
Step 3 (entitlement and sync) on `codex/journeys-sync`; step 4 (UI) on
`codex/journeys-ui`.

## Product rules

- A confirmed county crossing does not earn a badge until the existing dwell
  threshold is met. Journey recording has no effect on that decision.
- Recording is Pro-only and starts only after an explicit user action. A
  subscription expiring during a recording does not interrupt that session.
- Past Journeys remain viewable, replayable, exportable and deletable after Pro
  expires. Starting the next Journey requires an active entitlement.
- Completed Journeys sync privately to the user's account for access on other
  devices. An active session is stored locally first so recording survives
  network loss.
- Subcounty tracking is a later feature. Do not infer coverage from ordinary
  county crossing events.

## Architecture

`features/journeys` owns recording state, route samples, history and replay.
The existing `features/detection` owns badges and stays independent. Mapbox
renders a route; it does not own the recording or storage lifecycle.
Place Detail keeps its external directions launcher; `app/` coordinates the
optional Journey start before opening it. A destination is intent, not a
planned route or evidence that the user arrived.

| Layer | Responsibility |
|---|---|
| `domain` | Session states, point validation, route segments and summaries |
| `data` | Native location adapter, durable local session, upload and private Supabase reads |
| `application` | Generated Riverpod providers for entitlement, recorder and history |
| `presentation` | Journeys tab, live controls, history and route replay |

The initial schema has private read/delete policies but no authenticated
insert/update policy. The upload path must check a server-backed Pro
entitlement and validate the recording before granting writes. It must allow a
session that began while Pro was active to finish after expiry. Billing and
entitlements are not implemented in this foundation slice.

## Build sequence

1. **Foundation:** private `journeys` and `journey_points` tables; recording
   states and validation; tests. Keep the tab hidden.
2. **Recorder:** iOS background location and Android `location` foreground
   service, started from a visible, user-initiated action. Persist points and
   state locally, including pause/resume and gaps when fixes are missing. The
   `location` stream does not survive process termination; on next launch the
   saved session must pause and require an explicit Resume. Verify this on
   devices before enabling the tab.
3. **Entitlement and sync:** a server-verified Pro entitlement, an upload path
   that validates owner and session timing, offline retries, and private
   history reads/deletion. Never use client-only Pro gating for cloud writes.
   Built (migration `20260925160000`, `supabase/tests/journey_upload.sql`):
   - `pro_entitlement_periods`: users read their own, only admins write.
     Until billing (#12) exists, admins grant periods; billing will add
     periods through its own server path (`source`: app_store, play_store,
     mpesa).
   - `my_pro_status()` gates Start in the app, checked live every time:
     Start needs a connection (decided 2026-09-25), so no route is ever
     recorded that the server would refuse to save.
   - `upload_journey(...)` is the only write path (security definer). It
     checks the owner, that Pro was active when the Journey *started*
     (so a lapse mid-Journey still uploads), timing (ends after it starts,
     not in the future beyond 5 min skew, at most 7 days long, started in
     the last 90 days), point order and bounds (max 50,000), computes the
     distance within segments, and is idempotent on the client-made UUID.
   - App: `JourneyRecorder` (live Pro-checked start, pause/resume/finish,
     recover), `JourneyUploadQueue` (oldest first, backoff; permanent
     rejections wait a day; local copy deleted after upload),
     `JourneyHistoryList` (waiting-on-phone first, then cloud; delete).
   - Retries: `JourneySyncLifecycle` (around the tab shell) recovers a
     cut-off Journey and drains uploads on launch and every resume, and
     retries every minute while the app is in front (the queue's backoff
     decides what's due).
   - Reads page through Supabase's 1,000-row cap (history and points).
   - Account isolation: uploads name their owner and the RPC refuses a
     mismatch with the signed-in account; the queue stops when the account
     changes (before and after each upload, without blaming the Journey);
     the recorder pauses and lets go of a Journey when the account changes;
     history and the Pro status rebuild per account.
   Provisional limits to confirm: 7-day max Journey, 90-day upload window, 50,000 points per upload, and the default
   title "Journey on 25 Sep 2026".
4. **Journey UI:** fifth bottom-nav destination, live status and Stop controls,
   history, and route rendering on Mapbox. The tab must show archived Journeys
   after expiry and gate only Start Journey.
   Built on `codex/journeys-ui` behind `--dart-define=JOURNEYS_ENABLED=true`
   (`AppFeatureFlags.journeys`; off by default, so release builds hide it):
   - Journeys tab (`/journeys`, fifth shell branch): Start card (live Pro
     check; "Journeys are part of Pro", "Connect to the internet to start
     a Journey", location messages with a Settings link), live card (route
     on the map following the newest point, elapsed time, distance,
     Pause / Resume / Stop with confirmation), history (waiting-to-upload
     and cloud Journeys, offline notice, pull to refresh and upload).
   - A start the phone can't record (location off, no "Always") drops the
     empty Journey instead of leaving it paused.
   - A "Recording · 0:12:04" pill over the tab bar on other tabs.
   - Journey detail (`/journey/:id`): route per segment on Mapbox, distance,
     duration, start time, a ~10 s replay and delete. Works after Pro
     expires.
   - Not built yet: export (GPX), renaming, moving time (elapsed includes
     pauses).
   - Testing: grant Pro with
     `insert into public.pro_entitlement_periods (user_id, starts_at)
     values ('<user uuid>', now());` then run with the dart-define.
5. **Release readiness:** update the in-app explanation, privacy policy,
   purpose strings, App Store privacy answers and Play Data safety/declaration.
   Test locked-screen recording on real iOS and Android devices, offline and
   low-power cases, process restarts, permission revocation, account changes,
   deletion and missing-point gaps. Prepare reviewer access and a demo video.

## Reliability review (2026-09-26)

The UI branch now guards account changes during asynchronous Start/recovery,
coordinates deletion with in-flight uploads, excludes process-down time from
recorded duration, and splits a route after a long gap in accepted fixes.
Stop/Discard remain retryable if native background location does not confirm
shutdown, and a stream failure updates the visible recording state. Replay
crossings use the detector's inside-boundary margin and wait
for confirming route points. The recording map no longer opens at a default
Kenya-wide camera while waiting for its first fix.

Still open before enabling the tab: real-device locked-screen/stop tests,
comparison of the bundled county geometry with the Mapbox boundary and the
location-less geofence callback, multi-hour route performance, privacy/store
disclosures and retention, plus export. A limited free Journey allowance is
under design; Pro-only remains the implemented rule until a server-enforced
quota migration and matching app changes land.

## Place route handoff (2026-09-26)

Place Detail, Home map place pins and the Home promoted-place card now offer
Record as a Journey and Directions only when the feature flag is enabled.
County-only Route buttons continue to open directions. The user explicitly
chooses recording, which must
pass the live entitlement and background-location checks before directions
open in the external maps app. If directions cannot open, the new Journey is
discarded after confirmed teardown; if teardown fails, the app tells the user
that it is still recording. An existing Journey is not silently retargeted.

Local schema 4 keeps an optional account-scoped destination snapshot. The
`20260926150000_add_journey_destinations.sql` migration adds private cloud
fields and an owner-checked wrapper around the existing validated upload RPC.
Deploy this migration before enabling the new client. The recorded route and
manual Stop remain independent of the destination. Planning multiple stops,
route comparison and arrival handling are later work.

## Loading (2026-09-26)

- Past Journeys show shimmering placeholder cards shaped like the real
  cards (`JourneyCardsLoading`, shared `core/widgets/app_shimmer.dart`)
  while the history loads, instead of a spinner.

## Privacy boundary

Automatic detection continues to sync county-level visit data only. Precise
points are collected only during an explicit Journey, remain private to the
account, and can be deleted by the user. Local buffering is necessary for
offline recording; cloud sync is necessary for cross-device history. Define
retention and backup-deletion periods before release. No route is public or
shared by default. Current v1 privacy copy saying routes are never stored must
be updated before Journeys is enabled.

## Redesign: exploration-centered Journeys, travel modes, trip planning (2026-09-30)

Concept direction: Journeys currently reads as a utility (Start card + flat
history list). The redesign should make it read as a travelogue: what the
user has explored, not just what was recorded. Reuse the achievement visual
language already established on Home's map stat card (legend colors, "% of
Kenya" framing) rather than inventing a new one.

### 1. Layout (presentation only, no schema change)

- Replace the plain "Journeys" header with a hero summary: total distance
  travelled, counties touched via a Journey, and a highlight stat (e.g.
  "furthest from home" or "counties explored this month"), styled in the
  same family as `MapHomeStatCard`'s legend.
- Group `Past Journeys` by month instead of one flat list; larger, more
  editorial route-preview art per card.
- Replace the plain "No Journeys yet" text with an exploration-toned empty
  state (illustration/copy inviting the first trip), not just a sentence.
- Touches: `journeys_screen.dart`, `journey_history_section.dart`,
  `journey_card.dart`. No new fields on `JourneySummary`.

### 2. Travel mode (foot / drive / fly)

- New `JourneyTravelMode` enum (`foot`, `drive`, `fly`), chosen by the user
  on the Start card before recording begins (decided 2026-09-30 — not
  auto-detected from speed; unreliable without real motion classification,
  and adds interruption-free Start).
- Data model: add `travelMode` to `JourneyRecording`/`JourneySummary`, a
  column on the local Drift schema (new migration) and the cloud `journeys`
  table (new Supabase migration alongside `upload_journey`, mirroring how
  `journey_destinations` was added), and thread it through
  `JourneyRecorder.start()`, `JourneyUploadQueue`, and the read paths.
- UI: a compact mode selector added to `JourneyStartCard` (segmented
  control), a mode icon/chip on `JourneyCard`, and filter chips ("All /
  Walking / Driving / Flying") atop the redesigned history list.

### 3. Trip planning

- Lives as a second tab inside the Journeys screen (decided 2026-09-30 —
  "Past" and "Plan", not a new bottom-nav slot), keeping the nav flat.
- New domain concept: a planned trip (destination(s), optional date,
  status) distinct from a recorded `Journey`. A planned trip can hand off
  into an actual recording the same way Place Detail's existing "Record as
  a Journey" destination handoff works today, rather than duplicating that
  logic.
- Out of scope for the first slice: multi-stop routes, route comparison,
  reminders/notifications for an upcoming planned trip.

### Build sequence

1. Redesign the layout (low risk, immediately visible, no schema change).
2. Add travel mode (additive to the existing recording/upload path).
3. Add trip planning as the "Plan" tab (newest surface area, depends on
   nothing above but is more work, so sequenced last).

### Naming: Journeys → Trips, walk = Trek (2026-09-30)

User-facing copy only (decided 2026-09-30): every string the user sees now
says "Trip"/"Trips" instead of "Journey"/"Journeys" — the bottom-nav label,
screen and card titles, dialogs, Start/Stop copy, the Android recording
notification, badge and profile text. Code identifiers, file names, route
paths (`/journeys`, `/journey/:id`), the feature flag
(`AppFeatureFlags.journeys`), and the local/cloud schema (`journeys`,
`journey_points`, `upload_journey`) are unchanged for now — renaming those
is a separate, larger decision (see the two rejected options below) and
isn't needed for the user-facing rename to land.

Once travel mode (phase 2 above) exists, a foot-mode entry is labelled
"Trek" instead of "Trip" wherever the type is shown (card chip, default
title, filter chip); drive and fly stay "Trip". This can't be implemented
yet since the `JourneyTravelMode` field doesn't exist; tracked here so
phase 2's copy work picks it up rather than defaulting every mode to "Trip".

Options not taken, for reference if this comes up again: renaming the code
symbols/files (`JourneySummary`, `journeys/` folder, etc.) across ~30
files, and renaming the live Supabase tables/RPC — both larger jobs with
real risk (no compiler in this workflow to verify a symbol rename; the
database already has real migrations and entitlement logic built on it).



## Trip cards, replay, media, and trip stats — scoping (2026-09-30)

A bundled request: redesign the past-Trip card (gallery/folder feel instead
of the current flat photo card), move Delete and a new Rename off the main
card, show places visited along the route using the same `AppPlaceRow`
design Explore already uses, add average speed / top speed / highest
elevation, let a user attach photos/videos during recording and see them in
replay, and give the whole Replay screen a livelier, animated redesign to
host all of this. Investigated what each piece actually needs before
starting, since they're very different sizes:

### Already have the building blocks (presentation + moderate data work)

- **Card redesign.** Presentation only. `JourneyCard` can become a
  folder/gallery-style card without touching data.
- **Rename.** Does not exist yet (`journeys-plan.md`'s step 4 already
  flagged "Not built yet: export (GPX), renaming"). Needs a small new
  write path: a title-update method on the local repository and the cloud
  repository (its own owner-checked RPC or a direct authenticated update,
  mirroring how `upload_journey`/the destination wrapper are owner-checked),
  plus a text-edit UI. Small, contained.
- **Delete moved off the card.** Presentation only — the delete handler
  already exists (`JourneyHistoryList.delete`); this just relocates the
  trigger (e.g. into a card overflow menu or the replay/detail screen).
- **Places visited, Explore-style.** The detection already exists:
  `journeyMomentsProvider` finds nearby/saved places within 10 km of a
  route today, rendered as icon rows (`JourneyMomentRow`). The design
  system's shared `AppPlaceRow` (Explore's county-card rows, 54px
  thumbnail + category chip + save toggle) is exactly the "same design as
  Explore" ask. Gap: `JourneyPlaceMark` (what `journeyPlaces` fetches)
  only carries id/county/name/lat/lng/saved — no thumbnail, category or
  description. Needs the query behind `journeyPlacesProvider` widened to
  select those columns (they already exist on the places Explore reads),
  then swap `JourneyMomentRow`'s place branch for `AppPlaceRow`.
- **Average speed, top speed, highest elevation.** The `location` plugin
  already reports `altitude` and `speed` on every fix; `JourneyFix`/
  `JourneyPoint` currently discard both. Needs: add `altitudeMeters` and
  `speedMetersPerSecond` to the domain point, a new local Drift migration
  and a new cloud `journey_points` column (mirroring the existing
  migration pattern), and compute avg/top speed and max elevation from a
  route's points for the summary/replay header. Same shape and size as
  the already-planned travel-mode migration — real but bounded work.

### Genuinely new infrastructure

- **Photos/videos captured during a Trip, saved to the route, shown in
  replay.** Nothing for this exists today: no `image_picker`/camera/
  video package in `pubspec.yaml`, no Supabase Storage bucket, no upload
  queue for binary media (the existing `JourneyUploadQueue` only moves
  route points/JSON). This needs: picking and adding packages with camera/
  photo-library permission prompts, a capture control during recording, a
  local media store tied to a point/timestamp on the route, a Storage
  bucket with its own RLS policies, an upload queue for media (mirroring
  `JourneyUploadQueue`'s retry/backoff design, but for files), and replay
  UI that places captured media at the right point on the timeline. This
  is comparable in size to the original Journeys build itself (which took
  its own foundation → recorder → sync → UI sequence) and deserves the
  same treatment rather than being folded into a card redesign pass.

### Replay screen

Once places/stats/media exist, Replay is the natural home for all of it:
today it's a full-screen map with a floating summary card and a moment
list (delete already lives off it, per its own doc comment). A livelier,
animated redesign of that screen is the right vehicle for showing stats,
place cards and media together, but it should follow the data pieces
above landing, not precede them — otherwise it is UI for data that
doesn't exist yet.

### Suggested build order

1. Card redesign (folder/gallery look) — safe, immediate, no data change.
2. Rename + move Delete off the card — small new write path.
3. Trip stats (avg/top speed, highest elevation) — bounded schema addition.
4. Places visited as `AppPlaceRow` — data-query widening + a UI swap.
5. Replay screen redesign — brings 1-4 together with the livelier,
   animated treatment.
6. Media capture (photos/videos) — scoped and built as its own slice,
   given its size; folds into Replay (and the card) once it exists.


## Step 2 done: rename, and Delete moved into a card menu (2026-09-30)

Rename didn't exist before this (flagged as "not built yet" above); it's
now a real write path, mirroring the existing patterns:

- **Local (pending, not yet uploaded):** a nullable `title` column on
  `journey_sessions` (local schema 5, added via `customStatement` like the
  destination columns, not through generated Drift code — no toolchain
  available to run `build_runner` in this workflow). `customTitle()` reads
  it; `rename()` validates (1-120 chars, trimmed) and writes it.
  `JourneyUploadQueue._summary()` now prefers it over the synthesized
  "Trip on ..."/"Trip to ..." default, and `renameLocal()` waits for any
  running drain first so a rename can't be overwritten by an in-flight
  upload reading the old title.
- **Cloud (uploaded):** `journeys` has no client update policy (by design,
  see `20260925130000`), so a new migration
  (`20260930100000_add_journey_rename_rpc.sql`) adds `rename_journey`, a
  security-definer RPC with the same owner check as
  `upload_journey_to_place`. `SupabaseJourneyRepository.rename()` calls it.
- **App:** `JourneyHistoryList.rename()` routes to local or cloud by
  `journey.isUploaded`, same branching as `delete()`, then
  `invalidateSelf()`. `showJourneyRenameDialog` is a simple prefilled text
  dialog (`journey_rename_dialog.dart`).

Delete and the new Rename are no longer loose actions on the card face:
both sit behind a "Trip options" (⋯) menu in the card's footer, so neither
is a direct single-tap target. (The alternative considered was moving
Delete onto the Replay screen instead — went with the card menu since it
keeps both actions reachable from the list without opening Replay first;
easy to revisit if that's not what's wanted.) Delete's own confirm dialog
is unchanged.

Not done in this slice: renaming from the Replay screen itself (only from
the card), and there's no undo — a rename takes effect immediately, same
as delete.

## Step 3 done: average/top speed, highest elevation (2026-09-30)

Speed and elevation were captured by the `location` plugin all along
(`LocationData.speed`/`.altitude`) but discarded before this. Now:

- **Domain:** `JourneyPoint`/`JourneyFix` grew optional
  `altitudeMeters`/`speedMetersPerSecond` fields (validated finite;
  negative speed rejected at the constructor).
- **Capture:** `DeviceJourneyLocationSource.usableFix()` reads
  `data.altitude`/`data.speed`, treating a non-finite or negative speed
  (or non-finite altitude) as unknown (`null`) rather than rejecting the
  whole fix.
- **Local storage:** `journey_samples` gained nullable
  `altitude_meters`/`speed_mps` columns (local schema 6, same
  `customStatement`-outside-generated-code pattern as the destination/title
  columns). `LocalJourneyRepository.appendPoint()` writes them with a
  follow-up `customUpdate` when either is present; `points()`/
  `watchPoints()` now read the samples table entirely via `customSelect`
  (rather than merging generated-column and raw-column reads) so both old
  and new fields come back together.
- **Cloud:** new migration
  `20260930110000_add_journey_point_speed_elevation.sql` adds
  `top_speed_mps`/`highest_elevation_m` to `journeys` and
  `altitude_m`/`speed_mps` to `journey_points`. `journey_upload_rows()`
  had to be dropped and recreated (Postgres won't let `CREATE OR REPLACE`
  change a table function's output columns) to also emit the two new
  fields; `upload_journey()` now takes `max(speed_mps)`/`max(altitude_m)`
  across the uploaded points and stores/returns them alongside distance.
  Like the rename RPC before it, **this migration has not been applied to
  the live project** — no `supabase` CLI or deploy path exists in this
  workspace, so it needs to be run by hand (dashboard SQL editor or a
  linked CLI) before uploads will actually populate these columns.
- **App:** `JourneySummary` gained `topSpeedMps`/`highestElevationMeters`
  (both null until upload, same convention as `distanceMeters`) plus a
  derived `averageSpeedMps` getter (distance/duration, no storage needed).
  `JourneyFormat.speed()`/`.elevation()` format them. The Replay screen's
  floating summary card (`_SummaryHeader` in `journey_replay_controls.dart`)
  now shows a row of small stat chips (avg speed, top speed, highest
  elevation) under the existing facts line, each chip left out when its
  value is unknown — so a pending, not-yet-uploaded Trip just shows avg
  speed (computable client-side) until it uploads.

Not done in this slice: surfacing these stats on the card list itself (the
card redesign in Step 1 didn't plan for a third stats row, and stacking
more onto that gallery-style card face risks the "not blant" goal from the
original ask) — deferred to Step 5's fuller Replay/UI pass, which is the
natural place to reconsider what the card face shows too.

## Step 4 done: places visited, shown as Explore's place row (2026-09-30)

Places near the route already surfaced in Replay as key moments
(`JourneyMoments._places()`), but as a generic icon-and-text row — the ask
was to show them the same way Explore does.

- **Data:** `JourneyPlaceMark` gained `categoryLabel`/`description`/
  `thumbnailUrl`. `SupabaseJourneyRepository.places()` now selects
  `type, summary, place_images(thumbnail_url, sort_order)` alongside the
  existing columns (the same shape `mapPlaces()` already reads) and
  reuses the existing `_firstThumbnail()` helper.
- **Replay:** `JourneyMomentRow` branches on whether a moment carries a
  place. A place moment (saved or nearby) now renders as a `_PlaceMomentRow`
  built on the shared `AppPlaceRow` widget — same thumbnail, title,
  description, category chip and save toggle as Explore's place cards —
  with the route distance in the same "· 2.4 km" slot Explore uses for
  distance-from-me. A non-place moment (recording break, long stop, county
  crossing) is unchanged: the circular-icon row as before.
- Saving from this row uses the same `exploreSavedPlacesProvider` as
  Explore, so a save here shows up there immediately and vice versa (this
  was already true of the old row; unchanged).

Not done in this slice: the arrival time ("at 10:14am") that the old
generic row showed next to a place moment is dropped — `AppPlaceRow`'s
fixed layout has no slot for it, and stacking a time line on top would
stop it from actually looking like an Explore card. If that's missed,
worth revisiting as a small addition to `AppPlaceRow` itself (an optional
caption line) rather than a one-off in Replay.

## Step 5 (partial): Replay screen animated reveals (2026-09-30)

Scoped down from the full "lively Replay redesign" to animation polish
only, keeping the existing layout (map + floating summary/controls card):

- **Screen entrance:** `_PlayerState` now runs a 420ms fade on the map and
  a fade + slide-up on the floating controls card when Replay first
  builds, instead of both just appearing. Needed switching the state's
  mixin from `SingleTickerProviderStateMixin` to `TickerProviderStateMixin`
  since it now drives two tickers (the existing replay clock, plus this
  entrance `AnimationController`).
- **Key moments / place rows:** the moments block in
  `JourneyReplayControls` (`_MomentsReveal`) wraps in `AnimatedSize` +
  `AnimatedSwitcher` so it grows in and fades/slides in when replay pauses
  at a moment, rather than snapping into the layout; each row inside gets
  its own short staggered fade-and-rise (`_StaggeredReveal`) keyed to its
  position in the list, so a batch of moments feels like it's arriving in
  order. The entrance is 220ms; the *exit* (replay resumes, moments clear)
  is instant (`reverseDuration: Duration.zero`) — the ask was for arrivals
  to feel alive, not for the clearing to visibly linger, and an instant
  clear also kept the existing widget tests' assertions (which check a
  moment's text disappears right after tapping "Continue") accurate
  without changing their timing.
- **Play/pause:** the icon swap is now a small scale+fade
  (`AnimatedSwitcher`, 200ms) instead of an instant icon swap.
- **Map marker:** `JourneyRouteMap` gained a `pulsing` flag (wired to
  `_showing.isNotEmpty` — true only while paused at a moment). While on, a
  `Timer.periodic` steps the `journey-marker` layer's `circle-radius`
  through a gentle sine ease every 90ms (a slower cadence than the
  per-frame marker-position updates already happening during playback,
  since a pulse doesn't need 60fps to read as smooth) and resets to the
  base radius the moment it turns off.

Not done in this pass (deferred; the user chose "animated reveals only"
over the bigger draggable-sheet redesign this step could also have been):
turning the floating card into an expandable/draggable bottom sheet, and
any changes to the card list or media — those remain in Step 5's other
option and Step 6 respectively if picked up later.
