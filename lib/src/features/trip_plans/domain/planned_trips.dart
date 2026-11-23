import 'trip_plan_summary.dart';

/// The two halves of the Trips tab, in the order they are shown. Recorded
/// comes first and is where the tab always opens.
enum TripsSegment { recorded, planned }

/// The Planned list, split the way the Trips tab shows it (design 1b, 1c).
class PlannedTrips {
  const PlannedTrips({
    this.upcoming = const [],
    this.shared = const [],
    this.past = const [],
    this.archived = const [],
  });

  /// Plans the user owns that are still ahead: dated plans first, soonest
  /// at the top, then undated plans, most recently changed first.
  final List<TripPlanSummary> upcoming;

  /// Plans someone else owns that the user has joined, not yet past.
  final List<TripPlanSummary> shared;

  /// Plans whose last day has passed, newest first.
  final List<TripPlanSummary> past;

  /// The user's archived plans.
  final List<TripPlanSummary> archived;

  bool get isEmpty =>
      upcoming.isEmpty && shared.isEmpty && past.isEmpty && archived.isEmpty;

  /// Anything besides archived plans.
  bool get hasActive =>
      upcoming.isNotEmpty || shared.isNotEmpty || past.isNotEmpty;

  bool get hasUpcoming => upcoming.isNotEmpty || shared.isNotEmpty;

  /// The plan Home shows: the soonest of the user's own and joined plans
  /// that are still ahead (a trip under way counts), else the one changed
  /// most recently. Null when there is none.
  TripPlanSummary? get next {
    final all = [...upcoming, ...shared]..sort(_soonestFirst);
    return all.isEmpty ? null : all.first;
  }

  /// Upcoming plans that count toward the Free limit (converted plans from
  /// the old planner never count, decision D5).
  int get countedUpcoming => upcoming.where((p) => !p.converted).length;

  static PlannedTrips split(List<TripPlanSummary> plans) {
    final upcoming = <TripPlanSummary>[];
    final shared = <TripPlanSummary>[];
    final past = <TripPlanSummary>[];
    final archived = <TripPlanSummary>[];
    for (final plan in plans) {
      if (plan.archived && plan.isOwn) {
        archived.add(plan);
      } else if (plan.isPast) {
        past.add(plan);
      } else if (plan.isOwn) {
        upcoming.add(plan);
      } else {
        shared.add(plan);
      }
    }
    upcoming.sort(_soonestFirst);
    shared.sort(_soonestFirst);
    past.sort((a, b) => _compareDates(b.startDate, a.startDate));
    archived.sort((a, b) => _compareDates(b.updatedAt, a.updatedAt));
    return PlannedTrips(
      upcoming: upcoming,
      shared: shared,
      past: past,
      archived: archived,
    );
  }

  static int _soonestFirst(TripPlanSummary a, TripPlanSummary b) {
    final aDate = a.startDate;
    final bDate = b.startDate;
    if (aDate != null && bDate != null) return aDate.compareTo(bDate);
    if (aDate != null) return -1;
    if (bDate != null) return 1;
    return _compareDates(b.updatedAt, a.updatedAt);
  }

  static int _compareDates(DateTime? a, DateTime? b) {
    if (a == null && b == null) return 0;
    if (a == null) return -1;
    if (b == null) return 1;
    return a.compareTo(b);
  }
}
