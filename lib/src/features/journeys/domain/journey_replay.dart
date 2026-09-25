import 'dart:math' as math;

import 'journey_point.dart';
import 'journey_route.dart';

/// Replay speeds on offer.
enum JourneyReplaySpeed {
  x1(1),
  x2(2),
  x4(4);

  const JourneyReplaySpeed(this.factor);

  final int factor;

  String get label => '$factor×';
}

/// A route laid out for replay: the points in recording order, with the
/// time since the start and the distance so far at each one (distance
/// counted within segments only, like the route itself).
class JourneyReplayTrack {
  JourneyReplayTrack(JourneyRoute route)
    : points = [for (final segment in route.segments) ...segment] {
    var distance = 0.0;
    final distances = <double>[];
    for (var i = 0; i < points.length; i++) {
      if (i > 0 && points[i].segmentNumber == points[i - 1].segmentNumber) {
        distance += JourneyRoute.haversineMeters(points[i - 1], points[i]);
      }
      distances.add(distance);
    }
    _distances = distances;
  }

  final List<JourneyPoint> points;
  late final List<double> _distances;

  int get length => points.length;
  bool get canReplay => points.length > 1;
  int get lastIndex => math.max(points.length - 1, 0);

  /// How long a replay lasts at 1×: a quarter second per point, kept
  /// between 30 s and 2 min so short trips are watchable and long ones
  /// don't drag.
  Duration get baseDuration => Duration(
    milliseconds: (points.length * 250).clamp(30000, 120000),
  );

  /// Points to move per second of wall time at [speed].
  double pointsPerSecond(JourneyReplaySpeed speed) =>
      lastIndex / (baseDuration.inMilliseconds / 1000) * speed.factor;

  /// Time since the first point at [index].
  Duration elapsedAt(int index) =>
      points[index].recordedAt.difference(points.first.recordedAt);

  /// Distance travelled up to [index], in metres.
  double distanceAt(int index) => _distances[index];

  /// The route as far as [index], for drawing it as it plays.
  JourneyRoute routeUpTo(int index) =>
      JourneyRoute(points.sublist(0, index + 1));

  // Smooth replay: a position is fractional, e.g. 12.4 is 40% of the way
  // from point 12 to point 13.

  /// Where the marker is at [position]: between the two points around it,
  /// except across a pause (a new segment), where it waits at the earlier
  /// point instead of gliding across the gap.
  ({double latitude, double longitude}) positionAt(double position) {
    final (i, t) = _split(position);
    final a = points[i];
    if (t == 0 || a.segmentNumber != points[i + 1].segmentNumber) {
      return (latitude: a.latitude, longitude: a.longitude);
    }
    final b = points[i + 1];
    return (
      latitude: a.latitude + (b.latitude - a.latitude) * t,
      longitude: a.longitude + (b.longitude - a.longitude) * t,
    );
  }

  /// Time since the start at [position].
  Duration elapsedAtPosition(double position) {
    final (i, t) = _split(position);
    if (t == 0) return elapsedAt(i);
    final a = elapsedAt(i).inMilliseconds;
    final b = elapsedAt(i + 1).inMilliseconds;
    return Duration(milliseconds: (a + (b - a) * t).round());
  }

  /// Distance travelled at [position], in metres.
  double distanceAtPosition(double position) {
    final (i, t) = _split(position);
    if (t == 0) return distanceAt(i);
    return distanceAt(i) + (distanceAt(i + 1) - distanceAt(i)) * t;
  }

  /// The point index at or before [position] and how far towards the next
  /// one it is (0 at the last point).
  (int, double) _split(double position) {
    final clamped = position.clamp(0, lastIndex).toDouble();
    final i = clamped.floor();
    if (i >= lastIndex) return (lastIndex, 0);
    return (i, clamped - i);
  }
}
