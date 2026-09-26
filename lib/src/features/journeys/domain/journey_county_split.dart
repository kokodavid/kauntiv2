import 'journey_point.dart';
import 'journey_route.dart';

/// How far a route went in each county, for "Journeys in this county".
abstract final class JourneyCountySplit {
  /// Metres per county code. Each step between consecutive points of a
  /// segment counts for the county its end point is in; a county the
  /// route only touched still appears, with 0 m. Points outside Kenya
  /// ([countyAt] null) and the jumps across pauses count for nothing.
  static Map<int, double> split(
    List<JourneyPoint> points,
    int? Function(double latitude, double longitude) countyAt,
  ) {
    final meters = <int, double>{};
    JourneyPoint? previous;
    for (final point in points) {
      final code = countyAt(point.latitude, point.longitude);
      if (code != null) {
        final step =
            previous != null && previous.segmentNumber == point.segmentNumber
            ? JourneyRoute.haversineMeters(previous, point)
            : 0.0;
        meters[code] = (meters[code] ?? 0) + step;
      }
      previous = point;
    }
    return meters;
  }
}
