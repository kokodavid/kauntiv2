# Journeys: implementation plan

Status: foundation and local persistence merged; native capture integration in
progress on `codex/journeys-native-capture`.

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
4. **Journey UI:** fifth bottom-nav destination, live status and Stop controls,
   history, and route rendering on Mapbox. The tab must show archived Journeys
   after expiry and gate only Start Journey.
5. **Release readiness:** update the in-app explanation, privacy policy,
   purpose strings, App Store privacy answers and Play Data safety/declaration.
   Test locked-screen recording on real iOS and Android devices, offline and
   low-power cases, process restarts, permission revocation, account changes,
   deletion and missing-point gaps. Prepare reviewer access and a demo video.

## Privacy boundary

Automatic detection continues to sync county-level visit data only. Precise
points are collected only during an explicit Journey, remain private to the
account, and can be deleted by the user. Local buffering is necessary for
offline recording; cloud sync is necessary for cross-device history. Define
retention and backup-deletion periods before release. No route is public or
shared by default. Current v1 privacy copy saying routes are never stored must
be updated before Journeys is enabled.
