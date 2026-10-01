import 'dart:math' as math;

import 'badge_collection.dart';

/// A place to suggest for a county badge.
class BadgeSuggestedPlace {
  const BadgeSuggestedPlace({
    required this.id,
    required this.name,
    required this.type,
    this.summary,
    this.latitude,
    this.longitude,
    this.thumbnailUrl,
    this.saved = false,
  });

  final String id;
  final String name;
  final String type;
  final String? summary;
  final double? latitude;
  final double? longitude;
  final String? thumbnailUrl;
  final bool saved;

  /// Straight-line metres from ([latitude], [longitude]); null without
  /// coordinates.
  double? metersFrom(double fromLatitude, double fromLongitude) {
    final lat = latitude;
    final lng = longitude;
    if (lat == null || lng == null) return null;
    double rad(double degrees) => degrees * math.pi / 180;
    final dLat = rad(lat - fromLatitude);
    final dLng = rad(lng - fromLongitude);
    final h =
        math.pow(math.sin(dLat / 2), 2) +
        math.cos(rad(fromLatitude)) *
            math.cos(rad(lat)) *
            math.pow(math.sin(dLng / 2), 2);
    return 2 * 6371000 * math.asin(math.sqrt(h));
  }

  /// The [count] places nearest to the user when their position is known
  /// (farther and unplaced ones after), else the first [count] as given.
  static List<BadgeSuggestedPlace> nearest(
    List<BadgeSuggestedPlace> places, {
    ({double latitude, double longitude})? from,
    int count = 5,
  }) {
    if (from == null) return places.take(count).toList();
    double key(BadgeSuggestedPlace p) =>
        p.metersFrom(from.latitude, from.longitude) ?? double.infinity;
    final sorted = [...places]..sort((a, b) => key(a).compareTo(key(b)));
    return sorted.take(count).toList();
  }
}

/// One county's badge, in detail (`county_badge_detail`).
class CountyBadgeDetail {
  const CountyBadgeDetail({
    this.earnedAt,
    this.exploredVisits = 0,
    this.exploredMonths = 0,
    this.lastVisitedAt,
    this.journeys = 0,
    this.journeyMeters = 0,
    this.suggestedPlaces = const [],
  });

  /// When the county was first explored (the badge earned).
  final DateTime? earnedAt;

  /// Explored visits and the distinct months they fall in: depth counts
  /// both.
  final int exploredVisits;
  final int exploredMonths;

  /// The latest visit, explored or passed through.
  final DateTime? lastVisitedAt;

  /// Journeys whose route crossed the county, and how far they went in
  /// it (Journeys uploaded before counties were kept don't count).
  final int journeys;
  final double journeyMeters;

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
  static DepthStep? nextStep(
    CountyDepth current, {
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
