import '../../../counties/county_paths.dart';
import 'explore_board.dart';

/// One county in UNCLAIMED: no explored visit yet.
class ExploreUnclaimedCounty {
  const ExploreUnclaimedCounty({
    required this.county,
    required this.blurb,
    required this.percentHaveBeen,
    required this.placeCount,
    this.distanceLabel,
    this.distanceMeters,
    this.previewPlaces = const [],
    this.isSavedAlone = false,
    this.highlightImageUrl,
    this.facts = noCountyFacts,
    this.headquarters,
  });

  final CountyPath county;

  /// "N places to see, including A and B."
  final String blurb;

  /// `counties.rarity_pct`, rounded; null until a rarity job runs.
  final int? percentHaveBeen;
  final int placeCount;

  /// Straight-line distance from the ranking anchor ("N km away").
  final String? distanceLabel;
  final num? distanceMeters;
  final List<ExplorePlace> previewPlaces;

  /// Saved as a county (a `wishlist_items` row with no place).
  final bool isSavedAlone;
  final String? highlightImageUrl;
  final ExploreCountyFacts facts;

  /// County headquarters town (`counties.capital`).
  final String? headquarters;

  bool get isRare => percentHaveBeen != null && percentHaveBeen! <= 5;

  /// "Only 3% have been", "12% have been" or "Rarity not tracked yet".
  String get rarityLabel => switch (percentHaveBeen) {
    null => 'Rarity not tracked yet',
    final percent =>
      isRare ? 'Only $percent% have been' : '$percent% have been',
  };

  /// The accordion's status line. Rarity when it's tracked; until then
  /// distance ("45 km away"), else the headquarters town ("HQ · Kerugoya").
  String get statusLine {
    if (percentHaveBeen != null) return rarityLabel;
    if (distanceLabel case final distance?) return distance;
    if (headquarters case final town?) return 'HQ · $town';
    return rarityLabel;
  }

  /// Nearest first; counties with no distance go last, in their
  /// original order.
  static List<ExploreUnclaimedCounty> nearestFirst(
    Iterable<ExploreUnclaimedCounty> entries,
  ) {
    final indexed = entries.indexed.toList()
      ..sort((a, b) {
        final da = a.$2.distanceMeters;
        final db = b.$2.distanceMeters;
        if (da == null && db == null) return a.$1.compareTo(b.$1);
        if (da == null) return 1;
        if (db == null) return -1;
        final byDistance = da.compareTo(db);
        return byDistance != 0 ? byDistance : a.$1.compareTo(b.$1);
      });
    return [for (final (_, entry) in indexed) entry];
  }
}

enum ExploreSavedStatus { locked, badgeEarned, localExpert, savedOnly }

/// One county in SAVED (the Wishlist), with its saved places.
class ExploreSavedGroup {
  const ExploreSavedGroup({
    required this.county,
    required this.status,
    required this.statusLabel,
    required this.places,
  });

  final CountyPath county;
  final ExploreSavedStatus status;
  final String statusLabel;
  final List<ExplorePlace> places;

  /// The status and its label (v1 parity). [rank] is the county's depth
  /// rank when explored, null when not.
  static (ExploreSavedStatus, String) statusFor({
    required String? rank,
    required int savedPlaces,
    required int stillToSee,
  }) {
    if (rank != null) {
      final expert = rank == 'local_expert';
      final label = expert ? 'Local expert' : 'Badge earned';
      return (
        expert
            ? ExploreSavedStatus.localExpert
            : ExploreSavedStatus.badgeEarned,
        savedPlaces == 0
            ? '$label · nothing picked yet'
            : '$label · $stillToSee still to see',
      );
    }
    if (savedPlaces > 0) {
      return (ExploreSavedStatus.locked, 'Locked · $savedPlaces saved');
    }
    return (ExploreSavedStatus.savedOnly, 'Saved county · nothing picked yet');
  }
}
