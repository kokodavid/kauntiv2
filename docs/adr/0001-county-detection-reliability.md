# 0001. County detection reliability architecture

Status: Accepted (2026-11-27). Thresholds marked *TBC* are set from field
data before the release gate.
Product requirements: [prd/county-detection.md](../prd/county-detection.md)

## Context

County detection is the product's core promise: cross into a county and stay
about two hours, and it is claimed without the user doing anything. Today it
rests on OS geofences (the current county plus its neighbours, capped by iOS's
20 monitored regions), a foreground cycle (every 15 s, with a GPS read every
2 min while the app is open), Trip fixes, and an opt-in low-power stream
("Accurate county times").

Field evidence shows the engine is correct but the system around it can fail
silently or credit the wrong thing:

- A user who revokes "Always" location gets no detection at all.
  `DetectionController.runCycle()` removes every geofence and returns before
  reading a fix, so opening the app cannot recover the case either.
- Nothing notices when detection has stopped: permission loss, Android Force
  Stop, OEM task killers, or arriving outside the geofence window (for
  example by air).
- iOS has no native dwell event, so a claim lands only at exit or the next
  open of the app. Testers read this as a late or missing claim.
- Geofences are circles, so near a border they overlap the neighbouring
  county and can suggest the wrong one.
- Flights and other fast travel can pass over counties the user never
  visited.
- Users do not know which permission to grant or what each one gives them,
  and worry about battery.
- Settings offers an Automatic / Manual toggle that has no effect, and
  onboarding writes `location_mode = 'manual'` when location is skipped.

Funnel data (prod, 27 Nov 2026): every account sets a home county, 60% ever
enter a county, 17% record a real Trip, and 88% of real Trips have breaks.

## Decision

1. **Three-tier contract.** The app always knows which tier a user is in and
   tells them in plain words: *live* (Always granted, app alive), *catch-up on
   open* (While Using, or the background path was lost) and *off*.
2. **One reconciler.** Every signal (geofence callback, foreground fix, Trip
   fixes, the opt-in stream) keeps feeding `reconcileCurrentLocation` and
   `VisitRules`. No new detection path is added.
3. **Heartbeat.** Every signal writes a "last signal at" timestamp to the
   existing local database. On open, the gap since that time decides the
   status.
4. **`runCycle()` continues without background permission.** Geofences are
   removed (they cannot fire without it) but the foreground fix, reconcile,
   dwell check and sync still run.
5. **One status model** (healthy, reduced, off, stale) drives every surface:
   the Home chip, banners on Badges and Explore, an explanation screen and at
   most one notification.
6. **Conservative catch-up.** After a silence a stay starts at the first fix,
   not at an assumed earlier arrival. Under-credit rather than over-credit.
7. **Fast travel is a catch-up case.** When the speed implied between two
   fixes is above road speed (*TBC*, about 200 km/h) the segment is marked
   in transit. Counties crossed in transit get no credit, not even "passed
   through". The first good fix after transit starts a normal visit and its
   dwell clock. The geofence window is not widened. Road trips keep
   recording passed-through counties.
8. **iOS claim moment.** Schedule a local notification at enter + 2 h and
   cancel it on exit, so an iPhone user who stays in a county is told it was
   claimed. Android keeps the OS dwell event (`loiteringDelay`).
9. **Remove the Manual location mode** and stop onboarding writing it.
10. **Record detection health in production builds**, not only dev, without
    storing coordinates.
11. **Confidence gate.** A geofence event means "check here", never "credit
    here". A county is credited only from a fix that is inside the county
    polygon and has horizontal accuracy at or better than *TBC* (about
    100 m). Within *TBC* metres of a border, two consecutive fixes in the
    same county are required. The existing flap guard stays on top.
12. **Two-step permission ask.** Ask for While Using first. Ask for Always
    after the first value moment (first recorded county, or end of
    onboarding), with one screen that explains the three tiers, what each
    gives and the battery cost. Platform-specific steps to reach Always are
    one tap from the Home status chip.
13. **GPS budget.** App closed: geofences only, plus one accurate fix when a
    geofence fires, to confirm. App open: one fix on open or resume, then
    GPS only while a visit is pending or a Trip is recording. The fixed
    2-minute timer is removed. Trip recording and "Accurate county times"
    stay opt-in and say they use more battery.
14. **Pending visit is visible.** While a visit is pending, the app shows the
    county and the time left to claim ("Kisumu: claims in 1 h 20 m"), so a
    claim that arrives 2 hours later is expected, not late.

## Consequences

- Users without "Always" get a degraded but working product instead of
  silence, and know what they are missing.
- Every silent failure becomes visible, at the cost of one extra local write
  per signal.
- Wrong-county and flight credits drop, at the cost of occasionally missing a
  short or border-hugging visit. Under-credit is the accepted trade.
- Background battery use falls to OS geofences plus a confirming fix per
  event, which gives an honest line for the permission copy once measured.
- Catch-up claims arrive later than live ones, and the copy must say so.
- The reliability claim is gated on a real-device matrix, not on code alone.
- The work ships on its own branch for a later release, separate from any
  store submission in flight.

## Alternatives considered

- **Widen the geofence window.** Spends iOS's 20-region budget on a rare case.
- **Make Manual mode real.** Builds a feature to justify a toggle nobody asked
  for.
- **Keep the 2-minute GPS read unchanged.** Costs battery while the app is
  open without improving claims; replaced by the budget in decision 13.
- **Continuous background GPS for accuracy.** Would fix some border and
  timing cases but drains battery and makes the "Always" ask harder to
  justify.
- **Credit counties under a flight path as passed through.** Rejected: users
  did not visit them, and it inflates progress.
