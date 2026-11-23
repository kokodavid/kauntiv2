/// What a plan may hold, from its owner's tier (decision D1). The server
/// enforces these; the app only uses them to explain a limit before the
/// user hits it, and to show content over the limit as locked after a
/// downgrade.
class PlanLimits {
  const PlanLimits({
    required this.pro,
    required this.maxUpcomingPlans,
    required this.maxDays,
    required this.maxStopsPerDay,
    required this.maxPlaces,
    required this.maxMembers,
    required this.roles,
    required this.bestOrder,
    required this.offlineCopy,
    this.upcomingPlans,
  });

  /// Free, as the server defines it. Used until the server's answer loads.
  static const free = PlanLimits(
    pro: false,
    maxUpcomingPlans: 3,
    maxDays: 3,
    maxStopsPerDay: 8,
    maxPlaces: 30,
    maxMembers: 2,
    roles: false,
    bestOrder: false,
    offlineCopy: false,
  );

  /// Pro's limits, for the Free versus Pro comparison in the Pro sheet.
  static const proTier = PlanLimits(
    pro: true,
    maxUpcomingPlans: null,
    maxDays: 14,
    maxStopsPerDay: 20,
    maxPlaces: 100,
    maxMembers: 6,
    roles: true,
    bestOrder: true,
    offlineCopy: true,
  );

  final bool pro;

  /// Null means no limit (Pro).
  final int? maxUpcomingPlans;
  final int maxDays;
  final int maxStopsPerDay;
  final int maxPlaces;

  /// People in a plan, the owner included (Free: owner and one buddy).
  final int maxMembers;
  final bool roles;
  final bool bestOrder;
  final bool offlineCopy;

  /// How many upcoming plans the user owns; only set on the user's own
  /// limits (`my_trip_plan_limits`).
  final int? upcomingPlans;

  bool get canCreatePlan =>
      maxUpcomingPlans == null ||
      upcomingPlans == null ||
      upcomingPlans! < maxUpcomingPlans!;

  bool canAddDay(int days) => days < maxDays;
  bool canAddStop(int stopsOnDay) => stopsOnDay < maxStopsPerDay;
  bool canAddPlace(int places) => places < maxPlaces;

  /// Day [number] (1-based) is over the limit, so shown locked.
  bool isDayLocked(int number) => number > maxDays;

  /// The stop at [index] (0-based) on a day is over the limit.
  bool isStopLocked(int index) => index >= maxStopsPerDay;

  static PlanLimits fromJson(Object? json) {
    if (json is! Map) return free;
    int intOr(Object? value, int fallback) =>
        value is num ? value.toInt() : fallback;
    final maxPlans = json['max_upcoming_plans'];
    final upcoming = json['upcoming_plans'];
    return PlanLimits(
      pro: json['pro'] == true,
      maxUpcomingPlans: maxPlans is num ? maxPlans.toInt() : null,
      maxDays: intOr(json['max_days'], free.maxDays),
      maxStopsPerDay: intOr(json['max_stops_per_day'], free.maxStopsPerDay),
      maxPlaces: intOr(json['max_places'], free.maxPlaces),
      maxMembers: intOr(json['max_members'], free.maxMembers),
      roles: json['roles'] == true,
      bestOrder: json['best_order'] == true,
      offlineCopy: json['offline_copy'] == true,
      upcomingPlans: upcoming is num ? upcoming.toInt() : null,
    );
  }

  Map<String, Object?> toJson() => {
    'pro': pro,
    'max_upcoming_plans': maxUpcomingPlans,
    'max_days': maxDays,
    'max_stops_per_day': maxStopsPerDay,
    'max_places': maxPlaces,
    'max_members': maxMembers,
    'roles': roles,
    'best_order': bestOrder,
    'offline_copy': offlineCopy,
    'upcoming_plans': upcomingPlans,
  };
}
