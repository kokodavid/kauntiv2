import 'journey_summary.dart';

/// Where a Trip's distance puts it: a quick hop, a day drive, or a long
/// haul. A Trip with no distance yet (still waiting to upload) has none.
enum JourneyLengthBucket {
  quickHop,
  dayDrive,
  longHaul;

  String get title => switch (this) {
    JourneyLengthBucket.quickHop => 'Quick hops',
    JourneyLengthBucket.dayDrive => 'Day drives',
    JourneyLengthBucket.longHaul => 'Long hauls',
  };

  /// Under 15 km is a quick hop; up to 80 km a day drive; anything
  /// further a long haul.
  static const _quickHopMaxMeters = 15000;
  static const _dayDriveMaxMeters = 80000;

  static JourneyLengthBucket? of(double? meters) {
    if (meters == null) return null;
    if (meters < _quickHopMaxMeters) return JourneyLengthBucket.quickHop;
    if (meters < _dayDriveMaxMeters) return JourneyLengthBucket.dayDrive;
    return JourneyLengthBucket.longHaul;
  }
}

/// One month's worth of the Trips list: a heading ("This month", "August
/// 2026") over the Trips started that month, newest first.
class JourneyMonthGroup {
  const JourneyMonthGroup({required this.title, required this.journeys});

  final String title;
  final List<JourneySummary> journeys;

  double get totalMeters => journeys.fold(
    0,
    (sum, journey) => sum + (journey.distanceMeters ?? 0),
  );
}

/// Buckets already-filtered, newest-first [journeys] by the month they
/// started in, preserving that newest-first order between months.
abstract final class JourneyGrouper {
  static List<JourneyMonthGroup> byMonth(List<JourneySummary> journeys) {
    final order = <String>[];
    final byLabel = <String, List<JourneySummary>>{};
    for (final journey in journeys) {
      final label = JourneyTitles.monthLabel(journey.startedAt);
      (byLabel[label] ??= []).add(journey);
      if (!order.contains(label)) order.add(label);
    }
    return [
      for (final label in order)
        JourneyMonthGroup(title: label, journeys: byLabel[label]!),
    ];
  }
}
