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
- **Tier pill:** "Tier N" from counties claimed (1 / 10 / 25 / 47, docs
  01), hidden before the first badge.

## Steps

1. **Badges tab (built):** `features/badges` — domain `BadgeCollection`
   (state + depth per county, claimed / left / % / tier), data
   `SupabaseBadgesRepository` (`county_visits` + `county_depth_ranks()`,
   depth failing soft), `@riverpod badgeCollection` (reloads on account
   change and visit sync), screen: header + tier pill, hero card
   (47-segment bar), "ALL 47 COUNTIES / Collection" grid of
   `CountyBadgeMedallion`s in depth rings. Tap → County Detail.
2. **Badge detail sheet:** depth ladder for the county, what the next
   depth needs (visits / distinct months from `county_visit_events`), last
   visit — needs a small RPC.
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
