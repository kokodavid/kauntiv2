import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/app_logger.dart';
import '../domain/detection_health_report.dart';
import '../domain/detection_status.dart';
import 'detection_outcome_counts.dart';
import 'device_profile.dart';

/// Sends detection health to the team (ADR 0001 decision 10): the tier and
/// why, how long since detection last heard from the OS, and outcome
/// counts, with the device make and model. No coordinates, counties or
/// places. Sent the first time, when the tier changes, and about daily.
/// Never throws: health is a note, not part of detection.
class DetectionHealthReporter {
  DetectionHealthReporter({
    required this.send,
    this.counts = const DetectionOutcomeCounts(),
    this.loadDevice = DeviceProfile.load,
  });

  /// Reports through the signed-in user's Supabase client.
  DetectionHealthReporter.supabase(SupabaseClient client)
    : this(
        send: (params) =>
            client.rpc<Object?>('report_detection_health', params: params),
      );

  static const _logger = AppLogger.detection();
  static const _lastAtKey = 'detection.health.last_at_ms';
  static const _lastTierKey = 'detection.health.last_tier';

  final Future<Object?> Function(Map<String, Object?> params) send;
  final DetectionOutcomeCounts counts;
  final Future<DeviceProfile> Function() loadDevice;

  Future<void> maybeReport(DetectionStatus status, {DateTime? now}) async {
    try {
      final at = now ?? DateTime.now();
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final lastMs = prefs.getInt(_lastAtKey);
      final lastTierName = prefs.getString(_lastTierKey);
      final due = DetectionHealthPolicy.due(
        tier: status.tier,
        now: at,
        lastAt: lastMs == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(lastMs, isUtc: true),
        lastTier: DetectionTier.values
            .where((t) => t.name == lastTierName)
            .firstOrNull,
      );
      if (!due) return;
      final device = await loadDevice();
      final totals = await counts.snapshot();
      await send(
        DetectionHealthReport(
          platform: device.platform,
          osVersion: device.osVersion,
          manufacturer: device.manufacturer,
          model: device.model,
          appVersion: device.appVersion,
          tier: status.tier,
          reason: status.reason,
          lastCycleGapSeconds: DetectionHealthReport.gapSeconds(
            status.lastCycleAt,
            at,
          ),
          lastGeofenceGapSeconds: DetectionHealthReport.gapSeconds(
            status.lastGeofenceAt,
            at,
          ),
          counts: totals,
        ).toRpcParams(),
      );
      await prefs.setInt(_lastAtKey, at.toUtc().millisecondsSinceEpoch);
      await prefs.setString(_lastTierKey, status.tier.name);
      await counts.subtract(totals);
    } on Object catch (error, stackTrace) {
      _logger.warning(
        'Detection health report skipped.',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
