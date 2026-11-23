/// How a county on a route stands for the signed-in user.
enum PlanCountyStatus { claimed, home, notClaimed }

/// A county a day or a plan passes through.
class PlanCounty {
  const PlanCounty({required this.code, required this.status});

  final int code;
  final PlanCountyStatus status;

  /// Not claimed yet, so it would be new in the user's Passport if they
  /// stayed there. The route only passes through it; passing never claims.
  bool get isNew => status == PlanCountyStatus.notClaimed;
}

/// Turns route county codes into what the planner shows.
abstract final class PlanCounties {
  /// [codes] in order, once each, with their status. The home county reads
  /// as home whether or not it is claimed.
  static List<PlanCounty> of(
    Iterable<int> codes, {
    required Set<int> claimed,
    int? homeCode,
  }) {
    final seen = <int>{};
    return [
      for (final code in codes)
        if (seen.add(code))
          PlanCounty(
            code: code,
            status: code == homeCode
                ? PlanCountyStatus.home
                : claimed.contains(code)
                ? PlanCountyStatus.claimed
                : PlanCountyStatus.notClaimed,
          ),
    ];
  }

  /// How many counties across a whole plan would be new, each counted once
  /// even when several days pass through it (3a: "5 counties · 3 new").
  static int newCount(
    Iterable<Iterable<int>> days, {
    required Set<int> claimed,
    int? homeCode,
  }) => of(
    days.expand((codes) => codes),
    claimed: claimed,
    homeCode: homeCode,
  ).where((c) => c.isNew).length;
}
