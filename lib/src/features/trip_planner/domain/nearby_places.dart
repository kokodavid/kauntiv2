import 'dart:math' as math;

import '../../../core/domain/map_place.dart';

/// A place close to the one being planned, with how far it is from it.
class NearbyPlace {
  const NearbyPlace({required this.place, required this.distanceMeters});

  final MapPlace place;
  final double distanceMeters;

  /// "800 m", "4.2 km", "66 km".
  String get distanceLabel {
    if (distanceMeters < 1000) return '${(distanceMeters / 50).round() * 50} m';
    final km = distanceMeters / 1000;
    return km < 10 ? '${km.toStringAsFixed(1)} km' : '${km.round()} km';
  }
}

abstract final class NearbyPlaces {
  static const maxPlaces = 8;

  /// The places closest to ([lat], [lng]), nearest first, leaving out the
  /// place with id [exceptId] and any farther than [withinMeters].
  static List<NearbyPlace> near({
    required double lat,
    required double lng,
    required List<MapPlace> places,
    required String exceptId,
    double withinMeters = 150000,
    int limit = maxPlaces,
  }) {
    final found = [
      for (final place in places)
        if (place.id != exceptId)
          NearbyPlace(
            place: place,
            distanceMeters: metres(lat, lng, place.lat, place.lng),
          ),
    ].where((n) => n.distanceMeters <= withinMeters).toList()
      ..sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
    return found.take(limit).toList();
  }

  /// Great-circle distance in metres (haversine).
  static double metres(double lat1, double lng1, double lat2, double lng2) {
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
}
