/// The account's Pro entitlement as last confirmed by the server.
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

  /// How long a cached status may gate an offline start.
  static const maxCacheAge = Duration(days: 7);

  /// Whether Start Journey is allowed at [now] on this status. Fresh from
  /// the server this is just [active] (within the period); from the cache
  /// it also has to be recent.
  bool allowsStartAt(DateTime now, {bool fromCache = false}) {
    if (!active) return false;
    final until = activeUntil;
    if (until != null && !now.isBefore(until)) return false;
    return !fromCache || now.difference(checkedAt) <= maxCacheAge;
  }
}

/// Starting a Journey needs Pro.
class JourneyStartDenied implements Exception {
  const JourneyStartDenied();
}
