import 'visit_models.dart';

/// A county the phone entered whose visit hasn't been claimed yet: the
/// stay must reach the dwell threshold first (ADR decision 14).
class PendingClaim {
  const PendingClaim({required this.countyCode, required this.claimsAt});

  final int countyCode;
  final DateTime claimsAt;

  /// The soonest claim among [candidates]; null when none is pending.
  static PendingClaim? soonest(
    List<CountyArrivalNudge> candidates,
    Duration dwellThreshold,
  ) {
    PendingClaim? best;
    for (final candidate in candidates) {
      final claim = PendingClaim(
        countyCode: candidate.countyCode,
        claimsAt: candidate.enteredAt.add(dwellThreshold),
      );
      if (best == null || claim.claimsAt.isBefore(best.claimsAt)) best = claim;
    }
    return best;
  }

  Duration remaining(DateTime now) => claimsAt.difference(now);

  /// "1 h 20 m", "45 m", or "under a minute"; rounded up so it never
  /// reads 0 m while time is left.
  static String timeLeft(Duration remaining) {
    if (remaining <= Duration.zero) return 'any moment';
    final minutes = (remaining.inSeconds / 60).ceil();
    if (minutes < 2) return 'under a minute';
    if (minutes < 60) return '$minutes m';
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    return rest == 0 ? '$hours h' : '$hours h $rest m';
  }
}
