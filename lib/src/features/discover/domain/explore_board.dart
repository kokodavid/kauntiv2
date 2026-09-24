import '../../../core/domain/app_stat_format.dart';
import '../../../counties/county_paths.dart';
import 'explore_lists.dart';
import 'place_category.dart';

/// Explore's three tabs (v1 Discover: MINE / UNCLAIMED / SAVED).
enum ExploreTab { mine, unclaimed, saved }

/// One place row in an Explore county card.
class ExplorePlace {
  const ExplorePlace({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.saved,
    this.seen = false,
    this.thumbnailUrl,
    this.distanceLabel,
  });

  final String id;
  final String title;
  final String description;
  final PlaceCategory category;
  final bool saved;

  /// SAVED only: ticked by hand as visited (`wishlist_items.ticked_at`).
  final bool seen;
  final String? thumbnailUrl;

  /// Straight-line "N km away" from the traveller's current fix; null
  /// when there's no fix or the place has no coordinates.
  final String? distanceLabel;

  bool matches(String needle) =>
      title.toLowerCase().contains(needle) ||
      description.toLowerCase().contains(needle);
}

/// A county's Area / Elevation / Duration, when on file.
typedef ExploreCountyFacts = ({
  num? areaKm2,
  num? elevationM,
  int? durationMinutes,
});

const ExploreCountyFacts noCountyFacts = (
  areaKm2: null,
  elevationM: null,
  durationMinutes: null,
);

/// The stats shown on a featured county card.
List<({String value, String label})> exploreCountyStats(
  ExploreCountyFacts facts,
) => AppStatFormat.stats(
  areaKm2: facts.areaKm2,
  elevationM: facts.elevationM,
  durationMinutes: facts.durationMinutes,
);

/// MINE's "JUST UNLOCKED" card: the most recently explored county.
class ExploreFeaturedUnlock {
  const ExploreFeaturedUnlock({
    required this.county,
    required this.rarityLabel,
    required this.previewPlaces,
    required this.totalPlaceCount,
    this.blurb = '',
    this.highlightImageUrl,
    this.facts = noCountyFacts,
  });

  final CountyPath county;
  final String rarityLabel;
  final List<ExplorePlace> previewPlaces;
  final int totalPlaceCount;

  /// "N places to see, including A and B."
  final String blurb;
  final String? highlightImageUrl;
  final ExploreCountyFacts facts;
}

/// One explored county in MINE, below the featured unlock.
class ExploreMineCounty {
  const ExploreMineCounty({
    required this.county,
    required this.statusLabel,
    required this.placeCount,
    required this.isLocalExpert,
    required this.previewPlaces,
  });

  final CountyPath county;

  /// "EXPLORED" or "LOCAL EXPERT · N VISITS".
  final String statusLabel;
  final int placeCount;
  final bool isLocalExpert;
  final List<ExplorePlace> previewPlaces;
}

/// Everything Explore renders, loaded together so chip counts always
/// match the lists underneath.
class ExploreBoard {
  const ExploreBoard({
    required this.featuredUnlock,
    required this.mine,
    this.unclaimed = const [],
    this.saved = const [],
  });

  final ExploreFeaturedUnlock? featuredUnlock;
  final List<ExploreMineCounty> mine;

  /// Nearest first; the first entry is the "closest one you don't have".
  final List<ExploreUnclaimedCounty> unclaimed;

  /// Most recently saved county first.
  final List<ExploreSavedGroup> saved;

  /// v1 parity: the featured county isn't counted in MINE's chip.
  int get mineCount => mine.length;
  int get unclaimedCount => unclaimed.length;

  /// SAVED counts places, not counties (v1 parity).
  int get savedCount =>
      saved.fold(0, (sum, group) => sum + group.places.length);

  bool get isEmpty =>
      featuredUnlock == null &&
      mine.isEmpty &&
      unclaimed.isEmpty &&
      saved.isEmpty;

  /// Narrows every tab to counties whose name, or any listed place,
  /// matches [query] (case-insensitive); UNCLAIMED also matches its
  /// blurb. A blank query returns this.
  ExploreBoard filtered(String query) {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return this;

    bool countyMatches(CountyPath county, List<ExplorePlace> places) =>
        county.name.toLowerCase().contains(needle) ||
        places.any((place) => place.matches(needle));

    final unlock = featuredUnlock;
    return ExploreBoard(
      featuredUnlock:
          unlock != null && countyMatches(unlock.county, unlock.previewPlaces)
          ? unlock
          : null,
      mine: [
        for (final entry in mine)
          if (countyMatches(entry.county, entry.previewPlaces)) entry,
      ],
      unclaimed: [
        for (final entry in unclaimed)
          if (countyMatches(entry.county, entry.previewPlaces) ||
              entry.blurb.toLowerCase().contains(needle))
            entry,
      ],
      saved: [
        for (final group in saved)
          if (countyMatches(group.county, group.places)) group,
      ],
    );
  }
}
