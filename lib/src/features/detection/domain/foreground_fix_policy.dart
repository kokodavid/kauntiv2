/// When the foreground cycle may read hardware location (ADR decision 13).
///
/// A fix on open or resume (`forced`), then more only while a visit is
/// pending, to confirm the stay or catch an exit. Nothing is polled when
/// nothing is pending. A recording Trip supplies its own fixes through
/// `TripFixIngest`, so it needs no extra read here.
class ForegroundFixPolicy {
  const ForegroundFixPolicy._();

  /// Gap between reads while a visit is pending.
  static const pendingInterval = Duration(minutes: 2);

  static bool shouldRead({
    required bool forced,
    required bool hasPending,
    required DateTime now,
    DateTime? lastReadAt,
  }) {
    if (forced) return true;
    if (!hasPending) return false;
    return lastReadAt == null || now.difference(lastReadAt) >= pendingInterval;
  }
}
