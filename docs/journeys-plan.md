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

## Step added: search and date filter for Past Trips (2026-10-01)

Not part of the original 6-step order — came out of a design discussion
about what happens once someone has a lot of Trips, and the user asked to
build the discussed version: search by title/destination, plus a quick
date filter.

- **Visibility:** the search field and filter chips only render once
  there are more than 8 Trips (`_searchThreshold` in
  `JourneyHistorySection`). Below that, the list looks exactly as before —
  no point cluttering the screen for someone with three Trips.
- **Search:** matches the Trip's title (user-given or the default "Trip
  on .../Trip to ...") and its destination name, case-insensitively.
  Reuses Explore's existing `ExploreSearchField` widget rather than
  building a new one, for a consistent look and because it's already
  exactly the right shape (a styled `TextField` with a search icon).
- **Date filter:** All / This month / Last month as `ChoiceChip`s,
  matching the same `ChoiceChip` pattern already used for replay speed.
  Reuses `JourneyTitles.monthLabel()` (built for the month-grouped
  headers) rather than re-deriving "this month" logic separately.
- **State:** kept as plain local `State` on
  `JourneyHistorySection` (now a `ConsumerStatefulWidget`), not a Riverpod
  provider — this query/filter is only ever read by this one widget, so a
  shared provider (like Explore's `exploreSearchQueryProvider`) would add
  indirection without a reason; it also sidesteps needing new
  `@riverpod`-generated code in a workflow with no `build_runner` access.
- A distinct "No Trips match ..." empty state (with a "Clear filters"
  button) shows when filtering leaves nothing, separate from the "No
  Trips yet" state for a genuinely empty history.

Deliberately deferred (flagged during the design discussion, not
requested yet): searching by county crossed. The data exists server-side
(`journey_counties`, from the badge-sheet work) but nothing in the app
currently reads that table — wiring it up means a new repository query
and joining it onto `JourneySummary`, which is real additional plumbing
rather than a tweak to this feature. Worth a follow-up if county search
turns out to matter in practice. Also deferred: a travel-mode filter
(foot/drive/fly, "Trek" naming) — blocked on travel mode not existing as
a field yet; that was scoped in the original redesign discussion but
never actually built.

## Icons and empty-state polish (2026-10-01)

Prompted by feedback that the default Material icon glyphs read as dated
next to the rest of the redesign.

- Added `lucide_icons_flutter` (pub.dev) as a dependency: a modern, clean
  line-icon set (a Flutter port of lucide.dev), picked over `phosphor_flutter`
  for being more actively maintained at the time of adding it. This is the
  app's first non-Material icon source, available for other screens to
  adopt next — this slice only touches the two Trips empty states, not a
  full icon sweep.
- Added a shared `_IconBadge` widget (icon centred in a soft 64px circular
  tint) and used it for both of Past Trips' empty states: `_EmptyState`
  ("No Trips yet") now shows `LucideIcons.route` on a tinted accent
  circle, and `_NoMatches` ("No Trips match...") shows
  `LucideIcons.searchX` on a tinted neutral circle, instead of a bare
  Material glyph sitting on its own.
- `_NoMatches` also gained a short explanatory line under the title and a
  properly pill-shaped "Clear filters" button (filled, rounded, not a
  bare `TextButton`) so it reads as a real action rather than a stray link.

**Needs a `flutter pub get` (and the usual iOS `pod install` after) before
it'll build** — this session has no Flutter/Dart toolchain to run that
itself, so the new dependency is only declared in `pubspec.yaml`, not yet
fetched or lock-filed.

## Icon-font rendering fix + county search (2026-10-01, later same day)

Two follow-ups from the first real device test of the icon/polish work above.

**Lucide icons rendered as blank "tofu boxes"** on-device, instead of
actual glyphs. `lucide_icons_flutter` resolved fine (`pubspec.lock` shows
`3.1.21` fetched correctly), so this wasn't a missing dependency — it's an
icon-font glyph not mapping to its codepoint at runtime, a class of bug
that has bitten other Flutter icon-font packages after an SDK bump (seen
in `phosphor_flutter`'s own issue tracker). With no Flutter/Dart
toolchain available in this environment to actually debug the font at
runtime, the robust fix was to stop depending on an icon font at all:
- Removed the `lucide_icons_flutter` dependency entirely.
- Added `assets/icons/route.svg` and `assets/icons/search_x.svg` —
  hand-authored from Lucide's own published icon paths (ISC-licensed,
  same visual source), as plain stroke-style SVGs (`viewBox 0 0 24 24`,
  `stroke="currentColor"`).
- `_IconBadge` now takes an `iconAsset` path and renders it with
  `SvgPicture.asset` (`flutter_svg`, already a dependency and already
  used elsewhere in the app for `onboarding.svg`) with a `colorFilter` to
  tint it, instead of `Icon(IconData)`.
- This sidesteps font/codepoint/SDK-compat risk completely: an SVG asset
  either renders its vector paths or fails to load outright — it can't
  render as a silently-wrong glyph.
- Registered `assets/icons/` in `pubspec.yaml`. Needs a `flutter pub get`
  before building (dependency removal + new asset folder).
- Takeaway for later icon needs: prefer adding more hand-picked SVGs here
  (or a battle-tested package in actual device-tested use elsewhere)
  over another icon-font package, until one is confirmed fine on a real
  build.

**Search by county crossed.** Typing a county name (e.g. "Kiambu") now
also matches any Trip whose route passed through it, not just its title
or destination:
- `JourneySummary` gained `countyNames` (`List<String>`, defaults to
  `[]`).
- `SupabaseJourneyRepository.history()` now reads `journey_counties`
  (`journey_id, county_id`) alongside `journeys` in one `Future.wait`,
  maps `county_id` -> name via the existing `CountyPaths.all` table (no
  extra round-trip to the `counties` table), and attaches each Trip's
  county names.
- `_matches()` in `journey_history_section.dart` now also checks
  `countyNames` after title/destination.
- Journeys still waiting to upload, and any uploaded before the
  `journey_counties` migration landed, simply have an empty list — they
  just won't match on county, which is the correct fallback (no crash,
  no guessing).
