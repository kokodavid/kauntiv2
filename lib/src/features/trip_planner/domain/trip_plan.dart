import '../../../core/domain/map_place.dart';
import 'trip_route.dart';

/// A route, the stops it was planned through (in driving order) and the
/// counties it passes through, in order.
class TripPlan {
  const TripPlan({
    required this.route,
    required this.countyCodes,
    this.stops = const [],
    this.extraMeters = 0,
  });

  final TripRoute route;
  final List<int> countyCodes;
  final List<MapPlace> stops;

  /// How much longer the user's own stop order is than the shortest one,
  /// when enough to warn about; 0 otherwise.
  final double extraMeters;
}
