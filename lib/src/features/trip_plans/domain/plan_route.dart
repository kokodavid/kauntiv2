/// A point on a plan's map.
class PlanRoutePoint {
  const PlanRoutePoint(this.lat, this.lng);

  final double lat;
  final double lng;

  @override
  bool operator ==(Object other) =>
      other is PlanRoutePoint && other.lat == lat && other.lng == lng;

  @override
  int get hashCode => Object.hash(lat, lng);
}

/// A road route worked out for one day. Always an estimate.
class PlanRoute {
  const PlanRoute({
    required this.points,
    required this.distanceM,
    required this.durationS,
  });

  final List<PlanRoutePoint> points;
  final int distanceM;
  final int durationS;
}

/// Why a day's route could not be worked out. [message] is fit to show.
class PlanRouteFailure implements Exception {
  const PlanRouteFailure(this.message);

  final String message;

  @override
  String toString() => 'PlanRouteFailure($message)';
}

/// What one day asks the routing service: the points in driving order.
/// Two requests with the same points are the same request, so the answer
/// is reused (cached by the day's stops).
class PlanLegRequest {
  const PlanLegRequest(this.points);

  final List<PlanRoutePoint> points;

  bool get isRoutable => points.length >= 2;

  @override
  bool operator ==(Object other) =>
      other is PlanLegRequest && _same(other.points, points);

  @override
  int get hashCode => Object.hashAll(points);

  static bool _same(List<PlanRoutePoint> a, List<PlanRoutePoint> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// One day on the plan map: its road (or, when no road is known, the
/// straight line between its stops), and its numbered stops.
class PlanMapDay {
  const PlanMapDay({
    required this.number,
    required this.line,
    required this.stops,
    this.estimated = false,
  });

  final int number;
  final List<PlanRoutePoint> line;
  final List<PlanRoutePoint> stops;

  /// The line is straight, not the road.
  final bool estimated;
}
