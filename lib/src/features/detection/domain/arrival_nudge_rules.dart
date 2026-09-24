import 'visit_models.dart';

/// Which crossing gets the arrival sheet (v1 `ArrivalNudgeCoordinator`).
/// It keys off the ENTER (the active candidate), not the resolved visit:
/// the sheet is the "you crossed into X" moment, the unlock comes later.
abstract final class ArrivalNudgeRules {
  /// One crossing: the county plus when it was entered (v1's key format).
  static String keyFor(int countyCode, DateTime enteredAt) =>
      '$countyCode@${enteredAt.toUtc().toIso8601String()}';

  /// The newest crossing not in [suppressed] (the home county) and not
  /// already [shown]; null when there's nothing to show.
  static CountyArrivalNudge? pick(
    List<CountyArrivalNudge> candidates, {
    Set<int> suppressed = const {},
    Set<String> shown = const {},
  }) {
    CountyArrivalNudge? best;
    for (final candidate in candidates) {
      if (suppressed.contains(candidate.countyCode)) continue;
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
