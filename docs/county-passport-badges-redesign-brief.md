# County Passport and Badges Redesign Brief

**Audience:** Claude Design
**Product:** Kaunti47 mobile app
**Date:** 2026-10-19
**Status:** Design exploration; do not implement production behavior from this document yet

## 1. Purpose

Redesign the current Badges tab into a **County Passport**: a personal record of a traveller's progress across Kenya's 47 counties.

The current screen is primarily a grid of county badge icons. The new experience should make the user's journey clear:

```text
Discover a county -> Pass through -> Explore -> Deepen the visit -> Return and complete the passport
```

The redesign must preserve existing achievements. A user who already earned a county badge or pass-through must never be downgraded or asked to repeat the same achievement.

This brief locks the first progression model for design review. Explored uses the existing county-presence rule. Bronze, Silver, and Gold represent progressively deeper discovery through verified place visits, supported by return visits. Place verification must be implemented before those higher levels can be awarded live.

## 2. Product language

Use this language consistently in the design:

| Product concept | User-facing name |
| --- | --- |
| Feature / tab | County Passport |
| County achievement | County Stamp |
| Progress ladder | Stamp Level |
| One county's journey | County Passport Page |
| Criteria inside a level | Milestones |
| Guided set of actions | Trail |
| Temporary or optional goal | Challenge |

The five permanent levels are:

1. **Passed Through**
2. **Explored**
3. **Bronze**
4. **Silver**
5. **Gold**

Use **Not started**, **In progress**, and **Earned** for progress states. Avoid presenting the experience as a gallery of generic badges.

## 3. Design goals

The redesigned experience should:

- Make the user's progress across all 47 counties immediately understandable.
- Show the next meaningful action without exposing unnecessary complexity.
- Make each county feel like a living collection that can be revisited and deepened.
- Personalize recommendations using interests without changing eligibility standards.
- Explain exactly what counted toward a milestone.
- Preserve the progress of existing testers and early users.
- Leave room for new milestones, trails, challenges, and future levels.
- Avoid encouraging unsafe travel, unnecessary driving, or prolonged stays during incidents.
- Work with sparse counties that have few places or categories.

## 4. Current implementation to respect

These are real current behaviors, not proposed design assumptions:

- County detection resolves a visit as `passed_through` or `explored`.
- In production, the current explored threshold is two hours of county presence.
- A short boundary flap is ignored by the detection state machine.
- County visit events now include `stay_seconds` when available.
- Existing county states are read from `county_visits`.
- Existing depth ranks are computed from explored visits and distinct months:
  - `visitor`
  - `regular`: at least 3 explored visits across 3 months
  - `local_expert`: at least 6 explored visits across 5 months
- Journey uploads store the counties crossed and approximate distance in each county.
- Journey route points are not currently place-visit evidence.
- Wishlist `ticked_at` is a useful personal signal but is not reliable proof that a user visited a place.
- Interests map to place types and currently personalize Explore recommendations and filters.
- The current Badges tab is titled `Collection` and shows a 47-county grid with county medallions and depth rings.

The existing depth ranks are not yet the new Passport levels. They are legacy evidence that can be used for a careful migration, but they must not be presented as if the new Bronze, Silver, and Gold rules already exist.

Relevant implementation references:

- `lib/src/features/badges/presentation/badges_screen.dart`
- `lib/src/features/badges/domain/badge_collection.dart`
- `lib/src/features/badges/domain/county_badge_detail.dart`
- `lib/src/features/detection/domain/visit_rules.dart`
- `lib/src/features/detection/domain/visit_models.dart`
- `docs/badges-port-plan.md`

The new design should not imply that verified place visits, Passport stages, or dashboard-controlled rules already exist.

## 5. County Passport landing page

The landing page should feel like opening a personal passport, while remaining practical and easy to scan.

### Header and summary

Show:

- `Your County Passport`
- A progress statement such as `8 of 47 counties stamped`
- A visual progress bar or segmented county progress indicator
- The user's highest currently earned level or a concise summary
- The next recommended county or next achievable stamp

Avoid making the page feel like a competitive leaderboard before social features are ready.

### Next stamp section

Show one useful next action:

```text
Your next stamp
Explore Kiambu
Meaningful visit complete
Discover 1 place to earn Explored
```

The recommendation may be based on distance, interests, saved places, and county availability. It must not change the actual eligibility rules.

### County collection

Show all 47 counties using the real county map badge / medallion, not a generic compass icon.

Each county card should show:

- County map shape
- County name
- Current stamp level
- Progress toward the next milestone
- A clear state: Not started, In progress, or Earned
- Optional visit count or last visited date

Useful filters:

- All counties
- Not started
- In progress
- Completed
- Highest level

Include county search. Do not make the user open every icon to understand their progress.

## 6. County Passport detail page

Selecting a county opens a detailed passport page.

Suggested structure:

