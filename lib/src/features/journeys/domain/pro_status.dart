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

/// Starting a Journey needs Pro.
class JourneyStartDenied implements Exception {
  const JourneyStartDenied();
}

/// Pro couldn't be checked (offline or the server unreachable). Starting a
/// Journey needs a live check, so no route can be recorded that the server
/// would later refuse to save.
class JourneyProCheckUnavailable implements Exception {
  const JourneyProCheckUnavailable();
}
