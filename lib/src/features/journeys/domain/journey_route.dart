import 'dart:math' as math;

import 'journey_point.dart';

/// A recorded route: its points split into segments (a pause or a restart
/// starts a new one), so a gap is never drawn or measured as a straight
/// line.
class JourneyRoute {
  JourneyRoute(List<JourneyPoint> points)
    : segments = _split(points),
      pointCount = points.length;

  final List<List<JourneyPoint>> segments;
  final int pointCount;

  bool get isEmpty => pointCount == 0;

  /// Distance within segments, in metres (the server computes the stored
  /// figure the same way on upload).
  double get distanceMeters {
    var total = 0.0;
    for (final segment in segments) {
      for (var i = 1; i < segment.length; i++) {
        total += haversineMeters(segment[i - 1], segment[i]);
      }
    }
    return total;
  }

  /// South-west and north-east corners; null for an empty route.
  ({double south, double west, double north, double east})? get bounds {
    if (isEmpty) return null;
    var south = 90.0, north = -90.0, west = 180.0, east = -180.0;
    for (final segment in segments) {
      for (final p in segment) {
        south = math.min(south, p.latitude);
        north = math.max(north, p.latitude);
        west = math.min(west, p.longitude);
        east = math.max(east, p.longitude);
      }
    }
    return (south: south, west: west, north: north, east: east);
  }

  /// The route as GeoJSON: one LineString per segment with 2+ points, and
  /// lone points as Points, for the map.
  Map<String, Object?> toGeoJson() => {
    'type': 'FeatureCollection',
    'features': [
      for (final segment in segments)
        {
          'type': 'Feature',
          'properties': <String, Object?>{},
          'geometry': segment.length == 1
              ? {
                  'type': 'Point',
                  'coordinates': [segment.single.longitude, segment.single.latitude],
                }
              : {
                  'type': 'LineString',
                  'coordinates': [
                    for (final p in segment) [p.longitude, p.latitude],
                  ],
                },
        },
    ],
  };

  static List<List<JourneyPoint>> _split(List<JourneyPoint> points) {
    final segments = <List<JourneyPoint>>[];
    for (final point in points) {
      if (segments.isEmpty ||
          segments.last.last.segmentNumber != point.segmentNumber) {
        segments.add([point]);
      } else {
        segments.last.add(point);
      }
    }
    return segments;
  }

  static const _earthRadiusMeters = 6371000.0;

  static double haversineMeters(JourneyPoint a, JourneyPoint b) {
    double rad(double deg) => deg * math.pi / 180;
    final dLat = rad(b.latitude - a.latitude);
    final dLng = rad(b.longitude - a.longitude);
    final h =
        math.pow(math.sin(dLat / 2), 2) +
        math.cos(rad(a.latitude)) *
            math.cos(rad(b.latitude)) *
            math.pow(math.sin(dLng / 2), 2);
    return 2 * _earthRadiusMeters * math.asin(math.sqrt(h));
  }
}

/// Journey figures as the Journeys screens show them.
abstract final class JourneyFormat {
  static String distance(double? meters) {
    if (meters == null) return '—';
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(meters < 10000 ? 1 : 0)} km';
  }

  /// "1 h 05 min", "12 min", "45 s".
  static String duration(Duration d) {
    if (d.inMinutes < 1) return '${d.inSeconds} s';
    if (d.inHours < 1) return '${d.inMinutes} min';
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    return '${d.inHours} h $minutes min';
  }

  /// A live clock: "0:04:09".
  static String clock(Duration d) {
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '${d.inHours}:$m:$s';
  }
}
