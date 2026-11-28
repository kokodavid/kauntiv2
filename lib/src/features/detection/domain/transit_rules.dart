import 'dart:math' as math;

/// ADR 0001, decision 7: when the speed between two fixes is above road
/// speed the phone was flying (or on a train that fast), not visiting the
/// counties below. Nothing is credited in transit, not even "passed
/// through"; the first good fix after it starts a normal visit.
///
/// Starting values; field data (issue #52) sets the final ones.
class TransitConfig {
  const TransitConfig({
    this.speedKmh = 200,
    this.minElapsed = const Duration(seconds: 20),
    this.hold = const Duration(minutes: 30),
  });

  /// Faster than this between two fixes is transit.
  final double speedKmh;

  /// Two fixes closer in time than this say nothing reliable about speed.
  final Duration minElapsed;

  /// How long transit blocks location-less geofence entries after the last
  /// fix that showed it.
  final Duration hold;

  double get speedMetersPerSecond => speedKmh / 3.6;
}

/// The pure speed test between two fixes.
class TransitRules {
  const TransitRules([this.config = const TransitConfig()]);

  final TransitConfig config;

  /// Whether going from one fix to the next was faster than [config]'s
  /// speed. Fixes too close in time, or out of order, are not judged.
  bool isTransit({
    required double fromLatitude,
    required double fromLongitude,
    required DateTime fromAt,
    required double toLatitude,
    required double toLongitude,
    required DateTime toAt,
  }) {
    final elapsed = toAt.difference(fromAt);
    if (elapsed < config.minElapsed) return false;
    final meters = distanceMeters(
      fromLatitude,
      fromLongitude,
      toLatitude,
      toLongitude,
    );
    return meters / elapsed.inSeconds > config.speedMetersPerSecond;
  }

  /// Great-circle distance in metres.
  static double distanceMeters(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const earthRadius = 6371000.0;
    double rad(double deg) => deg * math.pi / 180;
    final dLat = rad(lat2 - lat1);
    final dLng = rad(lng2 - lng1);
    final a =
        math.pow(math.sin(dLat / 2), 2) +
        math.cos(rad(lat1)) *
            math.cos(rad(lat2)) *
            math.pow(math.sin(dLng / 2), 2);
    return 2 * earthRadius * math.asin(math.sqrt(a));
  }
}
