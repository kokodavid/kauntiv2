# V1 → V2 port tracker

One row per feature. Source: `kokodavid/kaunti47`, branch `redesign/figma-v2`
(about 40k lines). Update this file in every PR that moves a feature.

Status: `Not started` · `In progress` · `In review` · `Done`

| # | Feature | V1 location | V2 status | PR | Notes |
|---|---|---|---|---|---|
| 0 | Guardrails (rules, CI, review) | n/a | In review | setup/guardrails | Riverpod deps, strict analysis, architecture guard + baseline, CI, Claude review, docs |
| 1 | Foundations re-homed to `core/` (config, design, widgets, counties, services) | `lib/src/{config,design,widgets,counties,services}` | Not started | | Move plus a Supabase client provider. Clears most `layout` baseline entries |
| 2 | Auth + onboarding on Riverpod + go_router | `lib/src/features/auth`, `lib/src/screens/onboarding` | Not started | | Split `app.dart` (418 lines, 16 setState calls) into router redirects and notifiers. V2 currently lacks v1's 3 how-it-works intro screens |
| 3 | App shell / bottom nav | v1 `AppShell` | In progress | codex/home-migration | Floating bottom nav ported for Map Home; broader shell/router still pending |
| 4 | Map Home (+ variants 1a–1e) | `features/map_home` | In progress | codex/home-migration | Home map, sheet, county peek, v1-style For You section, and Supabase-backed visits/counties/recommendations are ported. Map interactions match v1 (press highlight + label, pinch-zoom 1x-4x with reset, small-county tap halo, compact stat card while browsing, v1 state colours); tap opens the peek until County Detail (#6) lands, then switches to v1's tap→detail. Empty/dimmed map modes and location pin wait on Detection (#5). Detection overlays, variants, quests, friends, and offline cache still pending |
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
