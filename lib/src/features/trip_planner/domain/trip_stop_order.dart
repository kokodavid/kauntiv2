import '../../../core/domain/map_place.dart';
import 'nearby_places.dart';

/// The order to visit the stops in: whichever gives the shortest straight
/// line path from where the user starts, through every stop, to the
/// destination. The destination is always last.
abstract final class TripStopOrder {
  /// More stops than this and the planner stops offering to add them.
  static const maxStops = 4;

  /// A chosen order is flagged when it is at least this much, and this
  /// much of the way again, longer than the shortest order.
  static const warnExtraMeters = 20000.0;
  static const warnExtraShare = 0.15;

  /// The straight line length of start -> [stops] in order -> destination.
  static double pathMeters({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
    required List<MapPlace> stops,
  }) {
    var lat = fromLat;
    var lng = fromLng;
    var total = 0.0;
    for (final stop in stops) {
      total += NearbyPlaces.metres(lat, lng, stop.lat, stop.lng);
      lat = stop.lat;
      lng = stop.lng;
    }
    return total + NearbyPlaces.metres(lat, lng, toLat, toLng);
  }

  /// How much longer (straight line) [chosen] is than the shortest order
  /// of the same stops, when that is enough to warn about; else 0.
  static double extraMeters({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
    required List<MapPlace> chosen,
  }) {
    if (chosen.length < 2) return 0;
    double length(List<MapPlace> stops) => pathMeters(
      fromLat: fromLat,
      fromLng: fromLng,
      toLat: toLat,
      toLng: toLng,
      stops: stops,
    );
    final shortest = length(
      order(
        fromLat: fromLat,
        fromLng: fromLng,
        toLat: toLat,
        toLng: toLng,
        stops: chosen,
      ),
    );
    final extra = length(chosen) - shortest;
    return extra >= warnExtraMeters && extra >= shortest * warnExtraShare
        ? extra
        : 0;
  }

  static List<MapPlace> order({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
    required List<MapPlace> stops,
  }) {
    if (stops.length < 2) return List.of(stops);
    List<MapPlace>? best;
    var bestLength = double.infinity;

    void walk(List<MapPlace> chosen, List<MapPlace> left, double length) {
      if (length >= bestLength) return;
      if (left.isEmpty) {
        final last = chosen.last;
        final total =
            length + NearbyPlaces.metres(last.lat, last.lng, toLat, toLng);
        if (total < bestLength) {
          bestLength = total;
          best = List.of(chosen);
        }
        return;
      }
      final lat = chosen.isEmpty ? fromLat : chosen.last.lat;
      final lng = chosen.isEmpty ? fromLng : chosen.last.lng;
      for (var i = 0; i < left.length; i++) {
        final next = left[i];
        walk(
          [...chosen, next],
          [...left.sublist(0, i), ...left.sublist(i + 1)],
          length + NearbyPlaces.metres(lat, lng, next.lat, next.lng),
        );
      }
    }

    walk(const [], stops, 0);
    return best ?? List.of(stops);
  }
}