- Scope: this only wires search. The RLS policy already restricts
  `journey_counties` reads to the owner, so no new Supabase migration was
  needed for this step — it only reads data `upload_journey` was already
  writing.

## Trips open to everyone, with a free monthly limit (2026-10-01)

Trips were Pro-only; now every account can record one, but an account
without Pro is capped at 3 saved Trips a month (resets the 1st, UTC). Pro
stays unlimited. Decisions made with the user before building: the limit
resets monthly (not a one-time lifetime trial), it's charged when a Trip
is actually saved/uploaded (not when it's started, so an abandoned
recording never costs a slot), and everyone starts at 0 — no retroactive
penalty for Trips recorded before this shipped.

**Server (new migration, undeployed along with the two from Steps 2/3):**
- `journey_trial_usage (user_id, period_month, trips_used)` — a monotonic
  per-month counter, not a count of `journeys` rows: deleting a past Trip
  must never hand back a free slot. RLS lets a user read only their own
  row; only `upload_journey` (security definer) ever writes it.
- `my_trial_status()` — the signed-in user's usage this month, for
  showing "2/3" before Start is even tapped.
- `upload_journey` no longer hard-rejects a non-Pro upload. For an
  account without Pro it now checks (and, on success, increments) this
  month's count, locking the usage row (`for update`) so two concurrent
  uploads can't both slip in as the 3rd. Rejection uses a distinct error
  code (`75001`) so the client can tell "limit reached" apart from other
  permanent failures.
- Along the way, found and fixed a real bug in the still-undeployed Step
  3 migration: it had redefined `upload_journey` with a 6-argument
  signature, silently dropping `p_paused_ms`/`p_counties` (and the whole
  county-split insert) because the app always calls the 8-argument
  overload — the 6-arg version would have been permanently dead code.
  Already caught and fixed by an earlier same-day migration
  (`20261001000800_fix_journey_upload_stats_signature.sql`) before this
  work started; the new trial-limit migration builds on that corrected,
  full signature.

