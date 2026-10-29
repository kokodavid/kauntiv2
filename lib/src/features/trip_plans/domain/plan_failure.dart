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
  limitMembers,
  limitRoles,
  limitBestOrder,
  inviteInvalid,
  inviteExpired,
  inviteFull,
  userNotFound,
  alreadyMember,
  rateLimited,
  lastDay,
  routeStale,
  orderStale,
  routingFailed,
  badInput,
  offline,
  unknown;

  /// A Free-tier limit the Pro sheet can explain.
  bool get isLimit =>
      this == limitPlans ||
      this == limitDays ||
      this == limitStops ||
      this == limitPlaces ||
      this == limitMembers ||
      this == limitRoles ||
      this == limitBestOrder;

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
    'trip_plan_limit_members' => limitMembers,
    'trip_plan_limit_roles' => limitRoles,
    'trip_plan_limit_best_order' => limitBestOrder,
    'trip_plan_invite_invalid' => inviteInvalid,
    'trip_plan_invite_expired' => inviteExpired,
    'trip_plan_invite_full' => inviteFull,
    'trip_plan_user_not_found' => userNotFound,
    'trip_plan_already_member' => alreadyMember,
    'trip_plan_rate_limited' => rateLimited,
    'trip_plan_last_day' => lastDay,
    'trip_plan_route_stale' => routeStale,
    'trip_plan_order_stale' => orderStale,
    'trip_plan_routing_failed' => routingFailed,
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
    PlanFailureKind.limitMembers => 'This plan is full.',
    PlanFailureKind.limitRoles => 'View-only members are part of Pro.',
    PlanFailureKind.limitBestOrder => 'Best order is part of Pro.',
    PlanFailureKind.inviteInvalid => 'That invite link doesn\'t work.',
    PlanFailureKind.inviteExpired => 'That invite link has expired.',
    PlanFailureKind.inviteFull => 'That invite link has been used.',
    PlanFailureKind.userNotFound => 'No one has that username.',
    PlanFailureKind.alreadyMember => 'They are already on this plan.',
    PlanFailureKind.rateLimited => 'Too many tries. Wait a little.',
    PlanFailureKind.lastDay => 'A plan needs at least one day.',
    PlanFailureKind.routeStale => 'The plan changed. Try again.',
    PlanFailureKind.orderStale => 'The day changed. Try again.',
    PlanFailureKind.routingFailed => "Couldn't work out the order. Try again.",
    PlanFailureKind.badInput => 'That didn\'t look right. Try again.',
    PlanFailureKind.offline => 'You\'re offline. Try again when connected.',
    PlanFailureKind.unknown => 'Couldn\'t save. Try again.',
  };

  @override
  String toString() => 'PlanFailure(${kind.name})';
}
