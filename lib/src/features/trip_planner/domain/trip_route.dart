/// A point on a planned route.
class TripRoutePoint {
  const TripRoutePoint(this.lat, this.lng);

  final double lat;
  final double lng;
}

/// A planned road route to a place.
class TripRoute {
  const TripRoute({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  final List<TripRoutePoint> points;
  final double distanceMeters;
  final double durationSeconds;

  /// "4.2 km", "66 km".
  String get distanceLabel {
    final km = distanceMeters / 1000;
    return km < 10 ? '${km.toStringAsFixed(1)} km' : '${km.round()} km';
  }

  /// "12 min", "1 h 5 min", "3 h".
  String get durationLabel {
    final minutes = (durationSeconds / 60).round().clamp(1, 1 << 30);
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    return rest == 0 ? '$hours h' : '$hours h $rest min';
  }
}

/// Why a route could not be planned. [message] is fit to show.
class TripRouteException implements Exception {
  const TripRouteException(this.message, {this.locationOff = false});

  final String message;

  /// The route could not start because there is no location to start from.
  final bool locationOff;

  @override
  String toString() => 'TripRouteException: $message';
}
