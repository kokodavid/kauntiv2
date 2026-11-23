import 'plan_day.dart';
import 'plan_day_path.dart';
import 'plan_route.dart';
import 'trip_plan.dart';

/// The road between a day's stops (design 3a: "about 50 min · 41 km"
/// between stops). Known only when the worked-out road lines up with the
/// day's waypoints; otherwise there are no per-stop times, and the day's
/// total still shows.
class PlanDayLegs {
  const PlanDayLegs({required this.beforeStop, this.toOvernight});

  const PlanDayLegs.none() : beforeStop = const [], toOvernight = null;

  /// The leg that arrives at each stop, by stop index; null where unknown
  /// (the first stop of a day with no start point).
  final List<PlanLeg?> beforeStop;

  /// The leg from the last stop to tonight's stay, when there is one.
  final PlanLeg? toOvernight;

  PlanLeg? before(int stopIndex) =>
      stopIndex < beforeStop.length ? beforeStop[stopIndex] : null;

  static PlanDayLegs of(TripPlan plan, PlanDay day, PlanRoute? route) {
    if (route == null || route.legs.isEmpty) return const PlanDayLegs.none();
    final waypoints = PlanDayPath.waypoints(plan, day);
    if (route.legs.length != waypoints.length - 1) {
      return const PlanDayLegs.none();
    }
    // Every stop must be a waypoint, or the legs can't be matched to them.
    if (PlanDayPath.stopPoints(day).length != day.stops.length) {
      return const PlanDayLegs.none();
    }
    final hasOrigin = PlanDayPath.origin(plan, day) != null;
    final offset = hasOrigin ? 0 : -1;
    PlanLeg? at(int i) =>
        i >= 0 && i < route.legs.length ? route.legs[i] : null;
    return PlanDayLegs(
      beforeStop: [for (var i = 0; i < day.stops.length; i++) at(i + offset)],
      toOvernight: at(day.stops.length + offset),
    );
  }
}
