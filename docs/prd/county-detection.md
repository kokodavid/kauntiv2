# PRD: Reliable automatic county detection

Architecture decision: [adr/0001-county-detection-reliability.md](../adr/0001-county-detection-reliability.md)

## Problem

Users expect counties to unlock on their own. Today a user can disable
detection, or arrive somewhere it cannot see, and get no sign anything is
wrong. Some testers ask whether they have to turn something on. Silent
failure erodes trust in the core promise.

## Goals

- A user who grants the right permission gets reliable automatic detection.
- A user who does not is told exactly what they will and will not get, and how
  to fix it.
- A claim announces itself on both platforms.
- The team can see detection health across real devices.

## Non-goals

Manual claiming, a wider geofence window, new badge rules, place detection.

## Users and the three tiers

| Tier | When | What the user gets |
|---|---|---|
| Live | Always granted, app alive | Crossings and claims with the app closed |
| Catch-up | While Using, or the background path was lost | Counties recorded when the app is opened; a claim needs a second open 2 h later |
| Off | Denied, or location switched off | Nothing, stated clearly |

## Requirements

1. The current tier is visible without hunting (Home chip, banners, an
   explanation screen).
2. The explanation screen gives platform-specific steps to reach Live.
3. The app detects a silent stop and says so on the next open.
4. At most one notification when detection has been reduced for over a day.
5. A claimed county produces a "claimed" moment on iOS and Android.
6. The Manual toggle is removed.
7. Detection health is queryable in production, without storing coordinates.

## Success metrics

Thresholds are set before the release gate runs, not after.

- Share of real crossings recorded, by platform and OEM.
- Median delay from arrival to claim.
- Share of users in Catch-up or Off who recover to Live.
- Battery cost per day on a budget Android and an iPhone.

## Release gate

A real-device matrix (Tecno, Infinix, Xiaomi, and an iPhone with the app
force-quit), each doing a border crossing with the app swiped away, measured
against the thresholds above.

## Risks

OEM battery managers, iOS behaviour after force-quit, unmeasured battery
drain, the Google Play background-location declaration, and App Review
sensitivity around location permission prompts.
