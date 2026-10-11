import 'visit_models.dart';

/// Which crossing gets the arrival sheet (v1 `ArrivalNudgeCoordinator`).
/// It keys off the ENTER (the active candidate), not the resolved visit:
/// the sheet is the "you crossed into X" moment, the unlock comes later.
abstract final class ArrivalNudgeRules {
  /// One crossing: the county plus when it was entered (v1's key format).
  static String keyFor(int countyCode, DateTime enteredAt) =>
      '$countyCode@${enteredAt.toUtc().toIso8601String()}';

  /// A county that already showed the sheet stays quiet this long, however
  /// many times the phone crosses its border (a commute, a boundary road,
  /// GPS jitter). The first time a county is entered it always shows.
  static const revisitCooldown = Duration(days: 7);

  /// The newest crossing not in [suppressed] (the home county), not
  /// already [shown], and not in a county whose sheet showed within
  /// [revisitCooldown] ([lastShown] maps county code to when); null when
  /// there's nothing to show.
  static CountyArrivalNudge? pick(
    List<CountyArrivalNudge> candidates, {
    Set<int> suppressed = const {},
    Set<String> shown = const {},
    Map<int, DateTime> lastShown = const {},
    DateTime? now,
  }) {
    final at = now ?? DateTime.now();
    CountyArrivalNudge? best;
    for (final candidate in candidates) {
      if (suppressed.contains(candidate.countyCode)) continue;
      final last = lastShown[candidate.countyCode];
      if (last != null && at.difference(last) < revisitCooldown) continue;
      if (shown.contains(keyFor(candidate.countyCode, candidate.enteredAt))) {
        continue;
      }
      if (best == null || candidate.enteredAt.isAfter(best.enteredAt)) {
        best = candidate;
      }
    }
    return best;
  }
}
