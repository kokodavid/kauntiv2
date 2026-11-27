# PRD: Reliable automatic county detection

Architecture decision: [adr/0001-county-detection-reliability.md](../adr/0001-county-detection-reliability.md)

## Problem

Users expect counties to unlock on their own. Today a user can disable
detection, or arrive somewhere it cannot see, and get no sign anything is
wrong. Testers ask whether they have to turn something on, read normal
2-hour claims as late, and do not know which location permission to grant
or what it costs in battery. Near borders and on flights the app can suggest
or credit counties the user never visited. Silent failure and wrong credit
both erode trust in the core promise.

## Goals

- A user understands which permission to grant, what each one gives and what
  it costs, before and after granting it.
- A user who grants "Always" gets reliable automatic detection.
- A user who does not is told exactly what they will and will not get, and how
  to fix it.
- Only counties the user actually visited are credited.
- A claim announces itself on both platforms, and a pending claim shows its
  countdown.
- Background battery use stays low and is measured.
- The team can see detection health across real devices.

## Non-goals

Manual claiming, a wider geofence window, new badge rules, place detection,
continuous background GPS.

## Users and the three tiers

| Tier | When | What the user gets |
|---|---|---|
| Live | Always granted, app alive | Crossings and claims with the app closed |
| Catch-up | While Using, or the background path was lost | Counties recorded when the app is opened; a claim needs a second open 2 h later |
| Off | Denied, or location switched off | Nothing, stated clearly |

## Requirements

1. The current tier is visible without hunting (Home chip, banners, an
   explanation screen).
2. The explanation screen describes the three tiers in plain words, including
   the battery cost, and gives platform-specific steps to reach Live.
3. Permission is asked in two steps: While Using first, Always after the
   first value moment.
4. The app detects a silent stop and says so on the next open.
5. At most one notification when detection has been reduced for over a day.
6. A claimed county produces a "claimed" moment on iOS and Android.
7. A pending visit shows the county and the time left to claim.
8. A county is credited only from an accurate fix inside its polygon; near a
   border, two consecutive fixes are required.
9. Fast travel (flights) credits nothing in transit; the destination starts
   a normal visit after the first good fix.
10. Background GPS follows the budget in the ADR (geofences plus one
    confirming fix per event); the fixed 2-minute foreground timer is removed.
11. The Manual toggle is removed.
12. Detection health is queryable in production, without storing coordinates.

## Thresholds to confirm

Set from field data before the release gate, not after.

| Threshold | Starting value | Used in |
|---|---|---|
| Minimum fix accuracy to credit | 100 m | Req. 8 |
| Border buffer needing two fixes | TBC | Req. 8 |
| Transit speed | 200 km/h | Req. 9 |
| Reduced-detection notice delay | 24 h | Req. 5 |

## Success metrics

- Share of real crossings recorded, by platform and OEM.
- Median delay from arrival to claim.
- Wrong-county credits per 100 visits (checked against Trip tracks).
- Counties credited under flight paths (target zero).
- Share of users in Catch-up or Off who recover to Live.
- Share of new users who grant Always within 7 days.
- Battery cost per day on a budget Android and an iPhone.

## Release gate

A real-device matrix (Tecno, Infinix, Xiaomi, and an iPhone with the app
force-quit), each doing a border crossing with the app swiped away, plus one
flight or fast-travel case, measured against the metrics and thresholds
above.

## Risks

OEM battery managers, iOS behaviour after force-quit, under-crediting short
border visits, unmeasured battery drain, the Google Play background-location
declaration, and App Review sensitivity around location permission prompts.
