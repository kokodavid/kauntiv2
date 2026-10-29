import 'plan_day.dart';
import 'plan_route.dart';
import 'trip_plan.dart';

/// Where a day starts, passes and ends, in driving order.
abstract final class PlanDayPath {
  /// The day's points: where it starts (Day 1: the plan's start; later days:
  /// last night's stay, else the previous day's last stop), each stop, and
  /// tonight's stay. Points without a position are left out.
  static List<PlanRoutePoint> waypoints(TripPlan plan, PlanDay day) {
    return [
      ?_origin(plan, day),
      for (final stop in day.stops)
        if (stop.place.hasPosition)
          PlanRoutePoint(stop.place.lat!, stop.place.lng!),
      ?_overnight(day),
    ];
  }

  /// The stops alone, numbered on the map.
  static List<PlanRoutePoint> stopPoints(PlanDay day) => [
    for (final stop in day.stops)
      if (stop.place.hasPosition)
        PlanRoutePoint(stop.place.lat!, stop.place.lng!),
  ];

  /// Counties the day passes through: the saved route's while it is still
  /// current, otherwise those of the day's stops in order.
  static List<int> counties(PlanDay day) => day.hasFreshRoute
      ? day.countyCodes
      : _unique([for (final stop in day.stops) stop.place.countyCode]);

  /// Where the day starts: the plan's start, or where the day before ended.
  static PlanRoutePoint? origin(TripPlan plan, PlanDay day) =>
      _origin(plan, day);

  static PlanRoutePoint? _origin(TripPlan plan, PlanDay day) {
    if (day.number > 1) {
      final before = plan.days.where((d) => d.number == day.number - 1);
      if (before.isNotEmpty) {
        final last = before.first;
        final stay = _overnight(last);
        if (stay != null) return stay;
        for (final stop in last.stops.reversed) {
          if (stop.place.hasPosition) {
            return PlanRoutePoint(stop.place.lat!, stop.place.lng!);
          }
        }
      }
    }
    return _start(plan);
  }

  static PlanRoutePoint? _start(TripPlan plan) {
    final place = plan.start.place;
    if (place != null && place.hasPosition) {
      return PlanRoutePoint(place.lat!, place.lng!);
    }
    final lat = plan.start.lat;
    final lng = plan.start.lng;
    return lat == null || lng == null ? null : PlanRoutePoint(lat, lng);
  }

  static PlanRoutePoint? _overnight(PlanDay day) {
    final place = day.overnightPlace;
    if (place != null && place.hasPosition) {
      return PlanRoutePoint(place.lat!, place.lng!);
    }
    final lat = day.overnightLat;
    final lng = day.overnightLng;
    return lat == null || lng == null ? null : PlanRoutePoint(lat, lng);
  }

  static List<int> _unique(Iterable<int> codes) {
    final seen = <int>{};
    return [
      for (final code in codes)
        if (seen.add(code)) code,
    ];
  }
}
