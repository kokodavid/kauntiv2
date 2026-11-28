/// ADR 0001, decisions 1, 3 and 5: how well detection can work right now.
enum DetectionTier {
  /// "Always" is granted: the OS wakes the app on a county crossing.
  live,

  /// Only "While using": counties are recorded when the app is opened.
  catchUp,

  /// Nothing can be detected until something changes.
  off,
}

/// Why detection is below [DetectionTier.live]; drives what Home says and
/// which fix it offers.
enum DetectionReason {
  none,

  /// "Always" missing, "While using" granted.
  backgroundMissing,

  /// No location permission at all.
  noPermission,

  /// Location is switched off for the whole phone.
  servicesOff,
}

/// The one status model Home, Settings and the health records read, instead
/// of each combining permission flags on their own.
///
/// [lastCycleAt] and [lastGeofenceAt] are the heartbeat: when the foreground
/// cycle last ran and when the OS last woke the app for a crossing. They are
/// reported, not judged here: a phone that sits at home for days legitimately
/// sees no geofence event, so silence alone never lowers the tier.
class DetectionStatus {
  const DetectionStatus({
    required this.tier,
    this.reason = DetectionReason.none,
    this.lastCycleAt,
    this.lastGeofenceAt,
  });

  /// Before the first cycle has said otherwise.
  static const initial = DetectionStatus(tier: DetectionTier.live);

  final DetectionTier tier;
  final DetectionReason reason;
  final DateTime? lastCycleAt;
  final DateTime? lastGeofenceAt;

  /// Works out the tier from what the phone currently allows. Location off
  /// for the phone or no permission at all beats everything; otherwise
  /// "Always" is live and "While using" is catch-up.
  static DetectionStatus derive({
    required bool backgroundGranted,
    required bool foregroundGranted,
    required bool servicesEnabled,
    DateTime? lastCycleAt,
    DateTime? lastGeofenceAt,
  }) {
    final (tier, reason) = !servicesEnabled
        ? (DetectionTier.off, DetectionReason.servicesOff)
        : backgroundGranted
        ? (DetectionTier.live, DetectionReason.none)
        : foregroundGranted
        ? (DetectionTier.catchUp, DetectionReason.backgroundMissing)
        : (DetectionTier.off, DetectionReason.noPermission);
    return DetectionStatus(
      tier: tier,
      reason: reason,
      lastCycleAt: lastCycleAt,
      lastGeofenceAt: lastGeofenceAt,
    );
  }

  DetectionStatus withHeartbeat({
    DateTime? lastCycleAt,
    DateTime? lastGeofenceAt,
  }) => DetectionStatus(
    tier: tier,
    reason: reason,
    lastCycleAt: lastCycleAt ?? this.lastCycleAt,
    lastGeofenceAt: lastGeofenceAt ?? this.lastGeofenceAt,
  );
}
