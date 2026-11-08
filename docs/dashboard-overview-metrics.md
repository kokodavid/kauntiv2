# Dashboard overview metrics

Migration `20261109100000_dashboard_overview_metrics.sql` adds two owner/admin
RPCs used by the dashboard Overview and Leaderboard analysis pages, plus a
people-by-state list:

- `dashboard_overview_metrics(p_start, p_end)`
- `dashboard_leaderboard_analysis(p_start, p_end)`
- `dashboard_people_in_state(p_state)`

Helpers (`dashboard_metric_*`) are not callable by clients.

## Production Deployment Checks

Apply `20261108100000_leaderboard_min_counties.sql`, then
`20261109100000_dashboard_overview_metrics.sql`. The second migration recreates
its temporary working tables per call rather than reusing caller-owned tables
inside a security-definer RPC. No mobile release, Edge Function or new secret
is required. The legacy growth RPC remains available.

`supabase/tests/dashboard_overview_metrics_smoke.sql` checks owner responses,
leaderboard totals, multiple calls/date ranges, authorization and private helper
permissions in a rolled-back transaction. It also pre-creates incompatible
caller temporary tables to verify safe replacement.

Only production is in scope for this rollout; development is unchanged.

## Definitions (agreed 8 Nov 2026)

- **Real Trip:** at least 1 km and 5 minutes of moving time (`moving_seconds`,
  or the Trip's duration when moving time is missing). Shorter finished Trips
  are short recordings.
- **Travelling:** a county entry or a finished real Trip in the 30 days ending
  at the period end. This is the North Star.
- **Meaningful action:** travel, or planning (trip plan created or edited,
  stop or idea added, saved trip, saved place), or contributing (place photo,
  check-in, public trip submitted). Opening the app does not count.
- **States, right now, in this order:** Travelling, Planning only (a
  meaningful action in 30 days without travel), New (signed up in the last 14
  days), Never started (never travelled), At risk (last action 31 to 60 days
  ago), Dormant (61 to 120), Gone (over 120).
- **New county:** the first time a person reached a county (non-seed county
  events plus legacy county records).
- **Notable Trip:** a real Trip that crosses 3+ counties, unlocks a new county
  (first reached between 5 minutes before the start and 1 hour after the end),
  covers 100 km+, has 3 h+ moving time, beats the person's earlier longest
  real Trip, or was recorded from a trip plan.
- **Trip score:** 3 per new county, 1 per county crossed, 1 per full 100 km.
- **Came back:** people Travelling 30 to 60 days ago who travelled again in
  the last 30 days. Not comparable until there are 60 days of travel data.
- **Activation in 7 days:** of people who signed up in the period at least 7
  days ago, the share with travel within 7 days of signing up.
- **Pro conversion:** people at the free 3-Trip limit in a month of the period
  who then started a paid Pro period (admin grants are not conversions).
- **Streak:** consecutive months with a real Trip, counted back from this
  month or last month (Nairobi time).

Hidden dashboard accounts, automated test accounts and dev-seeded data are left
out everywhere. The team's own accounts count. Leaderboard names respect the
leaderboard opt-out; opted-out people still count in totals. Home-county groups
under 5 people return no count or name. The leaderboard table lists people with
4 or more counties.
