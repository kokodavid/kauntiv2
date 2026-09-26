import 'badge_collection.dart';

/// A place to suggest for a county badge.
class BadgeSuggestedPlace {
  const BadgeSuggestedPlace({
    required this.id,
    required this.name,
    required this.type,
  });

  final String id;
  final String name;
  final String type;
}

/// One county's badge, in detail (`county_badge_detail`).
class CountyBadgeDetail {
  const CountyBadgeDetail({
    this.earnedAt,
    this.exploredVisits = 0,
    this.exploredMonths = 0,
    this.savedPlaces = 0,
    this.savedVisited = 0,
    this.placesTotal = 0,
    this.placesVisited = 0,
    this.suggestedPlaces = const [],
  });

  /// When the county was first explored (the badge earned).
  final DateTime? earnedAt;

  /// Explored visits and the distinct months they fall in: depth counts
  /// both.
  final int exploredVisits;
  final int exploredMonths;

  /// Places the user saved here, and how many of them they've ticked.
  final int savedPlaces;
  final int savedVisited;

  /// Kaunti47 places in the county, and how many the user has ticked.
  final int placesTotal;
  final int placesVisited;

  final List<BadgeSuggestedPlace> suggestedPlaces;
}

/// What the next depth level needs.
class DepthStep {
  const DepthStep({
    required this.next,
    required this.visitsNeeded,
    required this.monthsNeeded,
  });

  final CountyDepth next;

  /// More explored visits in total, and more distinct months among them.
  /// One visit in a new month counts towards both.
  final int visitsNeeded;
  final int monthsNeeded;

  /// Visits still to make: enough for both counts.
  int get visitsToGo =>
      visitsNeeded > monthsNeeded ? visitsNeeded : monthsNeeded;
}

/// The depth ladder above "Visited" (docs 02; same thresholds as
/// `county_depth_ranks()`): Regular at 3+ explored visits across 3+
/// months, Local expert at 6+ across 5+.
abstract final class DepthLadder {
  static const regularVisits = 3;
  static const regularMonths = 3;
  static const expertVisits = 6;
  static const expertMonths = 5;

  /// Null when there's no next level from [current] (not yet earned, or
  /// already a local expert).
  static DepthStep? nextStep(CountyDepth current, {
    required int visits,
    required int months,
  }) {
    final (next, needVisits, needMonths) = switch (current) {
      CountyDepth.visited => (
        CountyDepth.regular,
        regularVisits,
        regularMonths,
      ),
      CountyDepth.regular => (
        CountyDepth.localExpert,
        expertVisits,
        expertMonths,
      ),
      _ => (null, 0, 0),
    };
    if (next == null) return null;
    return DepthStep(
      next: next,
      visitsNeeded: (needVisits - visits).clamp(0, needVisits),
      monthsNeeded: (needMonths - months).clamp(0, needMonths),
    );
  }
}
