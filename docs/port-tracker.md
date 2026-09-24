# V1 → V2 port tracker

One row per feature. Source: `kokodavid/kaunti47`, branch `redesign/figma-v2`
(about 40k lines). Update this file in the same commit/PR that moves a feature: the table row,
the feature's section below (if it has one) and the progress log.

Status: `Not started` · `In progress` · `In review` · `Done`

| # | Feature | V1 location | V2 status | PR | Notes |
|---|---|---|---|---|---|
| 0 | Guardrails (rules, CI, review) | n/a | Done | #1 (main) | Riverpod deps, strict analysis, architecture guard + baseline, CI, Claude review, docs |
| 1 | Foundations re-homed to `core/` (config, design, widgets, counties, services) | `lib/src/{config,design,widgets,counties,services}` | Not started | | Move to `core/`. Clears most `layout` baseline entries. `core/services/supabase_client_provider.dart` exists (Explore uses it) |
| 2 | Auth + onboarding on Riverpod + go_router | `lib/src/features/auth`, `lib/src/screens/onboarding` | Not started | | `ProviderScope` is wired at the root (`buildAppRoot`); auth/onboarding still setState. Split `app.dart` (414 lines, 16 setState calls) into router redirects and notifiers. V2 currently lacks v1's 3 how-it-works intro screens |
| 3 | App shell / bottom nav | v1 `AppShell` | In progress | codex/explore-tab | `AppTabShell`: IndexedStack tabs under the floating nav, lazy first build (v1 parity). Map + Explore live; Badges / Ranks show "coming next". go_router waits on #2 |
| 4 | Map Home (+ variants 1a–1e) | `features/map_home` | In progress | codex/home-migration | Board, sheet, For You, peek, v1 map interactions, Supabase data ported. See [Map Home](#map-home-4) below |
| 5 | Detection (geofence, visit state machine, offline drift queue) | `features/detection`, `features/offline` | Not started | | Plan: [detection-port-plan.md](detection-port-plan.md). Needs a real-device test |
| 6 | Discover + Wishlist, County/Place Detail | `features/discover` | In progress | codex/explore-tab | County + Place Detail ported. Explore tab (MINE, UNCLAIMED, SAVED/Wishlist) ported on Riverpod; offline cache deferred. See [Discover](#discover-6) |
| 7 | Badges + tiers | `features/badges` | Not started | | |
| 8 | Profile, Settings, Data & Privacy | `features/profile` | Not started | | v1 profile screen is 1,339 lines |
| 9 | Ranks, leaderboards, seasons | `features/ranks` | Not started | | |
| 10 | Quests / side quests + sharing | `features/quests` | Not started | | |
| 11 | Friends | `features/friends` | Not started | | |
| 12 | Pro / M-Pesa monetization | docs only in v1 | Not started | | |

## Baseline burn-down

| Date | Baselined violations | Note |
|---|---|---|
| 2026-09-23 | 49 | Guard introduced over the imported v2 onboarding code |

## Feature notes

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
  Explore's UNCLAIMED tab (`AppTabShell.select`, keep-alive tab provider).
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
  peek sheet), zoom-independent strokes, just-unlocked 3-letter label.
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
- Map Home still loads through a plain loader; `AppTabShell` keeps its
  selected tab in widget state until go_router (#2).

## Progress log

Newest first. One line per commit that moves a feature or changes tracking.

| Date | Commit | Rows | Change |
|---|---|---|---|
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
