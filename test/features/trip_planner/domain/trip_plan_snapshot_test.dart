import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/core/domain/map_place.dart';
import 'package:kaunti47_v2/src/features/trip_planner/domain/trip_plan.dart';
import 'package:kaunti47_v2/src/features/trip_planner/domain/trip_plan_snapshot.dart';
import 'package:kaunti47_v2/src/features/trip_planner/domain/trip_route.dart';

TripPlan _plan({int stops = 0}) => TripPlan(
  route: const TripRoute(
    points: [TripRoutePoint(0, 36), TripRoutePoint(1, 37)],
    distanceMeters: 279000,
    durationSeconds: 8 * 3600 + 22 * 60,
  ),
  countyCodes: const [1, 2],
  stops: [
    for (var i = 0; i < stops; i++)
      MapPlace(
        id: 'p$i',
        name: 'Stop $i',
        type: 'park',
        countyCode: 1,
        lat: 0.5,
        lng: 36.5,
      ),
  ],
);

void main() {
  group('TripPlanSnapshot.barSummary', () {
    test('a direct trip is just distance and time', () {
      expect(
        TripPlanSnapshot(status: TripPlanStatus.ready, plan: _plan()).barSummary,
        '279 km · 8 h 22 min',
      );
    });

    test('stops come first', () {
      expect(
        TripPlanSnapshot(
          status: TripPlanStatus.ready,
          plan: _plan(stops: 2),
        ).barSummary,
        '2 stops · 279 km · 8 h 22 min',
      );
    });

    test('one stop is singular', () {
      expect(
        TripPlanSnapshot(
          status: TripPlanStatus.ready,
          plan: _plan(stops: 1),
        ).barSummary,
        startsWith('1 stop · '),
      );
    });

    test('without location it asks for it', () {
      expect(
        const TripPlanSnapshot(status: TripPlanStatus.noLocation).barSummary,
        'Turn on location to see the distance',
      );
    });

    test('without a road it says how far the place is', () {
      expect(
        const TripPlanSnapshot(
          status: TripPlanStatus.noRoute,
          straightMeters: 41200,
        ).barSummary,
        'Road not loaded · about 41 km away',
      );
      expect(
        const TripPlanSnapshot(status: TripPlanStatus.noRoute).barSummary,
        'Road not loaded',
      );
    });
  });
}
