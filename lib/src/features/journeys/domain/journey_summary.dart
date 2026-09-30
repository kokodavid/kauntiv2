import 'journey_destination.dart';

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
    this.destination,
    this.topSpeedMps,
    this.highestElevationMeters,
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

  final JourneyDestination? destination;

  /// The device's fastest instantaneous speed, in m/s. Computed by the
  /// server on upload; null while waiting to upload or when no fix
  /// reported a speed.
  final double? topSpeedMps;

  /// The highest altitude reached, in metres above sea level. Computed by
  /// the server on upload; null while waiting to upload or when no fix
  /// reported an altitude.
  final double? highestElevationMeters;

  /// The average speed for the recorded time, in m/s; null once there is
  /// no recorded time or distance to divide.
  double? get averageSpeedMps {
    final distance = distanceMeters;
    final seconds = duration.inMilliseconds / 1000;
    if (distance == null || seconds <= 0) return null;
    return distance / seconds;
  }

  /// Recorded time: start to end, minus pauses.
  Duration get duration {
    final recorded = endedAt.difference(startedAt) - pausedDuration;
    return recorded.isNegative ? Duration.zero : recorded;
  }
}

abstract final class JourneyTitles {
  static String toPlace(JourneyDestination destination) =>
      'Trip to ${destination.name}';
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

  /// The default name until renaming exists: "Trip on 25 Sep 2026", in
  /// the phone's local date.
  static String defaultFor(DateTime startedAt) {
    final local = startedAt.toLocal();
    return 'Trip on ${local.day} ${_months[local.month - 1]} ${local.year}';
  }

  /// A month heading for grouping history ("This month", "Last month", or
  /// "September 2026"), in the phone's local date.
  static String monthLabel(DateTime startedAt) {
    final local = startedAt.toLocal();
    final now = DateTime.now();
    if (local.year == now.year && local.month == now.month) {
      return 'This month';
    }
    final lastMonth = DateTime(now.year, now.month - 1);
    if (local.year == lastMonth.year && local.month == lastMonth.month) {
      return 'Last month';
    }
    return '${_months[local.month - 1]} ${local.year}';
  }
}
