# 0001. County detection reliability architecture

Status: Proposed (2026-11-26)
Product requirements: [prd/county-detection.md](../prd/county-detection.md)

## Context

County detection is the product's core promise: cross into a county and stay
about two hours, and it is claimed without the user doing anything. Today it
rests on OS geofences (the current county plus its neighbours, capped by iOS's
20 monitored regions), a foreground cycle (every 15 s, with a GPS read every
2 min while the app is open), Trip fixes, and an opt-in low-power stream
("Accurate county times").

Field evidence shows the engine is correct but the system around it can fail
silently:

- A user who revokes "Always" location gets no detection at all.
  `DetectionController.runCycle()` removes every geofence and returns before
  reading a fix, so opening the app cannot recover the case either.
- Nothing notices when detection has stopped: permission loss, Android Force
  Stop, OEM task killers, or arriving outside the geofence window (for
  example by air).
- iOS has no native dwell event, so a claim lands only at exit or the next
  open of the app.
- Settings offers an Automatic / Manual toggle that has no effect, and
  onboarding writes `location_mode = 'manual'` when location is skipped.
- Nothing tells the user what is happening or what to do about it.

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
7. **Flights and large jumps are a catch-up case.** The foreground reconcile
   handles them; the geofence window is not widened. *(Proposed)*
8. **iOS claim moment.** Schedule a local notification at enter + 2 h and
   cancel it on exit, so an iPhone user who stays in a county is told it was
   claimed. *(Proposed)*
9. **Remove the Manual location mode** and stop onboarding writing it.
10. **Record detection health in production builds**, not only dev.

## Consequences

- Users without "Always" get a degraded but working product instead of
  silence.
- Every silent failure becomes visible, at the cost of one extra local write
  per signal.
- Catch-up claims arrive later than live ones, and the copy must say so.
- The reliability claim is gated on a real-device matrix, not on code alone.
- The work ships on its own branch for a later release, separate from any
  store submission in flight.

## Alternatives considered

- **Widen the geofence window.** Spends iOS's 20-region budget on a rare case.
- **Make Manual mode real.** Builds a feature to justify a toggle nobody asked
  for.
- **Keep the 2-minute GPS read unchanged.** Its value was never measured;
  revisit with real battery data (see the PRD).
