import 'dart:math' as math;

import 'public_trip_owner_view.dart';

typedef PublicTripLatLng = ({double latitude, double longitude});

/// Replay speeds on offer.
enum PublicTripSpeed {
  x1(1),
  x2(2),
  x4(4);

  const PublicTripSpeed(this.factor);

  final int factor;

  String get label => '$factor×';

  PublicTripSpeed get next => values[(index + 1) % values.length];
}

/// A public route laid out for replay. The route has no times, so playback
/// is illustrative: an even pace along the points, never the real pace.
class PublicTripTrack {
  factory PublicTripTrack(List<List<PublicTripPoint>> routeLines) {
    final lines = [
      for (final line in routeLines)
        if (line.length > 1)
          [
            for (final p in line)
              (latitude: p.latitude, longitude: p.longitude),
          ],
    ];
    return PublicTripTrack._(lines);
  }

  PublicTripTrack._(this.lines) {
    var distance = 0.0;
    PublicTripLatLng? previous;
    for (var l = 0; l < lines.length; l++) {
      for (final point in lines[l]) {
        if (previous != null && _lineOf.last == l) {
          distance += haversineMeters(previous, point);
        }
        points.add(point);
        _lineOf.add(l);
        _distances.add(distance);
        previous = point;
      }
    }
  }

  final List<List<PublicTripLatLng>> lines;
  final List<PublicTripLatLng> points = [];
  final List<int> _lineOf = [];
  final List<double> _distances = [];

  bool get canReplay => points.length > 1;
  int get lastIndex => math.max(points.length - 1, 0);
  double get totalMeters => _distances.isEmpty ? 0 : _distances.last;

  /// A quarter second per point at 1×, kept between 30 s and 2 min.
  Duration get baseDuration =>
      Duration(milliseconds: (points.length * 250).clamp(30000, 120000));

  double pointsPerSecond(PublicTripSpeed speed) =>
      lastIndex / (baseDuration.inMilliseconds / 1000) * speed.factor;

  /// Distance covered at a fractional [position].
  double distanceAt(double position) {
    if (points.isEmpty) return 0;
    final (i, t) = _split(position);
    if (i >= lastIndex) return _distances[lastIndex];
    return _distances[i] + (_distances[i + 1] - _distances[i]) * t;
  }

  /// Where the marker is at [position]: between two points, waiting at the
  /// earlier one across a break between lines.
  PublicTripLatLng positionAt(double position) {
    final (i, t) = _split(position);
    final a = points[i];
    if (t == 0 || i >= lastIndex || _lineOf[i] != _lineOf[i + 1]) return a;
    final b = points[i + 1];
    return (
      latitude: a.latitude + (b.latitude - a.latitude) * t,
      longitude: a.longitude + (b.longitude - a.longitude) * t,
    );
  }

  /// The route as far as point [index], as separate lines.
  List<List<PublicTripLatLng>> linesUpTo(int index) {
    final result = <List<PublicTripLatLng>>[];
    var seen = 0;
    for (final line in lines) {
      if (seen > index) break;
      final take = math.min(line.length, index - seen + 1);
      result.add(line.sublist(0, take));
      seen += line.length;
    }
    return result;
  }

  /// The route point closest to a place, for tying a moment to the route.
  int nearestIndex(double latitude, double longitude) {
    var best = 0;
    var bestDistance = double.infinity;
    for (var i = 0; i < points.length; i++) {
      final dLat = points[i].latitude - latitude;
      final dLng = points[i].longitude - longitude;
      final d = dLat * dLat + dLng * dLng;
      if (d < bestDistance) {
        bestDistance = d;
        best = i;
      }
    }
    return best;
  }

  (int, double) _split(double position) {
    final clamped = position.clamp(0, lastIndex).toDouble();
    final i = clamped.floor();
    return (i, clamped - i);
  }

  static double haversineMeters(PublicTripLatLng a, PublicTripLatLng b) {
    const radius = 6371000.0;
    double rad(double deg) => deg * math.pi / 180;
    final dLat = rad(b.latitude - a.latitude);
    final dLng = rad(b.longitude - a.longitude);
    final h =
        math.pow(math.sin(dLat / 2), 2) +
        math.cos(rad(a.latitude)) *
            math.cos(rad(b.latitude)) *
            math.pow(math.sin(dLng / 2), 2);
    return 2 * radius * math.asin(math.sqrt(h));
  }
}
