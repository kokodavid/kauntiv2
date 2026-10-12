import 'dart:math' as math;

import '../../../core/domain/map_place.dart';
import '../../../counties/county_paths.dart';
import '../../profile/domain/place_interest.dart';

/// A place worth planning a trip to, with how far it is and whether its
/// county is still to claim.
class MapHomeNearbyPlace {
  const MapHomeNearbyPlace({
    required this.place,
    required this.county,
    required this.distanceMeters,
    required this.countyClaimed,
    this.matchedInterest,
  });

  final MapPlace place;
  final CountyPath county;
  final double distanceMeters;
  final bool countyClaimed;

  /// The interest this place's type matched for the user, if any.
  final PlaceInterest? matchedInterest;

  String get distanceLabel => MapHomeNearbyPlaces.distanceLabel(distanceMeters);
}

/// Picks the places nearest the user. Pure: the caller supplies the one
/// location read and the places it already loaded.
abstract final class MapHomeNearbyPlaces {
  /// The most cards the row shows.
  static const maxCards = 8;

  /// A matching place's distance counts as this fraction of the real one
  /// when ordering, so it can edge ahead of an equally close place without
  /// a match. The same factor Home uses for counties and the database uses
  /// in `for_you_candidates()`.
  static const interestDistanceFactor = 0.6;

  static List<MapHomeNearbyPlace> nearest({
    required List<MapPlace> places,
    required ({double latitude, double longitude}) from,
    required Set<int> claimedCountyCodes,
    int limit = maxCards,
    PlaceInterest? Function(String placeType)? interestFor,
  }) {
    final found = <MapHomeNearbyPlace>[];
    for (final place in places) {
      final county = CountyPaths.byCode[place.countyCode];
      if (county == null) continue;
      found.add(
        MapHomeNearbyPlace(
          place: place,
          county: county,
          distanceMeters: distanceMeters(
            from.latitude,
            from.longitude,
            place.lat,
            place.lng,
          ),
          countyClaimed: claimedCountyCodes.contains(place.countyCode),
          matchedInterest: interestFor?.call(place.type),
        ),
      );
    }
    double leaning(MapHomeNearbyPlace p) =>
        p.distanceMeters *
        (p.matchedInterest == null ? 1 : interestDistanceFactor);
    found.sort((a, b) => leaning(a).compareTo(leaning(b)));
    return found.take(limit).toList();
  }

  /// Great-circle distance in metres (haversine).
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
    return 2 * earthRadius * math.asin(math.sqrt(a.toDouble()));
  }

  /// "850 m", "4.2 km", "66 km".
  static String distanceLabel(double meters) {
    if (meters < 1000) return '${(meters / 50).round() * 50} m';
    final km = meters / 1000;
    return km < 10 ? '${km.toStringAsFixed(1)} km' : '${km.round()} km';
  }
}
