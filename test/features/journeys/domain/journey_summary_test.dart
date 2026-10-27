import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/journeys/domain/journey_summary.dart';

JourneySummary _trip({Duration? moving, double? distance = 10000}) =>
    JourneySummary(
      id: 't1',
      title: 'Trip',
      startedAt: DateTime.utc(2026, 10, 20, 8),
      endedAt: DateTime.utc(2026, 10, 20, 10),
      isUploaded: true,
      distanceMeters: distance,
      pausedDuration: const Duration(minutes: 20),
      movingDuration: moving,
    );

void main() {
  group('average speed', () {
    test('uses moving time when the server has worked it out', () {
      // 10 km in 1 h of movement: 10 km/h, however long the stops were.
      final trip = _trip(moving: const Duration(hours: 1));
      expect(trip.averageSpeedMps, closeTo(10000 / 3600, 1e-9));
    });

    test('falls back to recorded time (minus pauses) before that', () {
      // 2 h elapsed, 20 min paused: 100 min of 10 km.
      final trip = _trip();
      expect(trip.averageSpeedMps, closeTo(10000 / 6000, 1e-9));
    });

    test('is null without a distance or without time', () {
      expect(_trip(distance: null).averageSpeedMps, isNull);
      expect(_trip(moving: Duration.zero).averageSpeedMps, isNull);
    });
  });
}
