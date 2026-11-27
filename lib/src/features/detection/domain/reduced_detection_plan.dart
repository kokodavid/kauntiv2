import 'detection_status.dart';

/// What to do with the one "detection is reduced" notification (PRD
/// requirement 5). A reduced episode starts when the tier drops below Live
/// and ends when it returns; each episode gets at most one notice, sent once
/// it has lasted [threshold]. Never repeated while the episode continues.
enum ReducedAction { schedule, cancel, none }

class ReducedDetectionPlan {
  const ReducedDetectionPlan({required this.action, this.at, this.since});

  final ReducedAction action;

  /// When the notification is due (for [ReducedAction.schedule]).
  final DateTime? at;

  /// The episode start to remember; null clears it.
  final DateTime? since;

  /// Starting value, to confirm with the device matrix (#52).
  static const threshold = Duration(hours: 24);

  /// [since]: when the current episode began, if one is known.
  /// [scheduledThisEpisode]: whether a notice was already scheduled for it.
  static ReducedDetectionPlan decide({
    required DetectionTier tier,
    required DateTime now,
    DateTime? since,
    bool scheduledThisEpisode = false,
  }) {
    if (tier == DetectionTier.live) {
      // Back to normal: end the episode and drop a notice not yet shown.
      return ReducedDetectionPlan(
        action: since == null && !scheduledThisEpisode
            ? ReducedAction.none
            : ReducedAction.cancel,
      );
    }
    final start = since ?? now;
    if (scheduledThisEpisode) {
      return ReducedDetectionPlan(action: ReducedAction.none, since: start);
    }
    final due = start.add(threshold);
    return ReducedDetectionPlan(
      action: ReducedAction.schedule,
      at: due.isAfter(now) ? due : now.add(const Duration(minutes: 1)),
      since: start,
    );
  }

  /// The words for why detection is reduced.
  static ({String title, String body}) copy(DetectionReason reason) =>
      switch (reason) {
        DetectionReason.backgroundMissing => (
          title: 'Kaunti47 is only tracking while open',
          body:
              'Allow location "All the time" so counties are caught when the '
              'app is closed.',
        ),
        DetectionReason.servicesOff => (
          title: 'Location is off',
          body: 'Turn location back on so Kaunti47 can record your counties.',
        ),
        _ => (
          title: 'Kaunti47 can\'t see your location',
          body: 'Allow location in Settings so your counties are recorded.',
        ),
      };
}
