import 'detection_status.dart';

/// What the safeguards did, counted on the phone and reported as totals.
/// Never which county or where (doc 05): only that it happened.
enum DetectionOutcome {
  /// A stay reached the dwell threshold and the county was claimed.
  claimed('claimed'),

  /// A crossing fix was too loose to trust (confidence gate).
  rejectedAccuracy('rejected_accuracy'),

  /// A crossing near a border waited for a second fix.
  heldBorder('held_border'),

  /// A fix implied flight or fast travel, so nothing was credited.
  transit('transit');

  const DetectionOutcome(this.wireName);

  final String wireName;
}

/// One health report: the state of detection plus the device, no places.
class DetectionHealthReport {
  const DetectionHealthReport({
    required this.platform,
    required this.tier,
    required this.reason,
    required this.counts,
    this.osVersion,
    this.manufacturer,
    this.model,
    this.appVersion,
    this.lastCycleGapSeconds,
    this.lastGeofenceGapSeconds,
  });

  final String platform;
  final String? osVersion;
  final String? manufacturer;
  final String? model;
  final String? appVersion;
  final DetectionTier tier;
  final DetectionReason reason;
  final int? lastCycleGapSeconds;
  final int? lastGeofenceGapSeconds;
  final Map<String, int> counts;

  /// The arguments of the `report_detection_health` RPC.
  Map<String, Object?> toRpcParams() => {
    'p_platform': platform,
    'p_os_version': osVersion,
    'p_manufacturer': manufacturer,
    'p_model': model,
    'p_app_version': appVersion,
    'p_tier': tierWire(tier),
    'p_reason': reasonWire(reason),
    'p_last_cycle_gap_s': lastCycleGapSeconds,
    'p_last_geofence_gap_s': lastGeofenceGapSeconds,
    'p_counts': counts,
  };

  static String tierWire(DetectionTier tier) => switch (tier) {
    DetectionTier.live => 'live',
    DetectionTier.catchUp => 'catch_up',
    DetectionTier.off => 'off',
  };

  static String reasonWire(DetectionReason reason) => switch (reason) {
    DetectionReason.none => 'none',
    DetectionReason.backgroundMissing => 'background_missing',
    DetectionReason.noPermission => 'no_permission',
    DetectionReason.servicesOff => 'services_off',
  };

  /// Seconds from [then] to [now]; null when [then] is unknown.
  static int? gapSeconds(DateTime? then, DateTime now) =>
      then == null ? null : now.difference(then).inSeconds.clamp(0, 1 << 31);
}

/// When a phone sends a report: the first time, when the tier changed since
/// the last one, and otherwise about once a day.
class DetectionHealthPolicy {
  const DetectionHealthPolicy._();

  static const interval = Duration(hours: 24);

  static bool due({
    required DetectionTier tier,
    required DateTime now,
    DateTime? lastAt,
    DetectionTier? lastTier,
  }) {
    if (lastAt == null || lastTier == null) return true;
    if (tier != lastTier) return true;
    return now.difference(lastAt) >= interval;
  }
}
