import '../domain/detection_status.dart';
import '../domain/visit_models.dart';
import 'arrival_nudge.dart';

/// What the last foreground cycle saw.
class DetectionSnapshot {
  const DetectionSnapshot({
    this.currentCounty,
    this.activeCandidates = const [],
    this.resolved = const [],
    this.lastRunAt,
    this.status = DetectionStatus.initial,
  });

  final int? currentCounty;

  /// Counties being timed, captured before dwell resolution (the arrival
  /// sheet reads these).
  final List<CountyArrivalNudge> activeCandidates;

  /// Visits resolved by this cycle's dwell check.
  final List<ResolvedVisit> resolved;
  final DateTime? lastRunAt;

  /// How well detection can work right now (Live, Catch-up or Off, and the
  /// heartbeat). Home reads this, not the individual permission flags.
  final DetectionStatus status;

  /// "Always" isn't granted: geofences are removed, so counties are only
  /// recorded while the app is open (catch-up), or not at all.
  bool get backgroundLocationOff =>
      status.reason == DetectionReason.backgroundMissing ||
      status.reason == DetectionReason.noPermission;

  /// Location is switched off for the whole phone: nothing can be detected
  /// until it's back on (Home says so).
  bool get locationServicesOff => status.reason == DetectionReason.servicesOff;
}
