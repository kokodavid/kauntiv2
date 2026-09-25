/// One Journey in the history list.
class JourneySummary {
  const JourneySummary({
    required this.id,
    required this.title,
    required this.startedAt,
    required this.endedAt,
    required this.isUploaded,
    this.distanceMeters,
  });

  final String id;
  final String title;
  final DateTime startedAt;
  final DateTime endedAt;

  /// Computed by the server on upload; null while waiting to upload.
  final double? distanceMeters;

  /// False while it's only on this phone, waiting to upload.
  final bool isUploaded;

  Duration get duration => endedAt.difference(startedAt);
}

abstract final class JourneyTitles {
  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  /// The default name until renaming exists: "Journey on 25 Sep 2026", in
  /// the phone's local date.
  static String defaultFor(DateTime startedAt) {
    final local = startedAt.toLocal();
    return 'Journey on ${local.day} ${_months[local.month - 1]} ${local.year}';
  }
}