**Client:**
- `JourneyTrialStatus` (tripsUsed/tripLimit/resetsAt) and
  `JourneyTrialExhausted` replace the old hard `JourneyStartDenied`.
  `JourneyEntitlement.canStart()` now checks Pro first and only falls
  back to the live trial-status RPC when Pro doesn't cover it; it always
  either returns true or throws, never a bare `false`.
- Trial status is held in a generated `@riverpod` notifier and reset when
  the signed-in account changes. This follows the v2 architecture guide's
  Riverpod code-generation requirement and prevents a previous account's
  usage count flashing on a new account.
- `JourneyStartCard` is now a single compact row (icon, title, a one-line
  status, the usage pill, Start/Details) instead of the old icon-row +
  paragraph + full-width-button stack — addresses the "this card eats too
  much space" feedback at the same time, since the old copy explaining
  Pro no longer applied anyway. The pill shows "PRO" for a Pro account,
  "x/3" (turning the same warm amber as the PRO chip once it hits 3) for
  a free one, refreshed best-effort on card mount and again after a Trip
  finishes uploading. There is not yet a purchase flow; Details explains
  the limit and reset date without implying an upgrade can be purchased.
- A completed local Trip whose upload is rejected for the monthly limit
  is tracked with a new `blocked_by_trial_limit` column (schema 7, same
  raw-SQL-column pattern as `title`/`destination_*` — no codegen rerun
  needed) and surfaces in the history list as "Free limit reached"
  instead of the generic "Waiting to upload", so it doesn't read as stuck
  or broken. The upload queue's existing day-later backoff for permanent
  rejections is what naturally retries it once the month rolls over -
  no special-cased scheduling needed for that part.


## Addendum (2026-10-01): Trip media - photo capture, upload, Replay

Branch: `explore/trip-media`. Scope confirmed up front: photos only (no
video for now), capturable only while actively recording (not from
history or while paused), and a full vertical slice - capture, upload,
and display in Replay - rather than a capture-only first cut.

**Why genuinely new infrastructure, not an extension of the points
pipeline:** Trips have never stored a local file before (no
`dart:io` File usage, no `path_provider` anywhere in `lib/` before this),
and binary uploads don't fit the RPC pattern `upload_journey` uses for
points - Storage uploads go straight from the client, governed by RLS,
not through a security-definer function.

**New dependencies:** `image_picker: ^1.2.3` (camera capture only, via
`ImagePicker().pickImage(source: ImageSource.camera)`) and
`path_provider: ^2.1.5` (already present transitively through
`drift_flutter`; added directly since new code now imports it) - to copy
image_picker's cache file into the app's persistent support directory
before the upload queue can rely on it still being there.

**Local storage:** a new raw-SQL table, `journey_media_captures`
(schema 7 -> 8, via `customStatement` like every other schema change in
this file - no `build_runner` available, so no new typed Drift table
either), holding the captured file's local path, capture time, and the
last known fix's lat/lng. `LocalJourneyMediaRepository` mirrors
`LocalJourneyRepository`'s raw-SQL query style for it.

