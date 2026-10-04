import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/public_trips/domain/public_trip_owner_view.dart';
import 'package:kaunti47_v2/src/features/public_trips/domain/public_trip_track.dart';

void main() {
  final track = PublicTripTrack(const [
    [
      PublicTripPoint(0, 36),
      PublicTripPoint(0, 36.01),
      PublicTripPoint(0, 36.02),
    ],
    [PublicTripPoint(1, 37)], // a lone point is dropped
    [PublicTripPoint(0.1, 36.1), PublicTripPoint(0.1, 36.11)],
  ]);

  test('keeps only lines with two or more points', () {
    expect(track.lines, hasLength(2));
    expect(track.points, hasLength(5));
    expect(track.lastIndex, 4);
    expect(track.canReplay, isTrue);
  });

  test('a route with no usable line cannot replay', () {
    final empty = PublicTripTrack(const [
      [PublicTripPoint(0, 36)],
    ]);
    expect(empty.canReplay, isFalse);
    expect(empty.totalMeters, 0);
  });

  test('moves between points and waits across a break', () {
    expect(track.positionAt(0.5).longitude, closeTo(36.005, 1e-9));
    // Between points 2 and 3 is a break: it waits at point 2.
    expect(track.positionAt(2.5).longitude, 36.02);
    expect(track.positionAt(99).longitude, 36.11);
  });

  test('distance grows within lines only', () {
    final across = track.distanceAt(3) - track.distanceAt(2);
    expect(across, 0);
    expect(track.distanceAt(2), greaterThan(2000));
    expect(track.totalMeters, greaterThan(track.distanceAt(2)));
  });

  test('draws the route up to a point as separate lines', () {
    final upTo = track.linesUpTo(3);
    expect(upTo, hasLength(2));
    expect(upTo.first, hasLength(3));
    expect(upTo.last, hasLength(1));
    expect(track.linesUpTo(1).single, hasLength(2));
  });

  test('ties a place to the nearest route point', () {
    expect(track.nearestIndex(0.0001, 36.0101), 1);
    expect(track.nearestIndex(0.1, 36.11), 4);
  });

  test('replay lasts between 30 s and 2 min and speeds scale', () {
    expect(track.baseDuration, const Duration(seconds: 30));
    expect(
      track.pointsPerSecond(PublicTripSpeed.x4),
      closeTo(track.pointsPerSecond(PublicTripSpeed.x1) * 4, 1e-9),
    );
    expect(PublicTripSpeed.x4.next, PublicTripSpeed.x1);
  });
}
