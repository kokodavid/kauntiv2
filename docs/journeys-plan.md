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
