import '../../../core/counties/county_boundary_resolver.dart';
import '../domain/journey_county_split.dart';
import '../domain/journey_point.dart';

/// Metres per county for [points], checking the last county first (most
/// points are in the same county as the one before).
Map<int, double> splitJourneyCounties(List<JourneyPoint> points) {
  int? last;
  return JourneyCountySplit.split(points, (latitude, longitude) {
    final previous = last;
    if (previous != null &&
        CountyBoundaryResolver.countyCodeFor(
              latitude: latitude,
              longitude: longitude,
              countyCodes: [previous],
            ) ==
            previous) {
      return previous;
    }
    final code = CountyBoundaryResolver.countyCodeFor(
      latitude: latitude,
      longitude: longitude,
    );
    if (code != null) last = code;
    return code;
  });
}
