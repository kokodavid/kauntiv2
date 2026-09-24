import 'dart:math' as math;

/// Copy and distance helpers shared by Explore's cards (v1 parity).
abstract final class ExploreLabels {
  /// `counties.rarity_pct` is null until a real rarity job runs; that gap
  /// is shown, not filled with an invented percentage.
  static String rarity(num? percent) {
    if (percent == null) return 'RARITY NOT TRACKED YET';
    final rounded = percent.round();
    return rounded <= 5
        ? 'ONLY $rounded% HAVE BEEN HERE'
        : '$rounded% HAVE BEEN HERE';
  }

  /// "LOCAL EXPERT · N VISITS" or "EXPLORED".
  static String mineStatus({
    required bool isLocalExpert,
    required int visits,
  }) => isLocalExpert ? 'LOCAL EXPERT · $visits VISITS' : 'EXPLORED';

  /// Straight-line distance only: there's no routing step, so no
  /// drive-time copy is generated.
  static String? distance(num? meters) {
    if (meters == null) return null;
    final km = meters / 1000;
    return km < 1
        ? '${meters.round()} m away'
        : '${km.toStringAsFixed(0)} km away';
  }

  static String? placeDistance({
    required ({double latitude, double longitude})? from,
    required double? latitude,
    required double? longitude,
  }) {
    if (from == null || latitude == null || longitude == null) return null;
    return distance(
      haversineMeters(from.latitude, from.longitude, latitude, longitude),
    );
  }

  /// UNCLAIMED's one-line county blurb from its first two places.
  static String blurb(List<String> placeNames) {
    if (placeNames.isEmpty) return 'No places on file yet for this county.';
    final count = placeNames.length;
    final word = count == 1 ? 'place' : 'places';
    return count == 1
        ? '1 $word to see, including ${placeNames[0]}.'
        : '$count $word to see, including ${placeNames[0]} and '
              '${placeNames[1]}.';
  }

  static const _earthRadiusMeters = 6371000.0;

  static double haversineMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    double toRad(double degrees) => degrees * (math.pi / 180);
    final dLat = toRad(lat2 - lat1);
    final dLon = toRad(lon2 - lon1);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(toRad(lat1)) *
            math.cos(toRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return _earthRadiusMeters * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }
}
