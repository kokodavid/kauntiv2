import 'dart:math' as math;

import '../../counties/county_paths.dart';

/// Straight-line distances between county centroids.
abstract final class CountyDistance {
  static const _earthRadiusMeters = 6371000.0;

  /// Great-circle distance between two counties' centroids, or null when
  /// either code has no centroid.
  static double? betweenCentroids(int a, int b) {
    final from = CountyPaths.centroids[a];
    final to = CountyPaths.centroids[b];
    if (from == null || to == null) return null;
    return haversineMeters(from.$1, from.$2, to.$1, to.$2);
  }

  static double haversineMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    double rad(double degrees) => degrees * math.pi / 180;
    final dLat = rad(lat2 - lat1);
    final dLon = rad(lon2 - lon1);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(rad(lat1)) *
            math.cos(rad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return _earthRadiusMeters * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }
}
