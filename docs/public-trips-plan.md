# Public Trips: Product, Privacy and Phased Build Plan

Status: Phase 1 PR 1 (backend) complete and applied to the dev Supabase
project on 2026-10-04; flags off. Not applied to prod. Written
2026-10-04; product decisions revised the same day (section 2).
Supersedes the exploratory public-trips brief.
Architecture authority: [architecture.md](architecture.md). Progress: [port-tracker.md](port-tracker.md).

## 1. Outcome and rollout promise

Turn a completed private Journey into an explicitly approved, separate public
route that helps another person explore Kenya. Public means visible to
signed-in Kaunti47 users; anonymous web links are a later decision.
Watching or following a public trip never grants badges. Existing detection and
dwell rules remain authoritative, and Journey recording still requires an
explicit Start action.

The first build targets a controlled tester MVP that can be attempted today.
This is a scope target, not a claim that implementation, security verification,
device testing or store distribution can be completed in one day. Release only
after the gates below pass. If they do not, ship the disabled build internally
and continue verification; do not remove protections to meet the date.

This design reduces exposure; it cannot guarantee anonymity, route safety,
store approval, or recall of content someone has already copied.

## 2. Product decisions

Owner decisions recorded 2026-10-04. They replace the earlier proposed
defaults (pilot-only publishing, alias, no moments or photos, single card).

| Decision | MVP |
|---|---|
| Who can publish | Active Pro users (`public.has_pro_at(user, now())`), not suspended, while the publish flag is on. Every submission still needs moderator approval |
| Who can view | Any signed-in, non-suspended user while the read flag is on. Viewing and directions are free |
| Upload allowance | Unchanged: free accounts upload 3 trips a month, Pro is unlimited. Publishing doesn't use an upload slot, but only Pro accounts can publish |
| Eligible trips | Finished, uploaded, owner-controlled driving or walking trips; exclude cycling, unknown mode and active recordings |
| Identity | The owner's public profile: display name, username and avatar (`quest_public_profiles.display_name`, `handle`, `avatar_url`). No email, auth ID or profile link. An opaque author ID supports blocking |
| Visible content | Sanitized route, reviewed title, travel mode, trip date, public-route distance and counties, owner-chosen moments and owner-chosen photos (sanitized) |
| Moments | Owner picks per trip, starting from saved share defaults: county crossings and highest point on; long stops, recording breaks, top speed and photos off. A "Save as my default" option on the review screen; full defaults in settings |
| Timing | Calendar date only. No time of day, stop durations, recorded duration or real timestamps; replay uses synthetic timing with moment offsets rebased onto it. Speed appears only if the owner publishes the top-speed moment |
| Publishing | Owner submits the exact sanitized preview (route, moments, photos); a moderator approves that revision before it becomes visible |
| Editing | Any change creates a new revision that goes through approval; the approved version stays live, unchanged, until the new one is approved |
| Maps | Directions to a moderator-approved public starting point only; route-following handoff later |
| Discovery | Horizontal row of trip cards in the Home sheet's side-quest slot; hidden when there's no eligible content |
| Revocation | Owner can withdraw immediately; moderators can hide or suspend publishing |

Including photos moves image sanitization and photo moderation, previously
Phase 2, into the MVP. It is the largest single addition to Phase 1.

Display name and avatar are read live from the profile, so a later rename is
not re-reviewed with the trip. They are already shown to other users
elsewhere and covered by existing user moderation (`user_moderation_status`);
revisit if that proves insufficient.

## 3. MVP user experience

1. A Pro owner opens the existing Share trip sheet and chooses Submit public
   trip. Free accounts see the entry point with a Pro upsell; the server denies
   non-Pro requests regardless. Unsynced trips explain that upload must finish
   first.
2. The server prepares a sanitized candidate. While it loads, show a stable
   map-shaped skeleton. Never briefly display the full private route here.
