import 'dart:math' as math;

import 'county_boundaries.dart';

/// Resolves a real GPS point to the bundled geoBoundaries ADM1 county
/// polygon. Native OS geofences are still circular wake-up triggers; this
/// is the precise county assignment layer used once the app has a point.
abstract final class CountyBoundaryResolver {
  /// A county entry must be at least this far inside the polygon before
  /// it counts as a stable crossing. This prevents GPS jitter or emulator
  /// route interpolation right on a boundary from rapidly flipping
  /// counties.
  static const boundaryHysteresisMeters = 500.0;

  static int? countyCodeFor({
    required double latitude,
    required double longitude,
    Iterable<int>? countyCodes,
    double minimumInsideDistanceMeters = 0,
  }) {
    final codes = countyCodes ?? CountyBoundaries.polygons.keys;
    for (final code in codes) {
      final box = CountyBoundaries.boxes[code];
      if (box == null || !box.contains(longitude, latitude)) continue;

      final polygons = CountyBoundaries.polygons[code];
      if (polygons == null) continue;

      if (_containsMultiPolygon(polygons, longitude, latitude)) {
        if (minimumInsideDistanceMeters > 0 &&
            _distanceToMultiPolygonBoundaryMeters(
                  polygons,
                  longitude,
                  latitude,
                ) <
                minimumInsideDistanceMeters) {
          continue;
        }
        return code;
      }
    }
    return null;
  }

  static bool _containsMultiPolygon(
    List<CountyBoundaryPolygon> polygons,
    double lng,
    double lat,
  ) {
    for (final polygon in polygons) {
      if (polygon.isEmpty) continue;
      if (!_ringContainsPoint(polygon.first, lng, lat)) continue;

      var insideHole = false;
      for (final hole in polygon.skip(1)) {
        if (_ringContainsPoint(hole, lng, lat)) {
          insideHole = true;
          break;
        }
      }
      if (!insideHole) return true;
    }
    return false;
  }

  static bool _ringContainsPoint(
    CountyBoundaryRing ring,
    double lng,
    double lat,
  ) {
    var inside = false;
    var j = ring.length - 1;

    for (var i = 0; i < ring.length; i++) {
      final xi = ring[i].$1;
      final yi = ring[i].$2;
      final xj = ring[j].$1;
      final yj = ring[j].$2;

      final intersects =
          ((yi > lat) != (yj > lat)) &&
          (lng < (xj - xi) * (lat - yi) / (yj - yi) + xi);
      if (intersects) inside = !inside;
      j = i;
    }

    return inside;
  }

  static double _distanceToMultiPolygonBoundaryMeters(
    List<CountyBoundaryPolygon> polygons,
    double lng,
    double lat,
  ) {
    var closest = double.infinity;
    for (final polygon in polygons) {
      for (final ring in polygon) {
        closest = _min(closest, _distanceToRingMeters(ring, lng, lat));
      }
    }
    return closest;
  }

  static double _distanceToRingMeters(
    CountyBoundaryRing ring,
    double lng,
    double lat,
  ) {
    var closest = double.infinity;
    for (var i = 0; i < ring.length - 1; i++) {
      closest = _min(
        closest,
        _distanceToSegmentMeters(
          lng: lng,
          lat: lat,
          startLng: ring[i].$1,
          startLat: ring[i].$2,
          endLng: ring[i + 1].$1,
          endLat: ring[i + 1].$2,
        ),
      );
    }
    return closest;
  }

  static double _distanceToSegmentMeters({
    required double lng,
    required double lat,
    required double startLng,
    required double startLat,
    required double endLng,
    required double endLat,
  }) {
    final latMeters = 111320.0;
    final lngMeters = 111320.0 * math.cos(lat * math.pi / 180);
    final px = 0.0;
    final py = 0.0;
    final ax = (startLng - lng) * lngMeters;
    final ay = (startLat - lat) * latMeters;
    final bx = (endLng - lng) * lngMeters;
    final by = (endLat - lat) * latMeters;
    final dx = bx - ax;
    final dy = by - ay;
    final lengthSquared = dx * dx + dy * dy;

    if (lengthSquared == 0) {
      return math.sqrt(ax * ax + ay * ay);
    }

    final t = (((px - ax) * dx + (py - ay) * dy) / lengthSquared).clamp(
      0.0,
      1.0,
    );
    final closestX = ax + t * dx;
    final closestY = ay + t * dy;
    return math.sqrt(closestX * closestX + closestY * closestY);
  }

  static double _min(double a, double b) => a < b ? a : b;
}
