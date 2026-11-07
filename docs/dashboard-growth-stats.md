# Dashboard growth statistics

## Deployment

Apply `20261107140000_dashboard_growth_stats.sql` before deploying the dashboard.
It adds `dashboard_growth_stats(p_start, p_end, p_leaderboard_period)` without
changing `dashboard_usage_stats()`. No mobile release, new telemetry, Edge
Function or secret is needed. Owner/admin access is checked server-side.
No user records are modified. A dashboard rollback can leave this additive RPC
installed. The migration must also be recorded in the migration ledger.

## Periods and definitions

- Reporting windows are start-inclusive, end-exclusive. Custom dates include the
  entire final day in Africa/Nairobi; future end times are capped at now.
- Rolling 7/30/90-day windows compare with the immediately preceding equal-length
  window. All time starts at the earliest eligible profile and has no comparison.
- Hidden dashboard and automated test accounts are excluded using the existing
  dashboard user classification. Open feedback is an operational current total.
- New signups are profiles created in the selected period. Activation means a
  confirmed county entry or finished trip by the period end. Home-county setup
  reflects the current profile value, not historical onboarding events.
- Observed activity includes journey starts, non-seed county events and device
  latest check-ins. Weekly/monthly activity uses the 7/30 days ending at the
  selected period end, independently of the selected window's length.
- Device records are not an activity history: previous-period activity can
  undercount. No general app-open retention or daily-active claims are made.
- Week-2/5 travel retention uses durable journeys/county events during days 7–13
  or 30–36 after signup. Only cohorts whose entire return window has elapsed by
  the reporting end enter the denominator. An immature/empty cohort displays a
  dash, not 0%. These are travel-activity retention, not exact-day D7/D30 retention.
- Invitation conversion cohorts use the first successfully sent invitation per
  waitlist signup. Registration must occur after invitation and before period
  end, matched by linked user ID or normalized email. Activation has the same
  county/finished-trip definition. Resends never inflate invitations. Existing
  accounts invited later are not new acquisition conversions.
- Release adoption compares the most recently observed device per user in the
  selected window against the current live production release for its platform.
  It is not a reconstruction of the release that was live on a historical date.
- Open feedback and current Pro membership are current snapshots. Free-trip
  usage remains the current UTC calendar month and is labelled accordingly.

## Leaderboard

Top 20 users, sorted by distinct counties descending, then explored counties
descending, then earliest coverage completion, then stable user ID. A county is
either explored or passed-through-only, never counted twice. Repeated visits do
not increase coverage. Confirmed legacy county records are included alongside
non-seed event evidence, excluding seeded-only legacy fallbacks. Visibility
opt-outs are respected, even in this staff-only panel.

Default coverage includes records through the selected period end. The optional
period leaderboard includes only counties first reached during that period,
not repeat visits. Legacy records cannot reconstruct every historical upgrade;
stored state is used where event history is unavailable. Original achievements
are not changed.

## Verification

`scripts/check-dashboard-growth-sql.mjs` runs isolated synthetic fixtures against
PGlite, supplied through `PGLITE_MODULE` or installed locally. Tests cover date
boundaries, unique counties, tie-breaks, hidden/opt-out/seed filtering, first
discovery, mature retention cohorts, empty and invalid ranges and role rejection.
Fixture SQL files are local-test schema setup, never live migrations.

Production preflight installs the RPC inside a transaction, executes representative
owner queries and access checks, and rolls back before the real deployment.
Flutter/Dart commands are not needed or run.