3. The owner reviews the actual public route and stats, picks which moments
   and photos to include (pre-filled from their share defaults, with "Save as
   my default"), sets the title, accepts the current publishing terms and
   confirms. Moments and photos inside hidden areas show as unavailable.
   Explain that other people may copy what is published. Hidden geometry is not
   returned by this endpoint; do not draw lines connecting removed parts.
4. The trip shows Awaiting review, then Public or Needs changes. The owner can
   withdraw while pending or public. Editing a public trip prepares a new
   revision; the approved one stays live until the new one is approved. A
   failed request is retryable without creating another copy. No optimistic
   Public label before confirmation.
5. A moderator reviews the same candidate (route, title, moments and photos)
   and approves or rejects it. A revision changed since review cannot be
   approved with a stale version token.
6. A viewer sees a horizontal row of eligible trips on the Home sheet, opens a
   read-only replay with the published moments, photos, author name and avatar
   and trip date, optionally opens directions to the approved public starting
   point, reports it, or blocks its author. Playback never starts location
   tracking or a private recording.
7. An unavailable, blocked or withdrawn trip shows a neutral unavailable state.
   Returning from background revalidates access before restoring the route.

Reuse v2 blue tokens, type scale, shimmer, buttons and confirmation sheets.
Keep public and owner actions distinct in their view models. No public viewer
gets add-photo, private-source, edit or owner-delete controls.

## 4. Privacy transformation and acceptance rules

The trusted backend reads the owner's stored points and creates the public
candidate. Never accept a client-supplied public polyline as authoritative.
Version the transformation so older publications can be reprocessed or hidden.

- Start with a server-enforced minimum 500 m endpoint exclusion radius and at
  least 500 m of recorded path removed from each end. This is an initial policy,
  not an anonymity guarantee; pilot review may require wider removal.
- Apply endpoint exclusion zones to the entire route, including return visits
  and loops near those endpoints. Treat existing recording gaps as separate
  segments. Reject suspicious discontinuities for manual review.
- Owners can increase hidden prefixes/suffixes. MVP rejects routes with an
  interior sensitive location that cannot be safely excluded; arbitrary private
  exclusion zones are Phase 2. Reviewers never assume endpoint trimming hides
  every residence, workplace, private road or sensitive stop.
- Compute distances in metres using suitable geospatial operations. Split
  geometry at exclusions; never bridge across them. Simplify each retained
  segment, then test every output edge against excluded zones again. A shortcut
  created by simplification must not cross a hidden zone.
- Fail closed if geometry is invalid, the retained route is too short, exclusions
  cannot be enforced, or the result exceeds limits. Return an actionable owner
  error without exposing any candidate to viewers.
- Derive route thumbnails, bounds, county coverage and distance from retained
  geometry only. Never reuse private thumbnails, private destination labels,
  GPS timestamps, original total distance, original duration or private point IDs.
- Send only coordinates required for the approved visible route. Public replay
  timing is synthetic and resets at its own beginning. Removing clock time from
  labels is insufficient if timestamps or private offsets remain in the payload.
- Moments: the client sends validated source point and media references, never
  positions. The server derives each moment's position, drops any outside
  retained segments, and stores the result with the revision. Viewers never
  recompute moments. Visible offsets are rebased onto the synthetic timeline.
- Date: publish only the calendar date of the trip start (Africa/Nairobi), never
  a time or timestamp.
- Photos: published only as sanitized copies (section 4a). Original
  `journey-media` paths or URLs never appear in public responses.
- County coverage means route intersection, not an earned badge. Recommendations
  use these sanitized counties and the viewer's confirmed claims.
- Source Journey/account deletion revokes associated public revisions. A source
  geometry/media change invalidates pending candidates; published snapshots stay
  immutable unless deleted, moderated or explicitly replaced by the owner.

Proposed pilot limits: 50,000 input points (existing upload ceiling), 2,000 output
vertices across all segments, 1 km minimum retained length, three published trips
per publisher during the pilot, title 80 characters, up to 30 moments and 10
photos per revision. Reject output
over the vertex cap rather than increasing simplification until privacy fails.
Benchmark these limits; enforce them on the server, not just in the form.
Before choosing the sanitizer implementation, verify PostGIS availability and
metre-based geometry support in both databases. Prefer tested geospatial
operations; if unavailable, use a trusted worker with a proven geometry library
and keep candidate activation behind the same server validation boundary.

### 4a. Photo sanitization

Sanitize selected images in a trusted worker: decode, apply orientation, re-encode
to a supported format, remove EXIF/GPS/XMP/IPTC and original filenames, generate
new thumbnails, enforce byte/dimension limits, and moderate visible content.
EXIF removal does not conceal addresses, faces or number plates visible in pixels;
moderators review photos as part of the revision. Use a separate private bucket
and authorization-checked asset delivery. Supabase public buckets bypass
retrieval access controls; short-lived signed URLs also remain usable until
expiry, so prefer checked delivery for revocation-sensitive assets.
Source: [Supabase bucket access](https://supabase.com/docs/guides/storage/buckets/fundamentals).

A revision with photos becomes reviewable only after every selected photo is
sanitized. Worker completion checks publication generation; withdrawal cancels
outstanding work. Retry cleanup and inventory orphan objects. Deleting a source
photo revokes copies derived from it.

## 5. Data model and trusted API boundaries

Use additive migrations in v2; never change applied migration files. Public
publication does not alter private `journeys`, `journey_points` or media access.

| Proposed record | Responsibility and access |
|---|---|
| `public_trip_publications` | Private source/owner mapping, public opaque ID, active revision and revocation state; no viewer SELECT |
| `public_trip_revisions` | Sanitized segments, public stats, trip date, reviewed title, content hash, transformation version and moderation state |
| `public_trip_revision_moments` | Moments chosen for a revision: kind, server-derived position, synthetic offset and optional value (top speed); no source point IDs in viewer output |
| `public_trip_revision_photos` | Sanitized photo copies for a revision and their processing state; never the original `journey-media` object |
| `public_trip_consents` | Owner, terms version, candidate hash and consent time; owner/admin only |
| `public_trip_reports` | Viewer report and private moderation outcome; never expose reporter identity to the author |
| `public_trip_author_blocks` | Viewer-owned blocks, enforced for cards, detail and assets |
| `public_trip_moderation_events` | Append-only actor/action/revision audit; limited admin access |
| `public_trip_authors` | Opaque author ID per publishing user and publish suspension; publish eligibility itself comes from Pro (`has_pro_at`); clients cannot write it |
| `public_trip_share_preferences` | Owner-only share defaults; edits never republish or alter existing revisions |

Prefer a protected publication store and explicit read RPC projections. Do not
expose the source journey ID, auth user ID, moderation notes or private joins in
viewer responses. An opaque author ID supports blocking without revealing auth
identity. Grant only necessary access and test RLS and function grants directly.

| Proposed operation | Required behavior |
|---|---|
| `prepare_public_trip(journey_id, request_id, title, moments, photo_ids, start_trim_m, end_trim_m)` | Derive caller from auth, verify ownership, finished upload, Pro, flags and limits; persist owner-only candidate (route, moments, queued photos) and return sanitized preview plus revision/hash. Moments and photos in hidden areas are dropped and listed under `excluded` for the owner |
| `submit_public_trip(public_id, revision, hash, terms_version)` | Lock and validate candidate/source versions, consent and flags; idempotently move to pending review |
| `review_public_trip(public_id, revision, decision)` | Verify current admin role, publisher eligibility and exact content hash; approve exact revision or reject with owner-facing reason |
| `get_public_trip(public_id)` | Check enabled flag, viewer eligibility (signed in, not suspended), active approved revision, author eligibility and viewer blocks on every request; return sanitized projection only |
| `public_trips_for_you(county_code, cursor)` | Same read checks; rank sanitized unclaimed coverage within chosen county/nearby counties; return a bounded list of cards for the Home row |
| `get/set_public_trip_share_preferences` | Owner-only read and write of share defaults |
| `list_public_trip_photo_jobs`, `complete_public_trip_photo`, `fail_public_trip_photo` | Service role only: the sanitization worker's queue. Completion is refused for a stale generation, so a withdrawn trip never gets a late photo |
| `withdraw_public_trip(public_id, request_id)` | Owner-scoped, idempotent; revoke all revisions and invalidate pending work immediately; remains usable when discovery/publishing flags are off |
| Report/block/admin hide | Server-authorized, rate-limited; hide or block affects every read path and signed-in deep link |

Security-definer mutations use a fixed safe search path, schema-qualified
objects and explicit auth/role checks. Revoke default execution permissions and
grant narrowly. Service credentials never enter the Flutter app. A broad RLS
policy is not a substitute for authorization within a privileged function.
See [Supabase function guidance](https://supabase.com/docs/guides/database/functions).

Concurrency rules: one stable publication per source Journey; multiple immutable
revisions, at most one active pointer. Approval switches that pointer atomically.
Withdrawal increments a generation/version so late preparation, approval or asset
jobs cannot reactivate the trip. Request IDs are scoped to owner and payload;
repeated same requests return the same result, mismatched reuse is rejected.
For the MVP, completing the candidate can use one DB transaction; later asset
processing requires a staged job, not a pretend cross-storage transaction.
Initial server rate limits: five preparation requests per publisher per hour,
ten reports per viewer per day, and sixty detail requests per viewer per minute.
Apply additional infrastructure limits against bulk harvesting; authentication
does not prevent copying. Expire unsubmitted candidates after 24 hours. Limits
are pilot defaults and may be tuned from aggregate measurements.

## 6. Access, revocation and retention

- MVP public routes are online-only. No offline public-route download or persistent
  public geometry cache. Every detail open/resume rechecks server eligibility.
- Realtime invalidation plus a foreground access refresh at most every 30 seconds
  clears an open revoked trip. Fail closed when access cannot be revalidated;
  explain offline state rather than restoring a previously visible route.
- After withdrawal commits, new backend reads deny access. Already received
  bytes, screenshots and third-party copies cannot be recalled. Describe this
  explicitly in the owner consent and privacy policy.
- Delete public geometry/assets asynchronously after revocation, with a proposed
  24-hour operational cleanup target, retry queue and overdue alert. Preserve only
  minimal non-geographic audit metadata. Proposed report/audit retention is 90
  days; confirm support/legal obligations and actual backup expiry before launch.
- No route coordinates, source labels, image URLs, live viewer locations or request
  bodies in analytics, exception logs or moderation notifications. Record counts,
  error categories, opaque revision IDs and latency. Pilot metrics use aggregate
  views, submissions, approvals, reports and directions taps.

## 7. Moderation and travel suitability

Moderation is an MVP release dependency. Review title, route, moments and photos before
publication; check private access, restricted/sensitive locations and misleading
content. Review is not a guarantee that a road remains safe or accessible.
Photos are in the MVP, so photo sanitization and photo review are release
dependencies, not later work.

Before submission, accept publishing terms covering sharing rights, location
exposure and prohibited content. Provide report-trip, report-author, block-author
and a published support contact. Dashboard supports pending review, hide,
publisher suspension, report resolution and an audit trail. Verify actual
`admin_members` roles in implementation; moderators cannot grant themselves roles.
During the pilot the operator reviews reports daily and hides credible privacy
exposure urgently. Pause publishing if moderation cannot be staffed.

Both stores impose UGC safeguards; this plan incorporates their reporting,
blocking and moderation requirements, but does not promise approval.
Sources: [Apple 1.2](https://developer.apple.com/app-store/review/guidelines/#user-generated-content)
and [Google Play UGC](https://support.google.com/googleplay/android-developer/answer/9876937?hl=en).
Update privacy disclosures and review notes before distribution. Do not enable
unreviewed functionality remotely to evade store review.

Directions use a reviewed public access point, such as a park entrance, with
the matching travel mode. Validate that the point is outside every exclusion
zone and provides usable access to the retained route; omit the action if no
suitable point exists. Walking paths and flights must not become driving
suggestions. Actual county badges still require the normal visit/dwell criteria.

## 8. v2 architecture and reuse

Create `features/public_trips/{domain,data,application,presentation}`. Domain
owns sanitized trip/revision values and lifecycle rules; data owns RPC calls;
generated Riverpod application providers own submission, access and moderation
states; presentation renders those states. `app/router.dart` wires entry points.
Map Home consumes public-trips application/domain projections and navigates through
app wiring, without importing public-trips presentation or data.

Reuse Journey domain replay utilities only through an adapter containing public
data and synthetic playback timing. Extract genuinely shared replay controls/map
widgets to `core/` when needed, with feature-neutral inputs. Do not import Journey
presentation across features or pass a private repository into public replay.
Reuse the existing share sheet as an entry point, v2 styles and shimmer. Files
stay under 300 lines, baseline does not grow, and tests mirror feature layers.

## 9. Phases and concrete delivery order

### Phase 1: MVP

Scope is the product slice in sections 2-7. Build in these dependent PRs:

1. **Backend and security (in progress):** additive schema, flags, sanitizer,
   preview, consent, submit/withdraw/read operations, RLS/grants, lifecycle and
   SQL tests, updated to the section 2 decisions (see section 11 for the exact
   changes still needed in the in-progress migrations). Flags remain off.
2. **Photo sanitization worker:** the section 4a pipeline, its private bucket
   and checked delivery, and its failure tests.
3. **Dashboard moderation:** approve the exact revision including moments and
   photos, hide, publisher suspension, reports, blocks and flag controls, with
   server role validation. Use the existing dashboard project and its own PR;
   record migration dependencies explicitly.
4. **App vertical slice:** owner review screen with the moment and photo picker
   and share defaults (plus a defaults settings screen), submit/withdraw/edit,
   read-only public replay with moments, photos, author and date, report/block,
   the Home horizontal row and directions to an approved starting point.
5. **Rollout:** deploy additive backend and worker, dashboard, then a compatible
   dev app; verify environment and fixtures; enable flags in dev first.

All five are necessary before enabling the MVP. Deferred: interior exclusion
zones, route-following Maps handoff, duplicate-route scoring, anonymous URLs
and public social interactions. If time only covers PR 1, deliver that disabled
foundation and its test results; do not describe it as a usable MVP.

### Phase 2: Privacy controls, discovery and Maps itinerary

Add interior exclusion zones with conservative server minimums; preference
changes apply to future review screens, never silently to published content.

Improve ranking: unclaimed sanitized county coverage first, then coarse start
reachability; use chosen/home county as a fallback without requesting GPS.
Deduplicate routes, cap repeated authors, paginate and enforce rate limits.
Hide empty results; do not resurrect unrelated placeholder content after loading.

Offer a best-effort Google Maps itinerary through reviewed public stops. Keep
the origin implicit, use an appropriate mode, and explain that Google recalculates
the route. Arbitrarily sampled GPS points may be inaccessible or on the wrong
side of a road; review waypoint selection and preserve its order. Keep a separate
Directions to start action for unsupported/discontinuous routes.
Universal URLs allow up to three waypoints in mobile browsers and nine elsewhere,
with a 2,048-character limit; use a conservative fallback and test installed-app
and browser paths. [Google Maps URL limits](https://developers.google.com/maps/documentation/urls/get-started).

### Phase 3: Expansion based on evidence

Consider anonymous share links/web previews, saved public trips, larger discovery
surfaces and travel planning only after reviewing demand, moderation workload,
performance and cost. Offline public copies need a new revocation/retention
decision. Likes, comments, follows, live trips and in-app navigation remain out
of scope. Monetization must not obstruct withdrawal, reporting or blocking.

## 10. Release gates and rollback

Every gate is currently pending; documentation does not constitute verification.

| Gate | Required evidence before MVP enablement |
|---|---|
| Privacy geometry | Fixtures for loops, returning near home, multiple segments, short/all-hidden trips, GPS jumps and simplification edges; no retained edge enters excluded zones |
| Payload | Viewer JSON/thumbnail contains only approved fields; no source IDs, private stats, real timing or original media URLs |
| Authorization | Owner A, viewer B, blocked viewer, anonymous client, suspended publisher and non-admin tests against direct table access and RPCs |
| Lifecycle | Double submit, stale approval, withdrawal racing preparation/approval, source/account deletion, retry and replacement tests |
| UX and flashes | Intermediate-frame tests for pending auth/flags/revision, account changes, offline/error/retry and revoke during playback; physical Android/iOS visual checks |
| Moments | Moments inside hidden areas dropped; offsets synthetic; no source point IDs or real timestamps in the payload |
| Photos | Malformed-image, location-metadata, unauthorized-download, stale-worker and partial-failure tests; photo review in moderation |
| Moderation | Working report/block, contact, terms consent, staffed reviewer, exact-revision review and urgent hide exercise |
| Operations | Flag denial on backend, rate limits, cleanup monitoring, cost/latency checks at maximum route size, no sensitive logging |
| Delivery | Required format, codegen when changed, analysis, custom lint, architecture and tests pass in CI; verify dev/prod migrations and device build configuration |

Extend `app_feature_flags` through a new migration: its current CHECK allows
only `county_news`. Add separate read and submission controls with false defaults,
admin-only writes and server enforcement. A missing or disabled flag denies access.
Client flags alone are insufficient. Gate all route reads and asset delivery;
keep owner withdrawal and moderator controls available while disabled.

Enable only after checking another account cannot read private
Journey data and withdrawal blocks every public read path. Existing store builds
cannot gain the new UI from a DB flag; distribute a compatible app build first.
External testing or production availability depends on the usual store process.

Rollback trigger: any private-data exposure, authorization failure, broken
withdrawal/blocking, or unmanageable moderation queue. Disable reads/submissions,
hide affected publications, investigate with minimal audit IDs, and notify affected
users through the incident process if appropriate. Keep additive schema for older
clients; fix and revalidate before reenabling. An outage or revoked access must
never fall back to a private Journey or an old public snapshot.

## 11. Planning handoff

- Start implementation with Phase 1 PR 1; this document authorizes no deployment.
- Validate the proposed limits, publication eligibility and Pro gating
  during the pilot; record changes here before enabling a broader audience.
- `claude/security-plan.md` lives in the Claude project, not this repo. These
  privacy requirements are recorded here; reconcile them with that plan
  without weakening `docs/architecture.md`.
- In-progress migrations updated to the section 2 decisions on 2026-10-04
  (`20261004100000`-`20261004110000`, including the new `20261004106000`):
  Pro-based publishing with `public_trip_authors` for opaque IDs and
  suspension; author identity from `quest_public_profiles`; trip date;
  moments and photo tables with server-derived positions and values; share
  preferences; the photo worker queue and private `public-trip-media` bucket;
  a list for the Home row; statement-level `journey_points` triggers (50k-point
  upload overhead about 0.9 s to 70 ms). All four SQL test files pass against
  local PostGIS 16/3.4. Applied to dev 2026-10-04; prod pending.
- Follow-up (needs a new migration now that these are applied): one GPS jump
  within a recording segment rejects the whole trip. Decide whether to keep
  that or drop the bad point, then check the sanitizer against real dev trips.
- Keep phase status, implementation PRs, migration deployment and outstanding
  device checks in the port tracker. Do not label a phase done before its gates.
