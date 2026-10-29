/// Why a planner change was refused. The server sends stable codes
/// (`trip_plan_limit_days` and so on); this maps them to what the app
/// explains.
enum PlanFailureKind {
  unavailable,
  signedOut,
  notFound,
  viewOnly,
  ownerOnly,
  placeUnavailable,
  limitPlans,
  limitDays,
  limitStops,
  limitPlaces,
  lastDay,
  routeStale,
  badInput,
  offline,
  unknown;

  /// A Free-tier limit the Pro sheet can explain.
  bool get isLimit =>
      this == limitPlans ||
      this == limitDays ||
      this == limitStops ||
      this == limitPlaces;

  static PlanFailureKind fromCode(String? message) => switch (message) {
    'trip_plans_unavailable' => unavailable,
    'not_signed_in' => signedOut,
    'trip_plan_not_found' => notFound,
    'trip_plan_view_only' => viewOnly,
    'trip_plan_owner_only' => ownerOnly,
    'trip_plan_place_unavailable' => placeUnavailable,
    'trip_plan_limit_plans' => limitPlans,
    'trip_plan_limit_days' => limitDays,
    'trip_plan_limit_stops' => limitStops,
    'trip_plan_limit_places' => limitPlaces,
    'trip_plan_last_day' => lastDay,
    'trip_plan_route_stale' => routeStale,
    'trip_plan_bad_input' => badInput,
    _ => unknown,
  };
}

class PlanFailure implements Exception {
  const PlanFailure(this.kind);

  final PlanFailureKind kind;

  /// One short line for a toast or an inline note.
  String get message => switch (kind) {
    PlanFailureKind.unavailable => 'Trip plans aren\'t available right now.',
    PlanFailureKind.signedOut => 'Sign in to plan a trip.',
    PlanFailureKind.notFound => 'This plan is no longer available.',
    PlanFailureKind.viewOnly => 'You can view this plan but not change it.',
    PlanFailureKind.ownerOnly => 'Only the plan\'s owner can do that.',
    PlanFailureKind.placeUnavailable => 'That place can\'t be added any more.',
    PlanFailureKind.limitPlans => 'Free keeps 3 upcoming plans.',
    PlanFailureKind.limitDays => 'Free plans have up to 3 days.',
    PlanFailureKind.limitStops => 'Free days hold 8 stops.',
    PlanFailureKind.limitPlaces => 'Free plans hold 30 places to visit.',
    PlanFailureKind.lastDay => 'A plan needs at least one day.',
    PlanFailureKind.routeStale => 'The plan changed. Try again.',
    PlanFailureKind.badInput => 'That didn\'t look right. Try again.',
    PlanFailureKind.offline => 'You\'re offline. Try again when connected.',
    PlanFailureKind.unknown => 'Couldn\'t save. Try again.',
  };

  @override
  String toString() => 'PlanFailure(${kind.name})';
}