1. County map stamp and county name
2. Current level and progress summary
3. Five-level progression rail
4. Current milestone checklist
5. Next recommended action or trail
6. Places discovered
7. Trips and visits
8. Original achievement date
9. County context, including Explore information and safety/news where available

The page should make the next step obvious without showing every future rule at full visual weight.

Example:

```text
Kiambu
Explored

Passed Through     Earned
Explored           Earned
Bronze             In progress

Bronze progress
2 of 3 places discovered
1 of 2 categories experienced

Next: discover one more verified place
```

## 7. Ship first versus later

### Ship first

- County Passport header and progress summary
- 47-county grid using real county map badges
- Filters and county search
- Passed Through and Explored from existing visit detection
- Bronze, Silver, and Gold screens and milestone states, using verified place visits and return visits once the place-verification capability ships
- Visible Explored time meter and after-visit result
- Five-level county progression rail
- Milestone checklist rendered from data
- Original achievement dates
- Legacy-user carry-over
- Neutral loading, offline, and account-restoration states

### Later implementation work

- Interest-based trails
- Contribution credit
- Dashboard editor and visual rule publishing
- Friends, ranks, and leaderboards

Verified place visits are part of the locked Bronze/Silver/Gold design, but they are a technical dependency and are not currently implemented.

Later features must not block the first release, and future-only UI should be clearly labelled or omitted from the first prototype.

## 8. Stage definitions

These are the locked product definitions for the design prototype. Thresholds are initial defaults and must remain configurable so they can be tuned using real usage data without changing the five-level language.

### Level 1: Passed Through

**Meaning:** The user entered and travelled through or briefly stayed in the county.

**Current evidence:** Automatic county detection and a valid visit outcome below the production explored threshold.

**Suggested visual sub-progress:**

- Brief Pass
- Linger
- Almost There

These are progress markers within Passed Through, not additional permanent levels.

### Level 2: Explored

**Meaning:** The user made a meaningful visit in the county.

**Compatibility rule:** Existing users who earned the current two-hour county badge are immediately recorded as Explored.

**First-release eligibility:** One continuous visit of at least two hours.

This is one definition for every user. Existing users retain an Explored stamp they already earned, and new users use the same two-hour rule. The visible action should be one sentence:

> A meaningful visit of two hours or more earns Explored.

Do not use copy that encourages a user to wait in a location just to earn a stamp. The meter may show progress on the county page or arrival sheet, but it should not issue movement alerts or suggest unsafe waiting.

If verified place visits later become an additional route into Explored, that route must become available to everyone from the day it ships. It must not create two permanent definitions for the same level.

### Level 3: Bronze

**Meaning:** The user has started discovering the county beyond one meaningful visit.

**Eligibility:**

- Explored is already earned.
- 3 verified place visits in the county.
- At least 2 distinct place categories where the county has enough places.
- At least 1 qualifying return visit after the Explored visit.

The user should see a simple quest such as `Discover 3 places across 2 categories` rather than a hidden score.

### Level 4: Silver

**Meaning:** The user has broad familiarity with the county.

**Eligibility:**

- Bronze is already earned.
- 6 verified place visits in the county.
- At least 3 distinct place categories where available.
- At least 2 separate qualifying visit days.

Separate visit days must be genuinely distinct; restarting a trip at the same location must not inflate progress.

### Level 5: Gold

**Meaning:** The user has deeply experienced and returned to the county.

**Eligibility:**

- Silver is already earned.
- 10 verified place visits in the county, or the configured share of available places if the county has fewer places.
- At least 4 distinct place categories where available.
- At least 3 separate qualifying visit days.

Gold is not granted automatically during migration. Contributions may add bonus progress later, but are not mandatory.

Contributions should be an optional route or bonus, not a mandatory requirement.

## 9. Progress and sparse-county fairness

Bronze, Silver, and Gold use a visible milestone checklist rather than an unexplained county-credit bar. The first locked defaults are:

```text
Bronze: 3 verified places, 2 categories, 1 return visit
Silver:  6 verified places, 3 categories, 2 visit days
Gold:    10 verified places, 4 categories, 3 visit days
```

These are initial defaults, not hard-coded permanent values. Render all numbers from data so thresholds can be tuned later.

For sparse counties, a place target must be capped by available reviewed places. A county with fewer than the default target must remain completable; the design should explain the adjusted target rather than showing an impossible checklist. Category targets must also be capped by the categories that actually exist in that county.

Time proves county presence. Verified place evidence proves discovery. Separate visit days prove return. No single long stay should complete all five levels.

The core fairness rule is:

> Interests personalize recommendations; they never change eligibility.

This keeps remote and sparse counties completable without requiring a particular attraction.

## 10. Evidence model

The experience should distinguish between evidence types:

