# V1 → V2 port tracker

One row per feature. Source: `kokodavid/kaunti47`, branch `redesign/figma-v2`
(about 40k lines). Update this file in the same commit/PR that moves a feature: the table row,
the feature's section below (if it has one) and the progress log.

Status: `Not started` · `In progress` · `In review` · `Done`

| # | Feature | V1 location | V2 status | PR | Notes |
|---|---|---|---|---|---|
| 0 | Guardrails (rules, CI, review) | n/a | Done | #1 (main) | Riverpod deps, strict analysis, architecture guard + baseline, CI, Claude review, docs |
| 1 | Foundations re-homed to `core/` (config, design, widgets, counties, services) | `lib/src/{config,design,widgets,counties,services}` | Not started | | Move plus a Supabase client provider. Clears most `layout` baseline entries |
| 2 | Auth + onboarding on Riverpod + go_router | `lib/src/features/auth`, `lib/src/screens/onboarding` | Not started | | Split `app.dart` (414 lines, 16 setState calls) into router redirects and notifiers. V2 currently lacks v1's 3 how-it-works intro screens |
| 3 | App shell / bottom nav | v1 `AppShell` | In progress | codex/home-migration | Floating bottom nav on Map Home; other tabs show "coming next". Shell/router waits on #2 |
| 4 | Map Home (+ variants 1a–1e) | `features/map_home` | In progress | codex/home-migration | Board, sheet, For You, peek, v1 map interactions, Supabase data ported. See [Map Home](#map-home-4) below |
| 5 | Detection (geofence, visit state machine, offline drift queue) | `features/detection`, `features/offline` | Not started | | Needs a real-device test |
| 6 | Discover + Wishlist, County/Place Detail | `features/discover` | In progress | codex/discover-details | County Detail + Place Detail ported (save to wishlist, Get Route). Discover tabs + Wishlist not started. See [Discover](#discover-6) |
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
  when not); blurb; Source / Established / Governor card; "Places to See"
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

**Known debt**

- `DiscoverDetailActions` is a plain class and screens use `FutureBuilder`;
  move to `@riverpod` providers with #2. No widget tests for the screens.
- Discover tabs (Mine / Unclaimed / Saved), Wishlist and county save not
  ported.

## Progress log

Newest first. One line per commit that moves a feature or changes tracking.

| Date | Commit | Rows | Change |
|---|---|---|---|
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