**Upload queue:** `JourneyMediaUploadQueue` mirrors `JourneyUploadQueue`'s
drain/backoff shape, with one extra gate: a photo waits until its own
Trip's points have finished uploading (checked via
`journeyStillLocal` - whether a local `journey_sessions` row for that
Trip id still exists), since `journey_media.journey_id` references
`journeys` and would otherwise just fail the foreign key. No
permanent-vs-transient split like the points queue has for the trial
limit - there's no permanently-failing case for a photo upload, so any
error just backs off and retries. `JourneySync.drain()` now runs the
media drain right after the points drain, so every existing call site
(periodic/resume sync, pull-to-refresh, a Trip's own `finish()`) picks up
photo sync for free, with no new lifecycle wiring.

**Cloud:** `20261001020000_add_journey_media.sql` adds a private
`journey-media` Storage bucket (per-user folder RLS via
`storage.foldername(name)`, unlike the public admin-gated
`place-images` bucket) and a `journey_media` table (owner-only RLS, plus
a check that the referenced Trip is also theirs). The client uploads
directly via `client.storage.from('journey-media').upload(...)` and
inserts/upserts the row itself - no RPC, since a Postgres function isn't
a practical place to receive a binary upload. `SupabaseJourneyRepository`
gained `uploadMedia()` and `media()` (the latter returns each photo with
a fresh one-hour signed URL, since the bucket isn't public).

**UI:** a camera button appears in `JourneyRecordingControls` only while
actively recording (not paused, per the confirmed scope), opening the
system camera via image_picker and handing the result to a new
`JourneyRecorder.captureMedia()`. Replay shows a Trip's uploaded photos
as a horizontal thumbnail strip (`JourneyMediaStrip`, new) near the top
of the map, tappable for a full-screen pinch-to-zoom view; it renders
nothing for the (expected to be most) Trips with no photos, so it costs
no layout space for them. Discarding an in-progress Trip now also drops
any photos captured for it (local row and file), matching how discarding
already drops the Trip's points.

**Not done, deliberately deferred:** media isn't woven into the
point-by-point replay animation (no pins at capture locations, no
pausing replay on arrival at a photo) - the strip is a simple top-level
gallery instead, which covers "see the photos from this Trip" without
the complexity of aligning arbitrary capture timestamps to route indices
the way the existing key-moments system does for places. Also deferred:
a thumbnail badge on Trip cards in history showing photo count.

## Addendum (2026-10-01): fail fast when location isn't available

`JourneyLocationSource` gained `ensureAvailable()` - the same services/
permission/background-permission checks `start()` already did, pulled out
so `JourneyRecorder.start()` can call them first, before the live Pro/
trial check and before creating a local session row. Previously a phone
with location off or permission denied still paid for a network round
trip and a throwaway DB insert+delete before failing; now it fails
immediately with the same `JourneyLocationException` (and the same
"Turn on location services…" messaging `JourneyStartCard` already had).
`start()` still calls `ensureAvailable()` again as part of actually
attaching, since permission can still be revoked in the gap between the
two checks - that existing race-handling path is unchanged.

## Known issues / backlog

- ~~No gate for a Trip that never gets a GPS fix.~~ **Fixed 2026-10-01.**
  A Trip could sit in "Recording" indefinitely with 0 points and 0 m if
  location never actually produced a fix after Start (confirmed on an iOS
  Simulator run with no simulated location). The `ensureAvailable()` guard
  added earlier the same day only checked that location services/
  permissions were *granted*, not that a fix was actually arriving.

  Went with Option 1 from the fork below: `JourneyCapture.attachStarted()`
  now blocks until the first real fix arrives (reusing the existing single
  `_subscription` via a `Completer<void>? _firstFix`, completed from
  `_listen()`'s fix callback - a second listener isn't safe here, since
  one existing test uses a single-subscription stream for `fixes`). A
  `firstFixTimeout` constructor param (default 20s) bounds the wait; on
  timeout, `attachStarted` throws `JourneyLocationException` with the new
  `JourneyLocationFailure.noFixReceived` reason, which reuses the existing
  failure-handling path in `JourneyRecorder.start()` (Journey discarded,
  not left paused - same as any other `JourneyLocationException`) and has
  its own message in `JourneyMessages.forError()` ("Couldn't get a GPS
  signal..."). Tests that called `attachStarted()` then pushed a fix
  afterward were rewritten to push the fix during the await instead (via
  `pumpEventQueue()` then `source.controller.add(fix)` before awaiting the
  pending `attachStarted()` future); `JourneyRecorder`'s own tests'
  `_FakeSource.start()` now auto-emits a fix via a zero-duration `Timer`
  so the many tests that just `await recorder.start(...)` keep working
  unchanged.

  <details>
  <summary>Original fork (for history)</summary>

  Two ways to fix it, not yet decided between:
  1. Block Start until a first fix arrives (e.g. up to a ~20s timeout),
     failing Start outright with the same location-error messaging if
     none comes. Simpler mental model, but `JourneyCapture.attachStarted()`
     currently resolves as soon as the stream is subscribed - every
     existing test that calls `attachStarted()` then pushes a fix
     afterward would need reworking to push the fix before/during the
     await instead.
  2. Let Start stay instant; if no fix arrives within a timeout while
     "Recording", auto-pause or discard and surface an error. Needs the
     UI to show an error for a pause it didn't initiate (today
     `JourneyCapture.lastError`/`onUnexpectedPause` only updates state
     silently, nothing reads `lastError` to show a message) - and still
     leaves a window where the clock ticks with nothing recorded before
     the timeout fires.

  Whoever picks this up should settle that fork with the user first
  rather than guessing.

  </details>


## Photos surface in Replay as the marker reaches them (2026-10-01)

Trip photos used to only show as a static strip pinned over the map for
the whole Replay. Now each photo is a key moment: the replay marker
pauses at the route point closest to *when* the photo was taken (not
where - `recordedAt` vs `capturedAt`, since a phone can sit at one GPS
fix for minutes while several photos are taken, and `recordedAt` is what
actually orders the route the marker walks along), shows it in the same
paused-moment card as a recording break or a nearby place, and resumes
on Play/Continue - exactly the existing `JourneyMoments` pause/resume
mechanism, extended rather than replaced.

- `JourneyMomentKind.photo` + a `JourneyMoment.photo` field
  (`domain/journey_moments.dart`). `JourneyMoments.find()` takes a
  `photos: List<JourneyMediaItem>` param; a new `_photos()` finder
  matches each photo to the point with the closest `recordedAt`.
- `journeyMoments` (`application/journey_key_moments.dart`) now also
  watches `journeyMediaProvider(id)` and passes the photos through -
  still computed off the UI isolate alongside the county lookups.
- `JourneyMomentRow` (`presentation/journey_moment_row.dart`) renders a
  photo moment as a thumbnail row ("Photo taken here · <time>"), tapping
  opens it full screen. `journey_media_strip.dart`'s full-screen opener
  was made public (`openJourneyPhoto`) so both the strip and the moment
  row share it instead of duplicating the page route.
- No change needed to the replay ticker itself
  (`_Player._onTick`/`JourneyMoments.nextStopAfter`/`.at()`
  in `journey_replay_screen.dart`): it already pauses at *any* moment in
  `widget.moments` by index, so adding photo moments to that list was
  enough. The map pin list (`_pinsFor`) already pins every non-place
  moment too, so a photo's location gets a pin on the overview map for
  free.
- The static top strip (`JourneyMediaStrip`) is unchanged and still
  shows all of a Trip's photos at once, independent of replay position -
  useful for skimming before pressing Play.


## An elevation-peak moment, single highest point only (2026-10-01)

Elevation previously only showed as a Trip-wide stat pill ("Elev 1,234
m", `JourneySummary.highestElevationMeters`), not tied to any point on
the route. Added `JourneyMomentKind.elevationPeak`: the replay marker
now also pauses once, at the single highest-altitude point of the route,
showing "Highest point of the Trip · 1,680 m" (`JourneyMoment.elevationMeters`,
formatted with the existing `JourneyFormat.elevation`).

- `JourneyMoments._elevationPeak()` (`domain/journey_moments.dart`) scans
  `JourneyPoint.altitudeMeters` (already recorded per fix, already synced
  to Supabase as `altitude_m`) for the single max, and only yields a
  moment if it clears `elevationPeakMinimumGainMeters` (30 m) above the
  route's lowest known altitude - GPS altitude is noisier than
  horizontal position, so a flat urban Trip shouldn't get a "highest
  point" pause off a few metres of jitter. No moment at all when no
  point on the route has altitude data.
- Deliberately *not* built: per-climb detection (pausing at every
  meaningful ascent, not just the single peak). That's a reasonable
  follow-up for hiking-style Trips but needs its own threshold tuning;
  left out for now at the user's instruction ("just the single high
  point for now").
- Same mechanism as the photo moments above: no changes needed to the
  replay ticker, `nextStopAfter`/`.at()`, or the map-pin logic - adding
  a new `JourneyMoment` to the list `journeyMoments` returns is already
  enough for the marker to pause there and for `_pinsFor` to pin it.
- `journey_moment_row.dart`'s `_describe` switch got an
  `elevationPeak` case (icon `Icons.terrain`, matching the stats pill's
  icon) rather than a bespoke row, since - unlike a photo - there's
  nothing to show but text and nothing to tap through to.
