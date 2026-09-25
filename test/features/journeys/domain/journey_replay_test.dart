import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/journeys/domain/journey_point.dart';
import 'package:kaunti47_v2/src/features/journeys/domain/journey_replay.dart';
import 'package:kaunti47_v2/src/features/journeys/domain/journey_route.dart';

JourneyPoint _p(int minute, double lat, int segment) => JourneyPoint(
  recordedAt: DateTime.utc(2026, 9, 25, 10, minute),
  latitude: lat,
  longitude: 36.82,
  accuracyMeters: 5,
  segmentNumber: segment,
);

void main() {
  final track = JourneyReplayTrack(
    JourneyRoute([
      _p(0, -1.30, 0),
      _p(5, -1.29, 0),
      // Pause: the jump to segment 1 adds no distance.
      _p(20, -1.00, 1),
      _p(25, -0.99, 1),
    ]),
  );

  test('elapsed time and distance so far at each point', () {
    expect(track.elapsedAt(0), Duration.zero);
    expect(track.elapsedAt(3), const Duration(minutes: 25));
    expect(track.distanceAt(0), 0);
    final first = track.distanceAt(1);
    expect(first, closeTo(1112, 5));
    expect(track.distanceAt(2), first);
    expect(track.distanceAt(3), closeTo(2 * first, 10));
  });

  test('1× lasts between 30 s and 2 min; speeds multiply', () {
    expect(track.baseDuration, const Duration(seconds: 30));
    final long = JourneyReplayTrack(
      JourneyRoute([for (var i = 0; i < 1000; i++) _p(0, -1 + i / 1e4, 0)]),
    );
    expect(long.baseDuration, const Duration(minutes: 2));
    expect(
      track.pointsPerSecond(JourneyReplaySpeed.x4),
      4 * track.pointsPerSecond(JourneyReplaySpeed.x1),
    );
  });

  test('the route so far grows from the start', () {
    expect(track.routeUpTo(0).pointCount, 1);
    expect(track.routeUpTo(3).pointCount, 4);
    expect(track.canReplay, isTrue);
  });

  test('fractional positions glide between points, not across a pause', () {
    final halfway = track.positionAt(0.5);
    expect(halfway.latitude, closeTo(-1.295, 1e-9));
    expect(track.elapsedAtPosition(0.5), const Duration(seconds: 150));
    expect(track.distanceAtPosition(0.5), closeTo(track.distanceAt(1) / 2, 1));
    // Between points 1 and 2 is a pause: the marker waits at point 1.
    expect(track.positionAt(1.5).latitude, -1.29);
    // Past the end stays at the end.
    expect(track.positionAt(99).latitude, -0.99);
  });
}

