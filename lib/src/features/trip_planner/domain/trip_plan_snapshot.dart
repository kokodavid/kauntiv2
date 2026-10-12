import 'trip_plan.dart';
import 'trip_route.dart';

/// Where the planned road stands, for the map, the stops and the Start bar.
enum TripPlanStatus {
  /// The first route is on its way.
  planning,

  /// A route is planned (it may be the previous one while a new one loads).
  ready,

  /// There is no location to start from.
  noLocation,

  /// The road could not be planned; the straight line still can be shown.
  noRoute,
}

/// What every part of Place Detail's Plan trip tab shows about the plan:
/// one value, so the map card and the Start bar never disagree.
class TripPlanSnapshot {
  const TripPlanSnapshot({
    required this.status,
    this.plan,
    this.updating = false,
    this.message,
    this.origin,
    this.straightMeters,
  });

  final TripPlanStatus status;

  /// The route to show. While [updating] it is the previous one.
  final TripPlan? plan;

  /// A new route is on its way and [plan] is the one before it.
  final bool updating;

  /// Why the road is missing, fit to show.
  final String? message;

  /// Where the user is, when known.
  final TripRoutePoint? origin;

  /// Straight-line metres from [origin] to the place.
  final double? straightMeters;

  /// "41 km", "4.2 km" for a straight-line distance.
  String? get straightLabel {
    final meters = straightMeters;
    if (meters == null) return null;
    final km = meters / 1000;
    return km < 10 ? '${km.toStringAsFixed(1)} km' : '${km.round()} km';
  }

  /// The Start bar's second line.
  String get barSummary {
    switch (status) {
      case TripPlanStatus.planning:
        return 'Planning the route…';
      case TripPlanStatus.noLocation:
        return 'Turn on location to see the distance';
      case TripPlanStatus.noRoute:
        final away = straightLabel;
        return away == null
            ? 'Road not loaded'
            : 'Road not loaded · about $away away';
      case TripPlanStatus.ready:
        final shown = plan!;
        final stops = shown.stops.length;
        final trip =
            '${shown.route.distanceLabel} · '
            '${shown.route.durationLabel}';
        return stops == 0
            ? trip
            : '$stops ${stops == 1 ? 'stop' : 'stops'} · $trip';
    }
  }
}
