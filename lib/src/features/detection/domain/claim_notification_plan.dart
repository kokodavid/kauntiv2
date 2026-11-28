import 'pending_claim.dart';
import 'visit_models.dart';

/// What to schedule and cancel so iOS, which has no dwell event, still
/// tells the user when a stay has earned the county (ADR decision 8).
class ClaimNotificationPlan {
  const ClaimNotificationPlan({required this.schedule, required this.cancel});

  /// Claims still in the future, one per county in [candidates].
  final List<PendingClaim> schedule;

  /// Counties that were scheduled but no longer have a candidate (left
  /// early, or already claimed).
  final Set<int> cancel;

  /// [scheduled] holds the counties with a notification already pending.
  /// The home county never gets one, as with arrival notifications.
  static ClaimNotificationPlan build({
    required List<CountyArrivalNudge> candidates,
    required Set<int> scheduled,
    required Duration dwell,
    required DateTime now,
    int? homeCounty,
  }) {
    final claims = <PendingClaim>[
      for (final c in candidates)
        if (c.countyCode != homeCounty)
          PendingClaim(
            countyCode: c.countyCode,
            claimsAt: c.enteredAt.add(dwell),
          ),
    ];
    final wanted = {
      for (final c in claims)
        if (c.claimsAt.isAfter(now)) c.countyCode,
    };
    return ClaimNotificationPlan(
      schedule: [
        for (final c in claims)
          if (wanted.contains(c.countyCode)) c,
      ],
      cancel: scheduled.difference(wanted),
    );
  }
}
