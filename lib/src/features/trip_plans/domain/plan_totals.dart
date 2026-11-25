import 'plan_counties.dart';
import 'plan_day.dart';
import 'plan_day_path.dart';

/// The numbers over the day list: stops, drive and distance, counties.
class PlanTotals {
  const PlanTotals({
    required this.stops,
    required this.distanceM,
    required this.durationS,
    required this.countyCodes,
    required this.pending,
  });

  final int stops;
  final int distanceM;
  final int durationS;

  /// Counties across all days, in order, each once.
  final List<int> countyCodes;

  /// Days that have stops but no route yet, so the totals are incomplete.
  final int pending;

  bool get hasRoute => distanceM > 0;

  /// [routes] holds each day's worked-out route by day number; the saved
  /// route stands in until the app has its own.
  static PlanTotals of(
    List<PlanDay> days, {
    Map<int, ({int distanceM, int durationS})> routes = const {},
  }) {
    var stops = 0, distance = 0, duration = 0, pending = 0;
    final counties = <int>[];
    for (final day in days) {
      stops += day.stops.length;
      final route = routes[day.number];
      if (route != null) {
        distance += route.distanceM;
        duration += route.durationS;
      } else if (day.hasFreshRoute) {
        distance += day.distanceM ?? 0;
        duration += day.durationS ?? 0;
      } else if (day.stops.isNotEmpty) {
        pending++;
      }
      counties.addAll(PlanDayPath.counties(day));
    }
    return PlanTotals(
      stops: stops,
      distanceM: distance,
      durationS: duration,
      countyCodes: PlanCounties.of(
        counties,
        claimed: const {},
      ).map((c) => c.code).toList(),
      pending: pending,
    );
  }
}
