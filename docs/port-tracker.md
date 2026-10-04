# V1 → V2 port tracker

One row per feature. Source: `kokodavid/kaunti47`, branch `redesign/figma-v2`
(about 40k lines). Update this file in the same commit/PR that moves a feature: the table row,
the feature's section below (if it has one) and the progress log.

Status: `Not started` · `In progress` · `In review` · `Done`

| # | Feature | V1 location | V2 status | PR | Notes |
|---|---|---|---|---|---|
| 0 | Guardrails (rules, CI, review) | n/a | Done | #1 (main) | Riverpod deps, strict analysis, architecture guard + baseline, CI, Claude review, docs |
| 1 | Foundations re-homed to `core/` (config, design, widgets, counties, services) | `lib/src/{config,design,widgets,counties,services}` | Not started | | Move to `core/`. Clears most `layout` baseline entries. `core/services/supabase_client_provider.dart` exists (Explore uses it) |
| 2 | Auth + onboarding on Riverpod + go_router | `lib/src/features/auth`, `lib/src/screens/onboarding` | In progress | codex/go-router | go_router (`app/router.dart`, `appRouterProvider`); start-up gating is one redirect on `StartupFlow` (`features/onboarding`), the old `app.dart` state machine ported rule for rule; sign-in on a Riverpod notifier with error mapping in the data layer. Left: move the onboarding pages from `screens/` into `features/onboarding/presentation`, sign-out (with detection's local-state clearing), v1's 3 how-it-works intro screens |
| 3 | App shell / bottom nav | v1 `AppShell` | In progress | codex/go-router | `app/app_shell.dart` on a go_router `StatefulShellRoute.indexedStack`: tab branches keep their own stacks and state, built lazily (v1 parity). County / Place Detail are routes (`/county/:code`, `/place/:id`). Map + Explore live; Badges / Ranks show "coming next" |
| 4 | Map Home (+ variants 1a–1e) | `features/map_home` | In progress | codex/home-migration | Board, sheet, For You, peek, v1 map interactions, Supabase data ported. See [Map Home](#map-home-4) below |
| 5 | Detection (geofence, visit state machine, offline drift queue) | `features/detection`, `features/offline` | In progress | main (#3) | Plan: [detection-port-plan.md](detection-port-plan.md). Slices 1-7 coded. Foreground local detection/dwell/sync checks run every 15 s, while hardware location is read on start/resume and at most every 2 min; background crossing relies on OS geofences. Dev-only opt-in diagnostics can log cycle/GPS-read counts and geofence transitions. Physical-device validation still needed. |
| 6 | Discover + Wishlist, County/Place Detail | `features/discover` | In progress | main (#3) | County + Place Detail ported. Explore tab (MINE, UNCLAIMED, SAVED/Wishlist) ported on Riverpod; offline cache deferred. See [Discover](#discover-6) |
| 7 | Badges + tiers | `features/badges` | In progress | codex/badges | [Plan](badges-port-plan.md). Step 1: Badges tab on the new design (Figma 491:1394, star-less badge 277:19839): title + tier pill, claimed hero with 47-segment bar, collection grid with depth rings (county_visits + county_depth_ranks). "Since reset", the activity card, avatar and saved-data time wait on product rules. |
| 8 | Profile, Settings, Data & Privacy | `features/profile` | In progress | codex/journey-place-handoff | First-release account overview from Home avatar: auth identity, home county, badges, live Pro status, Journeys link, OS location settings, privacy summary and sign-out (removes native county geofences first). Full settings, published policy/support links and account deletion remain. |
| 9 | Ranks, leaderboards, seasons | `features/ranks` | Not started | | Tab hidden from the bottom nav until ported (`AppFeatureFlags.ranks`, `--dart-define=RANKS_ENABLED=true` to show it). |
| 10 | Quests / side quests + sharing | `features/quests` | Not started | | |
| 11 | Friends | `features/friends` | Not started | | |
| 12 | Pro / M-Pesa monetization | docs only in v1 | Not started | | |
| 13 | Journeys (new Pro feature) | New in v2 | In progress | codex/journey-place-handoff | [Plan](journeys-plan.md). Schema, local store/native capture, private sync/history, route handoff, rename, stats, county splits, camera-roll photo matching, replay moments and share-card media. Free accounts may save up to 3 Trips per UTC month; Pro is unlimited. Server migration owns the counter and upload limit; offline Trips rejected at the limit remain local and can retry after reset. Search/date filters appear after 8 Trips. Free-tier migration deployment, export, long-route performance and device checks pending. Subcounty coverage deferred. |

## Baseline burn-down

| Date | Baselined violations | Note |
|---|---|---|
| 2026-09-23 | 49 | Guard introduced over the imported v2 onboarding code |
| 2026-09-25 | 28 | `app.dart` state machine and the `ChangeNotifier` sign-in controller replaced (go_router work) |

## Feature notes

### Journeys (#13)

- Free accounts can save three uploaded Trips per UTC calendar month; Pro
  accounts remain unlimited. The server counter is monotonic for each user
  and month, so deleting a saved Trip does not restore usage. Offline Trips
  are charged when they successfully upload.
- `journey_trial_usage` is readable only by its owner. `upload_journey`
  serializes monthly allowance checks and increments usage in the same
  transaction as saving the Trip. Apply
  `20261001010000_add_journey_free_trial.sql` before shipping this policy.
- The app shows the usage count, explains the reset date when exhausted, and
  keeps a locally recorded Trip available when the server refuses its upload
  at the limit; the queue retries it later. Journey history search/date
  filters appear after the list grows beyond eight entries.
- Pending: a Pro purchase flow, migration deployment, device validation,
  and large-route performance checks.
- Battery pass: foreground detection keeps local dwell/sync work on a 15 s
  cadence but limits GPS reconciliation to start/resume and every 2 min. Journey
  capture uses mode-specific intervals/distance filters and enables platform
  auto-pause; stale background location is stopped during recovery and every
  capture teardown. Sampling values are initial profiles, not measured battery
  guarantees. Verify battery use, route fidelity, lock-screen capture and
  pause/resume behavior on physical iOS and Android devices before release.
- Dev-only whole-app location diagnostics are documented in
  [location-diagnostics.md](location-diagnostics.md). Local JSONL reports
  include Detection lifecycle/cycle events, native geofence transitions,
  battery samples, Journey start/stop, and existing segment-gap events; they
  exclude coordinates and account identifiers. Reports are shared manually.

### Dev Location Diagnostics

- Dev-only compile gate (`LOCATION_DIAGNOSTICS` in `dart_defines/dev.json`)
  and dev runtime check. Profile opens a local session recorder with start/stop,
  JSONL share, text summary copy, and clear actions.
- Reports sample native battery percentage at session start/stop and foreground
  transitions; Detection cycles/GPS reads and OS geofence events; Journey
  location start/stop and the existing segment-gap threshold events. No raw
  coordinates, place names, account IDs, or automatic uploads.
- Runbook: [location-diagnostics.md](location-diagnostics.md). Device profiling
  with Xcode Energy Log / Android Battery Historian remains required; the
  percentage delta is only a coarse whole-device signal.

### Profile (#8)

- Home avatar opens an account-bound Profile route. Until auth resolves (and
  the stream ID matches the current user), it shows a neutral state rather
  than any previous account's identity or progress.
- Name/email come from the signed-in user, home county from onboarding state,
  earned count from Badges, and Pro status from the live entitlement RPC.
  Links open the existing Badges/Journeys tabs and device location settings.
- Data and privacy explains the data this build stores. Sign-out blocks while
  a Journey is active, removes native county geofences, then resets the
  startup route. A failed sign-out resumes detection for the still-signed-in
  account.
- The account header uses v2's light-blue band and blue action accents; the
  information rows remain neutral for scanning.
- Profile's compact redesign keeps the account-bound auth gate and live
  entitlement behavior, adds the onboarding home-county chip and a live
  47-county progress card, and previews earned counties with the shared
  `CountyBadgeMedallion`. Membership, Trips and privacy use the existing
  profile tile component in surface/dark variants; dev-only location
  diagnostics, location settings and guarded sign-out remain available.
- Pending before release: published policy/support destinations, a real
  account-deletion workflow, app-version display, and device-level transition
  checks. The in-app summary is not a substitute for the privacy policy.

### Map Home (#4)

**Ported (matches v1)**

- Board layout: top bar and stat card above a top-aligned full-bleed map,
  pull-up sheet over it (0.14 peek, 0.88 max, sized to content, 16px gaps).
- For You section with suggestion media, quest preview card.
- Shared content type scale: `core/design/app_type_scale.dart`
  (`AppTypeScale`, Inter tuned ~10% below v1's DM Sans sizes) now drives
  For You, the quest card, Explore (`ExploreStyles`) and the detail pages'
  body / section / stat styles. Photo titles 16 / captions 11 everywhere.
  The featured For You card uses the compact set (title 15, reason 12,
  stats 12/10, Route 12) with a 136px photo and a 72px county tile.
- For You split (Figma "Your next best move" / "Nearby and unclaimed"):
  the top card ("PRIMARY TARGET") shows one `for_you` promotion with its
  AD label, picked by `for_you_promotion()` (migration
  `20260924150000`, reordered by `20260924160000`): the anchor county's
  ads first (county of the live fix, else last visited, else home county),
  then nearest county by centroid distance, then priority, then ties
  rotate at random per load. The app waits up to 2.5 s for the fix. Before that RPC is deployed the app
  reads active rows directly and rotates among the top priority. It shows the place photo, county, summary and place stats; it
  opens Place Detail and Route goes to the place's coordinates. With no
  promotion it falls back to a saved / depth pick, else the nearest
  unclaimed county. Below, "NEXT FOR YOU / Nearby and unclaimed" lists at
  most 6 nearest unclaimed counties (`discover_unclaimed_counties()`, county
  photo, distance, Unclaimed pill, Route) and "All N left ›" opens
  Explore's UNCLAIMED tab (`context.go('/explore')`, keep-alive tab provider).
  Promotion impressions/taps aren't reported yet.
- For You featured card redesigned (Figma "Your next best move"): inset
  photo with place/county name and a glass Route button; below, "<County>
  County", reason · distance, Area / Elevation / Duration and the county
  shape in a white squircle. Place suggestions show the place's stats,
  county suggestions the county's (`counties.area_km2 / elevation_m /
  duration_minutes`). Route (featured and compact cards) opens driving
  directions in the maps app by place/county name, wired from `app/`.
- County map: press highlight + name/status label, pinch-zoom 1x–4x with
  animated RESET, small-county tap halo, v1 state colours (shared with the
  peek sheet), zoom-independent strokes, just-unlocked 3-letter label. The
  chosen home county always uses the Home colour, including before its first
  visit, matching the legend.
- Stat card compact state while the map is browsed.
- Loading state (v2 addition, v1 shows a spinner): the board renders at
  once with same-sized placeholders (masked top-bar chip and stat numbers,
  pulsing tick bar, uncoloured pulsing county outlines, For You card
  skeleton), then each slot crossfades to real data in place.
- Supabase-backed visits, counties and recommendations
  (`SupabaseMapHomeRepository`).
- County profile facts seed: `counties.area_km2`, `population`, `capital`
  (county headquarters) and `governor_name` are seeded for all 47 counties
  from official sources; `elevation_m` is the elevation at each county
  headquarters town.

**Deliberate differences from v1 (temporary)**

- Tap opens the county peek sheet; v1 opens County Detail. Switch to v1's
  tap → detail (long-press stays peek) when #6 lands. The peek's
  "Open County" button only closes the sheet until then.
- Map overlay labels use Inter semibold, not IBM Plex Mono bold (not bundled).

**Pending**

- Empty (1a) and dimmed (1d) map modes, "you are here" pin: need #5.
- Board variants 1a–1e, milestone / season-live / manual-mode / tip cards,
  quests row, friends strip, offline cache, arrival nudge sheet.

**Real map (Mapbox) — Home's default, decided 2026-09-23**
- Opening camera: one native position read (v1's `currentLocation`
  channel, ~5 s, never stored), then one flight, 3D (50° tilt): the user
  at zoom 8.5 when inside Kenya, else the home county, else all of Kenya.
  No follow-the-dot mode, so nothing pulls the camera later. (Previously a
  fix outside Kenya, e.g. the emulator's default California location, was
  clamped to a random border spot.)

- Home renders the Mapbox map edge to edge behind the header, sheet and
  nav; top bar and stat card float on it. Built on `codex/mapbox-spike`,
  merged into `codex/home-migration`.
- Fallback: the drawn county map shows when there's no token, on web, or
  when the Mapbox style fails to load / doesn't load within 12 s (e.g. no
  signal on a cold start). Home stays on the drawn map until the user taps
  the "OFFLINE MAP ↻" chip; it never flips maps mid-session by itself.
  A pulsing county-outline skeleton covers the real map until it's ready.
- Real map content: counties from bundled `assets/geo/kenya_counties.geojson`
  (v1 seed geometry), "fog of war" styling (unclaimed hazed grey, claimed
  clear with a state-colour border); place pins from `places` — dots when
  zoomed out, photo/type markers from zoom 6; 3D terrain on by default;
  Light / Terrain / Satellite; opens on the user's location (else home
  county); tapping a county flies to it and opens the peek.
- The drawn map and `CountyPaths` stay: fallback Home map, county artwork
  (peek, cards, badges, share cards, onboarding picker), arrival moments.
  Crossing detection (#5) is independent of both maps.
- Candidate follow-ups: offline Mapbox with an in-app minimal style (would
  let the drawn Home map retire, needs a real-device test); compact stat
  card by default on the real map; Pro split (3D, satellite, offline packs,
  journey recording).

**Known debt (fix before marking Done)**

- Board loading isn't on Riverpod: `MapHomeBoardLoader` is a plain class and
  the screen uses `FutureBuilder`. Move to a `@riverpod` repository provider
  and board notifier with `AsyncValue`.
- `app.dart` falls back to `MockMapHomeRepository` when Supabase isn't
  initialised, which can flash mock data (AGENTS.md rule 9).
- Error state is still a full-page message with no retry (planned: keep the
  outline map and show a small retry card).
- No tests for `SupabaseMapHomeRepository` or the board.
- `AppColors.pendingFill` and `justUnlockedFill` are unused since the v1
  colour port; remove or reuse.
- Real map: Mapbox location telemetry is off by default (iOS: AppDelegate
  sets `MGLMapboxMetricsEnabled` = false once at launch; Android:
  MainActivity calls Mapbox Common `TelemetryUtils.setEventsCollectionState
  (false)` once, via the `com.giglab.kaunti47/mapbox` channel after the
  first map is created). Users can opt back in from the map's (i) menu,
  which must stay visible. Needs a device check on both platforms (Android
  uses reflection, so a Mapbox Common rename would only log a warning).
  Billing (MAU) events still run and can't be disabled. Mapbox /
  OpenStreetMap attribution not yet in Credits — required before release. Doc 05 and doc 06 ("one projection
  everywhere") need updating for the real map.
- Real map status and map choice live in widget state
  (`MapHomeBoard`), not a Riverpod provider — move with the board to
  Riverpod (#2). No widget tests for the real map yet.

### Discover (#6)

**Ported (matches v1)**

- County Detail (Figma 235:7261): photo carousel (county photo, then place
  photos) with back button, centred name and status chip ("NOT VISITED
  YET" / "PASSED THROUGH N TIMES" / "EXPLORED" / "LOCAL EXPERT"); title,
  Area / Elevation / Population, county shape (solid when explored, dashed
  when not); blurb; Governor / Headquarters / Source card (headquarters from `counties.capital`, replacing v1's "Established"); "Places to See"
  photo cards with save toggles.
- Place Detail (Figma 235:7353): photo carousel with category pill, title,
  description, Source / Type card, Get Route (Google Maps directions) /
  share (coming soon) / save bar.
- Saving writes `wishlist_items` (optimistic, reverts on failure).
- Links from Map Home via `app/detail_routes.dart` (features don't import
  each other's screens): drawn map tap opens County Detail and long-press
  peeks (v1 parity); "Open County" on both maps' peek sheets; For You cards;
  "Open Place" on the real map's place sheet.

**Differences from v1 (temporary)**

- No distance labels (v1: place cards and Place Detail's Distance fact);
  v2 has no foreground location read yet.
- Images use `Image.network` (v1: `cached_network_image`).

**Explore tab — ported (matches v1)**

- First feature on `@riverpod` codegen (`application/explore_providers.dart`):
  board, selected tab, search text and saved-place overrides.
- Header: "Discover" title, search (county name or place text), MINE /
  UNCLAIMED / SAVED pills with counts (MINE's count excludes the featured
  county, v1 parity).
- MINE: "JUST UNLOCKED" card for the newest explored county (rarity line,
  two places, "ALL N PLACES IN …" opens County Detail), then the other
  explored counties listed straight below it, newest first, as accordions
  (first open, "Explored" or "Local expert · N visits", three places, "SEE
  FULL COUNTY PAGE →"). v1's "MINE / Nearby and unclaimed" heading is
  dropped (it described UNCLAIMED, not MINE). Empty card for a new traveller; "Nothing
  matches" for an empty search.
- Place rows open Place Detail and save to `wishlist_items` (optimistic,
  reverts with a note on failure).
- Data: `discover_mine_counties()`, `places` with first image, `wishlist_items`,
  `counties.rarity_pct` (read separately; "Rarity not tracked yet" when null). Status lines
  across MINE / UNCLAIMED / SAVED are sentence case.
  Distances are straight-line from one foreground fix (1.2 s budget, never
  stored).
- UNCLAIMED: counties with no explored visit, nearest first (live fix, else
  the RPC's last-visited / home-county anchor). The closest is the featured
  "CLOSEST ONE YOU DON'T HAVE" card (county photo with name and blurb, or the
  dashed shape, distance and blurb), with "See what's there" (County Detail)
  and a county Save / Saved toggle. The rest are accordions: rarity line
  (rarity once tracked; until then distance, "45 km away", else "HQ ·
  <town>" from `counties.capital`), blurb, three places,
  "SEE FULL COUNTY PAGE →". Then the rarity note card.
- SAVED (Wishlist): "N places saved across M counties", county groups
  (most recently saved first, first open) with status in sentence case
  ("Local expert / Badge earned · N still to see", "Locked · N saved",
  "Saved county · nothing picked yet"), hand-ticked rows (strike-through + "COMPLETE"), the "ticked
  by hand" footer, and an empty card.
- Writes: county save (`wishlist_items` row with no place) and ticks
  (`ticked_at`) are optimistic and revert with a note on failure. A place or
  county save refreshes the board in place (no skeleton) so SAVED and the
  counts catch up; ticks don't reload.
- The title, search and pills stay fixed; only the active list scrolls,
  and each tab keeps its own scroll position (v1 scrolled the header away).
- The first load shows an account-neutral skeleton; errors show "Try again".
  Explore unmounts on sign-out, so a board never outlives its account.

- Explore's top cards (MINE "JUST UNLOCKED", UNCLAIMED "CLOSEST ONE YOU
  DON'T HAVE") use the shared feature card (`core/widgets/
  app_feature_card.dart`, same as Home's For You): county photo, rarity or
  distance, blurb, Area / Elevation / Duration, county shape; Route opens
  directions to the county on MINE; tapping opens County Detail. The
  UNCLAIMED card has no photo buttons: its caption is "HQ · <town>" and
  distance joins the stats (Area / Elevation / Distance). Saving a whole
  county has no button in Explore for now. The MINE card's two place rows and "ALL N PLACES"
  link and UNCLAIMED's "See what's there" button are gone (County Detail
  has them).
- County Detail (v2 addition): place filters above the place cards, "ALL ·
  N" then one pill per category the county's places have, in Explore's
  pill style.
- County Detail quick facts now have seeded Area, Population, Governor,
  headquarters/capital and headquarters elevation data for all 47 counties.
- Paid place placements are modelled separately in `place_promotions`, with
  the dashboard RPC `set_place_promotion_dashboard(...)` creating/updating an
  active AD row or deactivating it. `places` remains the editorial listing.
- Promotion edits keep one active AD per place. Changing placement from
  `places_to_see` to `for_you` updates the active row rather than creating a
  second live ad.
- Discover MINE and UNCLAIMED preview rows include an active promoted place
  and pin it to slot two when at least one normal place can appear before it;
  if it is the county's only place, it appears first and is marked `AD`.
- County Detail adds a compact Deckwatch “In the news” row with a 30-day
  report count and latest headline; it opens a bottom sheet with report
  location, category, date, outlet/corroboration count and external source
  links. A recent (48-hour), multi-outlet high-severity report can show a
  prominent alert banner; medium-severity items use an advisory treatment.
  Reports whose headline names a single different county are silently
  excluded. Feed errors/retries are isolated from county facts and places.
  Visibility for the alert and news row is controlled by the dashboard's
  `county_news` feature flag (`app_feature_flags`); the app hides both while
  the flag is unresolved, disabled, missing, or unavailable.
  The news sheet also loads DeckWatch's county summary endpoint, showing
  30-day report volume, change from the previous period, leading categories
  and high/critical report counts. Summary loading/errors are isolated from
  the incident list and support retry.
  The sheet explicitly says reports are not independently verified or a
  safety rating. Places to See uses a horizontal photo-card carousel. The
  mockup's “Wrong county or duplicate?” action is not
  implemented until Deckwatch provides a feedback endpoint; report thumbnails
  are also omitted because the feed exposes no usable image field. The mockup's
  Map action is deferred because County Detail place data has no coordinates
  or map-launch action to wire it to.

**Differences from v1 (temporary)**

- No distance labels on the detail pages (v1: place cards and Place Detail's
  Distance fact).
- Images use `Image.network` (v1: `cached_network_image`).
- Detail text is sized to v2's Inter scale (v1's DM Sans sizes read ~10%
  larger): names 20 (v1 24), "Places to See" 18, nav title 17, place card
  titles 16, body 13, stat values 13, status chip 11.
- Explore's tier pill and avatar are left out: v1 hard-coded "Tier 1" and a
  gradient dot. They return with real tier/profile data.
- Explore text is Inter (v1: DM Sans), like the rest of v2, sized to v2's
  scale: county names and section title 16 (v1 18), pills 11.5 with 0.3
  tracking (v1 12.45 / 0.62), status lines 0.3 tracking.
- SAVED's "SORT ⌄" label is left out: it did nothing in v1.
- SAVED's small caps use Inter (v1: a mono face v2 doesn't have).
- UNCLAIMED accordions with no places show the blurb once (v1 repeated "No
  places on file yet").
- v1 flipped the county Save button only after a reload; v2 flips it
  immediately.
- Offline board cache and queued wishlist writes (v1
  `offline_discover_repository.dart`) are deferred to the offline work.

**Known debt**

- `DiscoverDetailActions` is a plain class and the detail screens use
  `FutureBuilder`; move them onto the Explore providers. No widget tests for
  the detail screens.
- Ticking doesn't refresh SAVED's "N STILL TO SEE" until the next load
  (v1 parity).
- Map Home still loads through a plain loader.

## Journeys (13)

**Built in the foundation slice**

- Private `journeys` and `journey_points` schema for completed route history;
  owner-only reads/deletion and no direct authenticated writes until the
  entitlement-checked upload path exists.
- Pure recording states and validated route points in
  `features/journeys/domain`, with focused transition tests.

**Built in the local recorder slice**

- Separate Drift database for account-scoped recording sessions and ordered
  points; transactional pause/resume/finish and recovery after database reopen.
- Point writes reject paused sessions, old segments and out-of-order fixes.

**Built in the native capture slice**

- Opt-in location adapter with background-mode configuration and capture
  coordinator that writes fixes serially to the local Journey store.
- Restart recovery pauses an active session; Resume creates a new segment so
  missing points are never drawn as a straight route. Timestamps preserve
  milliseconds for closely spaced fixes.
- Recovery excludes the process-down interval from recorded time, using the
  last stored fix. Long gaps between accepted fixes also start new segments.
- Stop/Discard do not report success if native location teardown is still
  unconfirmed; a paused session remains available for retry.
- Android's location plugin reports `false` after a successful background-mode
  disable, so stop now waits for the call rather than treating that value as a
  failure. A timed-out stream cancellation is retried before native stop.
- Unexpected location-stream failure pauses the notifier-visible session, so
  the UI does not continue to claim it is recording.

**Built in the entitlement and sync slice**

- `pro_entitlement_periods` (admin-granted until billing), `my_pro_status()`
  and the `upload_journey` RPC (owner, Pro-at-start, timing and point checks;
  distance computed server-side; idempotent). SQL test in
  `supabase/tests/journey_upload.sql`.
- `JourneyRecorder` (start needs a live Pro check, recover after
  restart), `JourneyUploadQueue` (backoff, local copy deleted after
  upload), `JourneyHistoryList` (local waiting + cloud, delete). Local
  Journey database schema 2.
- Start/recovery recheck account ownership after asynchronous work. Deleting
  a pending Journey coordinates with in-flight upload and removes any cloud
  copy created during that race.

**Built in the UI slice**

- Full-screen recording map with place pins and floating controls; Journey
  list with previews; full-screen replay and key moments. Replay crossings
  use the same 500 m inside-boundary margin as detection and appear only at
  the confirming point. The recording map waits for its first fix rather
  than briefly opening over the default Kenya camera.

**Built in the Journey media follow-up**

- Match camera-roll photos to a recorded Trip by capture time. Nearby shots
  (within 60 seconds) are grouped as alternatives; users can choose a different
  shot, select matches, or add up to 24 suggestions at once. Thumbnail loading
  uses a stable skeleton rather than flashing an empty tile.
- Replay can show Trip photos and key moments, including a top-speed moment
  only when speed clears the minimum threshold and is not an isolated GPS spike.
- Trip sharing supports selecting/replacing media and deleting an uploaded
  photo from both private Storage and its `journey_media` row.
- Release version is set to `1.3.10+19`. Camera-roll permission, photo loading,
  account/session transitions and native sharing still need device verification.

**Built in the place handoff slice**

- Place Detail Get Route, Home map place pins and the Home promoted-place card
  offer Record as a Journey or Directions only when Journeys are enabled.
  The choice sheet opens over the shell navigation with Directions only as a
  visible primary action, including on smaller phones.
  County-only Route buttons still open directions without a place association.
  Recording starts and passes entitlement/location checks before external
  directions launch; a failed launch discards that new Journey where native
  teardown succeeds.
- The chosen place ID, name and optional coordinates persist in local schema 4
  and upload privately through `upload_journey_to_place`. Pending and synced
  history retain the destination, including after a place listing changes.
- Planned routes and travel itineraries are not implemented. A Journey remains
  the actual recorded route, and the user stops it explicitly.

**Pending**

- Validate native stop and locked-screen recording on devices, including
  process death, permission changes and account switches. Compare the county
  geometry with the Mapbox base map; live geofence no-fix callbacks can still
  announce early crossings.
- Profile multi-hour route rendering and place-pin loading; add export and
  update privacy/store copy before release.
- Decide and implement a server-enforced limited free Journey allowance.
- Admin dashboard screen for granting Pro periods (until billing, #12).
- Subcounty tracking follows Journeys in a later feature.

## Progress log

Newest first. One line per commit that moves a feature or changes tracking.

| Date | Commit | Rows | Change |
|---|---|---|---|
| 2026-10-04 | working tree | 13 | Journey media follow-up: cluster timestamp-matched camera-roll photos with alternatives and a capped bulk-add action; enrich replay/share surfaces with photo management and a filtered top-speed moment. Version set to 1.3.10+19. CI/device verification pending. |
| 2026-10-03 | working tree | 6 | County news sheet now displays live DeckWatch summary stats: total and previous-period comparison, leading categories and high/critical reports. Summary fetch has independent loading/error/retry states and county-switch transition coverage; Flutter/device verification pending. |
| 2026-10-03 | working tree | 6 | Match attached KauntiNews concept in v2: compact 30-day news summary, 48-hour corroborated alert banner, detailed external-source sheet and horizontal county place cards. Screen-transition test updated; Flutter/device verification pending. |
| 2026-10-03 | working tree | 6 | Add owner/admin dashboard control for county news visibility via `app_feature_flags`; app fails closed until the remote flag enables news. Apply migration before using the control. Flutter checks pending. |
| 2026-10-03 | working tree | 6 | Deckwatch county safety feed: real 14-day incident list/trend, original-source links, independent loading/retry, and exclusion of obvious headline/county mismatches; live endpoint and source data checked, upstream classification issue found and guarded. Flutter verification pending. |
| 2026-10-03 | working tree | 8 | Profile layout updated to the attached concept: identity/home county, live county progress, earned badge preview, membership, Trips and privacy shortcuts; retained location diagnostics and sign-out flows. Flutter/device visual verification pending. |
| 2026-10-03 | working tree | 5, 13 | Dev-only opt-in location diagnostics: local JSONL report, native battery samples, Detection/geofence events, Journey segment-gap events and share/copy controls. Device validation pending. |
| 2026-10-01 | codex/journey-place-handoff | 13 | Free monthly Trip allowance for non-Pro accounts, account-scoped usage state, Trip search/date filters and empty-state icons; serialize trial checks in the upload RPC and keep rejected recordings retryable. Version bumped to 1.3.2+11. |
| 2026-10-01 | codex/journey-place-handoff | 7, 13 | Merge-preparation pass: Trip naming and rename, route stats, county splits, map and card polish; corrected the Journey upload RPC signature while retaining paused time and county data. Architecture, strict analysis, custom lint and full Flutter tests passed; SQL deployment and device transition checks remain pending. |
| 2026-09-26 | codex/journey-place-handoff | 8 | Profile visual pass: pale-blue account band and v2 blue accents for profile actions; neutral information rows retained |
| 2026-09-26 | codex/journey-place-handoff | 8 | First-release Profile from Home avatar with account-bound identity, county badges, live Pro status, Journeys, permission settings, privacy summary, and sign-out. Flutter/device verification pending; published policy, support and deletion workflow pending |
| 2026-09-26 | codex/journey-place-handoff | 3 | Launcher icon is the splash mark (gradient + white Kenya) on iOS and Android, with an Android 8+ adaptive icon; Map tab icon is Kenya's outline instead of a house |
| 2026-09-26 | codex/journey-place-handoff | 7, 13 | Repaired Journey stream filtering and destination-era test signatures; cleaned up visible badge analyzer lints. Flutter analysis and device verification pending |
| 2026-09-26 | codex/journey-place-handoff | 13 | Fixed Android Journey stop: accept the plugin's disable response and retry pending stream cancellation before background-mode shutdown; device verification pending |
| 2026-09-26 | codex/journey-place-handoff | 13 | Route choice sheet moved above floating bottom navigation; Directions only is a full-width primary action with small-screen coverage |
| 2026-09-26 | codex/journey-place-handoff | 3, 7 | Badges tab titled Collection: slider of claimed + Tiers card (medals, expandable progress to the next), 'Badges' grid with tap hint; medal art mapped to the right tier; Ranks tab hidden behind `RANKS_ENABLED` |
| 2026-09-26 | codex/journey-place-handoff | 13 | Place Detail, Home pin and promoted-place Route choice; background Journey start before external directions, durable destination snapshot and private upload migration; device validation and migration deployment pending |
| 2026-09-26 | codex/badges | 7, 13 | Badge sheet: 'Your time in <county>' (visits, months, last visit, Journeys + km) replaces the place cards; Journeys record the counties they cross (`journey_counties`, `upload_journey` p_counties) |
| 2026-09-26 | codex/badges | 7 | Badge sheet: earned date, next-depth progress, saved places / county coverage, share card (share_plus), how-to-earn + places for locked; `county_badge_detail` RPC |
| 2026-09-26 | codex/badges | 7 | Badges tab: tier pill, claimed hero, collection grid of star-less badges with depth rings; tap opens County Detail |
| 2026-10-04 | codex/map-home-unvisited-home-county | 4 | Map Home always colours the selected home county with the Home swatch, including while its badge is still locked |
| 2026-09-26 | codex/journeys-ui | 13 | Reliability pass: account-switch guards, recovery duration, pending delete/upload race, native stop retry state, stream-failure status, GPS-gap segments, replay crossing confirmation, and initial map camera; device verification pending |
| 2026-09-25 | codex/journeys-ui | 13 | Journeys tab behind `JOURNEYS_ENABLED`: start, live route and controls, history, detail with replay and delete |
| 2026-09-25 | codex/journeys-ui | 13 | Recording on a full-screen map with Home's place pins (tap for the place sheet), follow / re-centre, floating controls; Start opens it; place map pieces moved to core |
| 2026-09-25 | codex/journeys-ui | 13 | Live clock stands still while paused; recorded time (minus pauses) kept locally (schema 3) and uploaded (`journeys.paused_ms`, `upload_journey` p_paused_ms); Stop can discard |
| 2026-09-25 | codex/journeys-ui | 13 | Past Journeys as place-style cards over a Mapbox static-map route preview (thinned, encoded polyline) with Replay and delete |
| 2026-09-25 | codex/journeys-ui | 13 | Replay moments include every Kaunti47 place within 10 km of the route (saved ones marked), openable and savable from the card |
| 2026-09-25 | codex/journeys-ui | 13 | Journey detail page removed: a Journey opens straight into the full-screen replay (summary in the card); delete moved to the list |
| 2026-09-25 | codex/journeys-ui | 13 | Full-screen replay with floating controls; pauses at key moments (breaks, long stops, county crossings, saved places) |
| 2026-09-25 | codex/journeys-ui | 13 | Smooth replay: interpolated marker on a frame ticker, played line over a faded route, map layers split out |
| 2026-09-25 | codex/journeys-sync | 13 | Pro entitlement periods, `upload_journey` RPC, Pro-gated start, upload queue and private history |
| 2026-09-25 | codex/journeys-native-capture | 13 | Device location adapter, local capture coordinator, restart gap handling and millisecond fixes |
| 2026-09-25 | codex/journeys-recorder | 13 | Durable local Journey sessions and point queue with recovery and ownership tests |
| 2026-09-25 | codex/journeys-foundation | 13 | Private Journey schema, recording domain and phased implementation plan |
| 2026-09-25 | codex/go-router | 2, 3 | go_router: start-up redirects on `StartupFlow`, tab shell route, detail routes; sign-in on Riverpod; baseline 49 → 28 |
| 2026-09-24 | `8437820` | 3, 5, 6 | Merge #3: Explore tab, county detection (slices 1-7), arrival and map place sheets |
| 2026-09-24 | `40e4f22` | 5 | Detection: arrival sheet ("You've crossed into X"), once per crossing, never the home county |
| 2026-09-24 | `6115570` | 5 | Detection: pause and remove geofences when background location is lost; Home chip opens settings |
| 2026-09-24 | `0e8b6a3` | 5 | Detection: foreground cycle (`DetectionController`, `DetectionLifecycle`) |
| 2026-09-24 | `cfecd06` | 5 | Detection: native geofencing (`native_geofence`, rolling window, background callback) |
| 2026-09-24 | `999063e` | 5 | Detection: visit sync queue |
| 2026-09-24 | `9c19db3` | 5 | Detection: local visit store (drift `detection_queue`, schema 2) and repository |
| 2026-09-24 | `7894964` | 5 | Detection: visit rules and county polygon lookup |
| 2026-09-24 | `c481986` | 5 | Detection port plan |
| 2026-09-24 | uncommitted | 6 | Discover previews pin active promoted places to the second slot and label them AD |
| 2026-09-24 | uncommitted | 6 | Fix promoted-place edits to keep one active AD row per place |
| 2026-09-24 | uncommitted | 6 | Add promoted-place table and dashboard RPC for AD placements |
| 2026-09-24 | uncommitted | 4, 6 | Seed county profile facts for Area, Population, Governor, headquarters/capital and headquarters elevation |
| 2026-09-24 | `b92317a` | 6 | Explore UNCLAIMED and SAVED (Wishlist): county save, ticks, in-place refresh |
| 2026-09-24 | `0f2b6d4` | — | Generated Riverpod files (local build_runner) |
| 2026-09-24 | `b5c589c` | 1, 2, 3, 6 | Explore tab (MINE) on Riverpod; `ProviderScope` + Supabase client provider; `AppTabShell` |
| 2026-09-23 | `7c0bc06` | 6, 4 | County Detail + Place Detail ported; Map Home links to them |
| 2026-09-23 | `843f9a4` | — | dart format (local run) |
| 2026-09-23 | `63fd670` | 4 | County photos read separately from county facts |
| 2026-09-23 | `c8e922d` | 4 | Mapbox location telemetry off by default |
| 2026-09-23 | `3930ab9` | 4 | Merge `codex/mapbox-spike`: real (Mapbox) map is Home's default (`0dc58ab`), drawn map is the fallback |
| 2026-09-23 | `d8c9959` | — | Port tracker: log skeleton and docs commits |
| 2026-09-23 | `c421cdd` | 4 | Map-first loading skeleton replaces the loading message |
| 2026-09-23 | `d987c15` | — | Port tracker: Map Home notes, progress log, maintenance rule |
| 2026-09-23 | `64976a8` | 4 | Port v1 county map interactions (zoom, press label, halo, compact stat card, v1 colours) |
| 2026-09-23 | `71652b0` | 3, 4 | Supabase-backed board, v1 For You section, v1 sheet sizing, startup session restore |
| 2026-09-23 | `42b32ae` | — | AGENTS.md: project direction, no screen flashes, command discipline |
| 2026-09-23 | `03a3fe3` | 3, 4 | Map Home shell and floating bottom nav |
| 2026-09-23 | `489b83d` | 0 | Architecture guardrails, CI, review checklist |
| 2026-09-23 | `e7824d5` | — | Import v2 baseline (onboarding + auth) |
