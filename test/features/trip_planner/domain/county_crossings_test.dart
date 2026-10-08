import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/trip_planner/domain/county_crossings.dart';
import 'package:kaunti47_v2/src/features/trip_planner/domain/county_shape.dart';
import 'package:kaunti47_v2/src/features/trip_planner/domain/trip_route.dart';

CountyShape square(int code, double west, double east, {double? holeSize}) {
  const south = 0.0;
  const north = 1.0;
  return CountyShape(
    code: code,
    polygons: [
      CountyPolygon(
        outer: [
          TripRoutePoint(south, west),
          TripRoutePoint(south, east),
          TripRoutePoint(north, east),
          TripRoutePoint(north, west),
        ],
        holes: holeSize == null
            ? const []
            : [
                [
                  TripRoutePoint(0.5 - holeSize, (west + east) / 2 - holeSize),
                  TripRoutePoint(0.5 - holeSize, (west + east) / 2 + holeSize),
                  TripRoutePoint(0.5 + holeSize, (west + east) / 2 + holeSize),
                  TripRoutePoint(0.5 + holeSize, (west + east) / 2 - holeSize),
                ],
              ],
      ),
    ],
  );
}

void main() {
  final shapes = [square(1, 0, 1), square(2, 1, 2), square(3, 2, 3)];

  test('a point is inside the county that holds it', () {
    expect(shapes[0].contains(0.5, 0.5), isTrue);
    expect(shapes[0].contains(0.5, 1.5), isFalse);
    expect(shapes[0].contains(2, 0.5), isFalse);
  });

  test('a hole is not part of the county', () {
    final ring = square(1, 0, 1, holeSize: 0.1);
    expect(ring.contains(0.5, 0.5), isFalse);
    expect(ring.contains(0.1, 0.1), isTrue);
  });

  test('counties come back in the order the route enters them', () {
    final route = [
      const TripRoutePoint(0.5, 0.1),
      const TripRoutePoint(0.5, 1.5),
      const TripRoutePoint(0.5, 2.9),
    ];
    expect(CountyCrossings.along(route, shapes), [1, 2, 3]);
  });

  test('a long gap between two points does not skip a county', () {
    // ~222 km apart, with county 2 only in between.
    final route = [
      const TripRoutePoint(0.5, 0.2),
      const TripRoutePoint(0.5, 2.2),
    ];
    expect(CountyCrossings.along(route, shapes), [1, 2, 3]);
  });

  test('a county is listed once even if the route comes back', () {
    final route = [
      const TripRoutePoint(0.5, 0.5),
      const TripRoutePoint(0.5, 1.5),
      const TripRoutePoint(0.5, 0.5),
    ];
    expect(CountyCrossings.along(route, shapes), [1, 2]);
  });

  test('points outside every county are ignored', () {
    final route = [const TripRoutePoint(5, 5), const TripRoutePoint(0.5, 0.5)];
    expect(CountyCrossings.along(route, shapes), [1]);
  });
}