| Evidence | What it can prove |
| --- | --- |
| County geofence and dwell | Presence in a county |
| County visit event | Passed Through or existing Explored outcome |
| Journey route samples | Movement through a county and trip context |
| GPS proximity plus dwell at a place | Verified place visit; technical dependency for Bronze+ |
| Completed trail | Future guided route that can help users discover qualifying places |
| Interest selection | Recommendation preference only |
| Saved or ticked place | Planning / personal signal, not visit proof |

The design should use language such as **verified place discovered** only when the backend has evidence. Do not award progress merely because a user tapped a place card or marked a place as saved.

## 11. Existing-user migration

The redesign must be additive.

```text
Existing passed_through  -> Passed Through
Existing explored badge  -> Explored
Legacy regular rank      -> Bronze, grandfathered
Legacy local expert rank -> Silver, grandfathered
Existing timestamps      -> Preserved
New Bronze/Silver/Gold   -> Verified-place criteria after capability ships
```

Existing achievements must not be recalculated under new rules or downgraded.

Use this conservative starting-point mapping:

| Existing evidence | Passport starting point |
| --- | --- |
| `passed_through` | Passed Through |
| Existing two-hour / `explored` badge | Explored |
| Legacy `regular` depth rank | Bronze as a grandfathered achievement |
| Legacy `local_expert` depth rank | Silver as a grandfathered achievement |

The legacy Bronze and Silver levels must be marked as grandfathered in the achievement ledger. They preserve what the old system proved; they do not manufacture historical place-visit evidence. New Bronze and Silver progress uses the new verified-place criteria. Missing historical `stay_seconds` must not be treated as proof of a two-hour visit.

Show the original achievement date where available. A one-time transition message may say:

> Your county achievements have been preserved in your County Passport. Your claimed counties are now recorded as Explored, with new levels available to earn.

Early testers may receive a separate `Founding Traveller` recognition marker, but it must not replace or alter their actual county achievements.

## 12. Dashboard-controlled progression

The long-term design should support dashboard-managed Passport configuration. The first release should already read rules from a server-side configuration source, even if the initial changes are made through migrations rather than a dashboard editor.

Dashboard admins may manage:

- Stage and milestone labels
- Thresholds and counts
- Enabled milestones
- Recommended trails
- Interest-based recommendations
- Explanatory copy
- Draft and published configuration versions
- Effective dates
- Rollback history

The app/backend must continue to own:

- County detection
- Dwell calculation
- GPS accuracy checks
- Place-radius verification
- Trip validation
- Supported evidence types

The dashboard may configure `verified_places >= 3` after place evidence exists, but it must not invent a new evidence type the app cannot measure. Until place verification is deployed, Bronze, Silver, and Gold must remain unavailable for new awards or clearly labelled as coming soon.

Rules must support:

- Draft versus published state
- Separate Dev and Production configurations
- Preview before publishing
- Audit history
- Rollback
- No retroactive downgrades
- Grace periods for meaningful rule changes

## 13. Extensibility

Keep the five main levels stable, but allow each level to contain configurable milestones.

```text
Bronze
├── Discover 3 places
├── Experience 2 categories
└── Return on 1 visit day
```

This leaves room to add milestones, county-specific trails, seasonal challenges, or a future Platinum level without changing the meaning of existing achievements.

Use these concepts consistently:

- **Levels:** permanent passport ladder
- **Milestones:** criteria inside a level
- **Trails:** guided routes to a milestone
- **Challenges:** optional or temporary goals

## 14. Design questions for the HTML prototype

Please include designs or states for:

1. Empty passport with no counties visited
2. A user with Passed Through progress
3. A legacy user with an existing Explored county
4. A county currently working toward Bronze
5. A fully completed Gold county
6. The 47-county passport grid
7. County detail with the five-level progression
8. A milestone explanation showing what counted
9. A county with too few places for the default threshold
10. A personalized trail based on interests, clearly labelled Later
11. Offline or stale passport data
12. Loading and account-restoration states without showing the wrong user's progress
13. A future verified-place milestone, clearly labelled Later

## 15. Review checklist before implementation

The HTML design should be reviewed against these questions:

- Can a user understand their current level in less than a few seconds?
- Can they see the next action without reading a rules document?
- Does the design preserve the dignity of existing achievements?
- Is the distinction between Passed Through and Explored clear?
- Are county map badges used consistently?
- Does personalization change recommendations rather than fairness rules?
- Can sparse or remote counties still be completed fairly?
- Are verified achievements visually distinct from saved or suggested places?
- Does the design avoid unsafe incentives?
- Does it leave room for more milestones without redesigning the whole screen?
- Does it support future friends and leaderboards without making the passport feel competitive today?

## 16. Non-goals for this design pass

Do not design or assume:

- A new leaderboard system
- Friends or social comparison screens
- Arbitrary admin-authored detection formulas
- A requirement to visit one fixed attraction in every county
- Retroactive recalculation that can remove a user's achievement
- Safety/news activity as a requirement for earning a stamp

The immediate goal is a clear, trustworthy, extensible County Passport experience that can be validated visually before database and application implementation begins.
