# Badges port plan

Port of v1's Badges tab to v2, on the new design:
- Screen: Figma `491:1394` ("Badges").
- Badge: Figma `277:19839` — the badge **without the stars banner**. The
  basic badge doesn't carry depth; depth is the ring around it.

## Decisions (2026-09-26)

- **Ring = depth, in quarters**, from 12 o'clock clockwise: passed
  through 1/4, visited 1/2, regular 3/4, local expert full. Locked and
  pending: empty track. Depth comes from `county_depth_ranks()` (the only
  live depth source; `county_depth_progress` is stale — Explore and County
  Detail still read it, see below).
- **Colours:** blue badge = earned (explored); grey badge = everything
  else. Passed-through keeps its 1/4 ring; pending gets a small
  "PENDING" marker so it isn't mistaken for locked.
- **Left out for now** (no product rules / data model yet): "3 Months
  since reset", the "Nairobi reached depth 3 · 2d ago" activity card, the
  avatar, and "Saved data. 12:34". Candidates when decided: active
  leaderboard season start for "since reset"; depth changes computed from
  `county_visit_events` for the activity card.
- **Tier medals:** three tiers (`core/domain/county_tier.dart`): Msafiri
  at 10 counties, Mzururaji at 25, Mkenya Halisi at all 47, with the
  medal artwork in `assets/images/Tier 1-3.png`. The old 1-county tier is
  gone. The medal pill (`AppTierPill`) shows on the Badges header and the
  Home top bar only once a tier is earned; before that Home shows just
  the avatar. The Badges hero card says how many counties to the next
  medal ("3 more counties to Msafiri").

## Steps

1. **Badges tab (built):** `features/badges` — domain `BadgeCollection`
   (state + depth per county, claimed / left / % / tier), data
   `SupabaseBadgesRepository` (`county_visits` + `county_depth_ranks()`,
   depth failing soft), `@riverpod badgeCollection` (reloads on account
   change and visit sync), screen: header + tier pill, hero card
   (47-segment bar), "ALL 47 COUNTIES / Collection" grid of
   `CountyBadgeMedallion`s in depth rings. Tap → County Detail.
2. **Badge sheet (built):** tapping a badge opens a sheet instead of
   County Detail: the badge card (big badge in its depth ring, county,
   depth · N of 47), earned date, what the next depth needs ("2 more
   visits, in 2 different months, to become a local expert"), saved
   places visited and county places ticked, Share (earned: the card as a
   PNG via the share sheet, `share_plus`; no location or dates on it) and
   View county. Not yet earned: how to earn it (about 2 hours there;
   pending waits for sync) and places to start with. Data: new RPC
   `county_badge_detail(p_county_id)` (migration `20260926100000`).
   The two place cards (saved places visited / county places ticked)
   were replaced by **"Your time in <county>"**: explored visits and the
   months they span, last visit, and Journeys there ("2 Journeys · 38 km",
   shown only when there are any). Journeys per county: on upload the
   phone splits the route by county with the bundled boundaries
   (`JourneyCountySplit`, off the UI isolate) and `upload_journey` stores
   it in the private `journey_counties` table (migration
   `20260926120000`). Journeys uploaded earlier have no counties.
   "Places to start with" (not yet earned) now uses the shared place row
   — photo, summary, type, distance, save — nearest first from a one-shot
   foreground position (migration `20260926130000` adds photo, summary,
   coordinates and saved to the suggestions).
   **Coin spin:** an earned badge's coin spins (2 turns over 2.2 s about its
   vertical axis, easing out, slight lift) and lands on its front the
   first time the account opens that badge on this phone
   (`BadgeSpinHistory`, shared_preferences); tapping it spins it again;
   the back is Kenya's map with the county picked out in white and the Kaunti47 mark; locked badges don't spin;
   reduced motion is respected; Share waits until it lands.
   Next: the unlock celebration + share prompt, a collection share card,
   filter chips and regional goals.
3. **Pending overlay:** merge detection's local pending codes (v1 did)
   through detection's application layer.
4. **Offline:** show the last collection when offline with "Saved data.
   HH:MM" (needs the v2 offline cache decision).
5. **Since reset + activity card:** once the rules are written down.
6. **Depth consistency:** move `discover_mine_counties` /
   `for_you_candidates` / County Detail off `county_depth_progress` onto
   the same rules as `county_depth_ranks()`.

## Design notes

- Inter only ships 400/500/600 here: the hero's "20" (Inter Extra Light
  in Figma) and the badge's county name (Baloo 2 Bold) use the nearest
  available weights.
- The hero card's scattered dots aren't in the Figma export (no asset);
  left out.
- Badge disc colours are sampled from the Figma render and drawn in code
  (county silhouette from `CountyPaths`), so every county gets its own
  badge without 47 image assets.
