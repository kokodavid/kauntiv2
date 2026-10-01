/// The account's Pro entitlement as confirmed by the server.
class ProStatus {
  const ProStatus({
    required this.active,
    required this.checkedAt,
    this.activeUntil,
  });

  final bool active;

  /// When the current period ends; null means open-ended.
  final DateTime? activeUntil;
  final DateTime checkedAt;

  /// Whether Start Journey is allowed at [now].
  bool allowsStartAt(DateTime now) {
    if (!active) return false;
    final until = activeUntil;
    return until == null || now.isBefore(until);
  }
}

/// Pro couldn't be checked (offline or the server unreachable). Starting a
/// Journey needs a live check, so no route can be recorded that the server
/// would later refuse to save.
class JourneyProCheckUnavailable implements Exception {
  const JourneyProCheckUnavailable();
}

/// The free-Trip allowance for an account without Pro: a capped number of
/// Trips per calendar month (resets the 1st). Pro accounts are unlimited
/// and never consult this.
class JourneyTrialStatus {
  const JourneyTrialStatus({
    required this.tripsUsed,
    required this.tripLimit,
    required this.resetsAt,
  });

  /// Trips saved so far this period. A Trip only counts once it's
  /// actually saved/uploaded; one that's recorded but never uploaded
  /// doesn't use a slot.
  final int tripsUsed;

  /// Free Trips allowed per month.
  final int tripLimit;

  /// When the count next resets (the 1st of next month, UTC).
  final DateTime resetsAt;

  bool get hasRemaining => tripsUsed < tripLimit;

  int get tripsRemaining => (tripLimit - tripsUsed).clamp(0, tripLimit);
}

/// Starting a Journey needs Pro, or the free Trip allowance for this
/// month (checked live): neither is available right now.
class JourneyTrialExhausted implements Exception {
  const JourneyTrialExhausted();
}
