import 'plan_day_path.dart';
import 'trip_plan.dart';

/// The box around a plan's stops, with room around it, that Offline copy
/// saves the map for.
class PlanBounds {
  const PlanBounds({
    required this.south,
    required this.west,
    required this.north,
    required this.east,
  });

  final double south;
  final double west;
  final double north;
  final double east;

  /// The larger side, in degrees.
  double get span =>
      (north - south) > (east - west) ? north - south : east - west;

  /// The most detailed zoom to save: big areas get less detail so the
  /// download stays small.
  int get maxZoom => span > 8 ? 8 : (span > 4 ? 9 : 10);

  /// Null when the plan has nothing to draw yet.
  static PlanBounds? of(TripPlan plan, {double padding = 0.15}) {
    final points = [
      for (final day in plan.days) ...PlanDayPath.waypoints(plan, day),
    ];
    if (points.isEmpty) return null;
    var south = points.first.lat;
    var north = south;
    var west = points.first.lng;
    var east = west;
    for (final p in points) {
      if (p.lat < south) south = p.lat;
      if (p.lat > north) north = p.lat;
      if (p.lng < west) west = p.lng;
      if (p.lng > east) east = p.lng;
    }
    return PlanBounds(
      south: south - padding,
      west: west - padding,
      north: north + padding,
      east: east + padding,
    );
  }
}

/// Where a plan's offline copy stands.
class PlanOfflineState {
  const PlanOfflineState({this.savedAt, this.progress, this.failed = false});

  static const none = PlanOfflineState();

  final DateTime? savedAt;

  /// 0 to 1 while saving; null when idle.
  final double? progress;
  final bool failed;

  bool get saved => savedAt != null;
  bool get saving => progress != null;
}
