# V1 → V2 port tracker

One row per feature. Source: `kokodavid/kaunti47`, branch `redesign/figma-v2`
(about 40k lines). Update this file in the same commit/PR that moves a feature: the table row,
the feature's section below (if it has one) and the progress log.

Status: `Not started` · `In progress` · `In review` · `Done`

| # | Feature | V1 location | V2 status | PR | Notes |
|---|---|---|---|---|---|
| 0 | Guardrails (rules, CI, review) | n/a | In review | setup/guardrails | Riverpod deps, strict analysis, architecture guard + baseline, CI, Claude review, docs |
| 1 | Foundations re-homed to `core/` (config, design, widgets, counties, services) | `lib/src/{config,design,widgets,counties,services}` | Not started | | Move plus a Supabase client provider. Clears most `layout` baseline entries |
| 2 | Auth + onboarding on Riverpod + go_router | `lib/src/features/auth`, `lib/src/screens/onboarding` | Not started | | Split `app.dart` (414 lines, 16 setState calls) into router redirects and notifiers. V2 currently lacks v1's 3 how-it-works intro screens |
| 3 | App shell / bottom nav | v1 `AppShell` | In progress | codex/home-migration | Floating bottom nav on Map Home; other tabs show "coming next". Shell/router waits on #2 |
| 4 | Map Home (+ variants 1a–1e) | `features/map_home` | In progress | codex/home-migration | Board, sheet, For You, peek, v1 map interactions, Supabase data ported. See [Map Home](#map-home-4) below |
| 5 | Detection (geofence, visit state machine, offline drift queue) | `features/detection`, `features/offline` | Not started | | Needs a real-device test |
| 6 | Discover + Wishlist, County/Place Detail | `features/discover` | Not started | | v1 Supabase repository is 924 lines |
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

## Spikes (not for main)

### Mapbox Pro map — `codex/mapbox-spike`

Question: is a Mapbox "real map" worth offering as a Pro view, with the drawn
map kept for everyone?

- County outlines bundled as `assets/geo/kenya_counties.geojson` (from v1's
  geoBoundaries seed geometry, 47 features, ~170 KB); no database change.
- `ProMapView`: embedded in Home's map slot and swapped with the drawn map
  by a "MAP | REAL · PRO" switch (top-left of the map); top bar, stat card,
  For You sheet and nav stay put. Counties coloured by badge state over a
  Light / Terrain / Satellite base (style, 3D and locate-me buttons on the
  right), kept inside Kenya; Mapbox logo/attribution lifted above the sheet.
- Place pins from `places` (lat/lng): type-coloured dots when zoomed out;
  from zoom 6, rendered markers (round `place_images` thumbnail in a type
  ring with a pointer, or a type badge with icon), names underneath,
  collisions hidden with photos preferred. Tap opens a sheet with the photo.
- 3D terrain (Mapbox Terrain-DEM, 1.5x exaggeration, atmosphere sky), on by
  default with a 50° tilt; "3D" toggle flattens it and levels the camera.
- Opens on the user's surroundings: flies from Kenya to a pulsing "you are
  here" dot at zoom 8.5 (photo markers visible) when foreground location is
  allowed, else to the home county; zooming out gives the Kenya-wide dots.
  Locate-me button refocuses. Location is read by Mapbox, never stored.
- Tapping a county flies the camera into it (framed above the peek sheet,
  tilted when 3D is on); the sheet opens as the flight settles.
- The switch shows only when `MAPBOX_ACCESS_TOKEN` is set (stand-in for a
  Pro entitlement).
- To evaluate on a device: look, start-up time, tap accuracy, gesture
  conflicts with the sheet, app-size increase, offline behaviour.
- Open before any real build: telemetry opt-out (doc 05; matters more now
  the map reads location), attribution in
  Credits, Pro entitlement + paywall (#12), decision record.

## Progress log

Newest first. One line per commit that moves a feature or changes tracking.

| Date | Commit | Rows | Change |
|---|---|---|---|
| 2026-09-23 | `c421cdd` | 4 | Map-first loading skeleton replaces the loading message |
| 2026-09-23 | `d987c15` | — | Port tracker: Map Home notes, progress log, maintenance rule |
| 2026-09-23 | `64976a8` | 4 | Port v1 county map interactions (zoom, press label, halo, compact stat card, v1 colours) |
| 2026-09-23 | `71652b0` | 3, 4 | Supabase-backed board, v1 For You section, v1 sheet sizing, startup session restore |
| 2026-09-23 | `42b32ae` | — | AGENTS.md: project direction, no screen flashes, command discipline |
| 2026-09-23 | `03a3fe3` | 3, 4 | Map Home shell and floating bottom nav |
| 2026-09-23 | `489b83d` | 0 | Architecture guardrails, CI, review checklist |
| 2026-09-23 | `e7824d5` | — | Import v2 baseline (onboarding + auth) |

