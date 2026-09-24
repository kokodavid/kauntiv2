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

  bool get isRare => percentHaveBeen != null && percentHaveBeen! <= 5;

  /// "ONLY 3% HAVE BEEN", "12% HAVE BEEN" or "RARITY NOT TRACKED YET".
  String get rarityLabel => switch (percentHaveBeen) {
    null => 'RARITY NOT TRACKED YET',
    final percent => '${isRare ? 'ONLY ' : ''}$percent% HAVE BEEN',
  };

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
      final label = expert ? 'LOCAL EXPERT' : 'BADGE EARNED';
      return (
        expert ? ExploreSavedStatus.localExpert : ExploreSavedStatus.badgeEarned,
        savedPlaces == 0
            ? '$label · NOTHING PICKED YET'
            : '$label · $stillToSee STILL TO SEE',
      );
    }
    if (savedPlaces > 0) {
      return (ExploreSavedStatus.locked, 'LOCKED · $savedPlaces SAVED');
    }
    return (ExploreSavedStatus.savedOnly, 'SAVED COUNTY · NOTHING PICKED YET');
  }
}
