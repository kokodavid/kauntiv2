/// One Journey in the history list.
class JourneySummary {
  const JourneySummary({
    required this.id,
    required this.title,
    required this.startedAt,
    required this.endedAt,
    required this.isUploaded,
    this.distanceMeters,
    this.pausedDuration = Duration.zero,
  });

  final String id;
  final String title;
  final DateTime startedAt;
  final DateTime endedAt;

  /// Computed by the server on upload; null while waiting to upload.
  final double? distanceMeters;

  /// False while it's only on this phone, waiting to upload.
  final bool isUploaded;

  /// Time spent paused (0 for Journeys uploaded before it was kept).
  final Duration pausedDuration;

  /// Recorded time: start to end, minus pauses.
  Duration get duration {
    final recorded = endedAt.difference(startedAt) - pausedDuration;
    return recorded.isNegative ? Duration.zero : recorded;
  }
}

abstract final class JourneyTitles {
  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  /// The default name until renaming exists: "Journey on 25 Sep 2026", in
  /// the phone's local date.
  static String defaultFor(DateTime startedAt) {
    final local = startedAt.toLocal();
    return 'Journey on ${local.day} ${_months[local.month - 1]} ${local.year}';
  }
}
