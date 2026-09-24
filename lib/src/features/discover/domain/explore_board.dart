import '../../../counties/county_paths.dart';
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
    this.thumbnailUrl,
    this.distanceLabel,
  });

  final String id;
  final String title;
  final String description;
  final PlaceCategory category;
  final bool saved;
  final String? thumbnailUrl;

  /// Straight-line "N km away" from the traveller's current fix; null
  /// when there's no fix or the place has no coordinates.
  final String? distanceLabel;

  bool matches(String needle) =>
      title.toLowerCase().contains(needle) ||
      description.toLowerCase().contains(needle);
}

/// MINE's "JUST UNLOCKED" card: the most recently explored county.
class ExploreFeaturedUnlock {
  const ExploreFeaturedUnlock({
    required this.county,
    required this.rarityLabel,
    required this.previewPlaces,
    required this.totalPlaceCount,
  });

  final CountyPath county;
  final String rarityLabel;
  final List<ExplorePlace> previewPlaces;
  final int totalPlaceCount;
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
/// match the lists underneath. UNCLAIMED and SAVED join in later slices.
class ExploreBoard {
  const ExploreBoard({required this.featuredUnlock, required this.mine});

  final ExploreFeaturedUnlock? featuredUnlock;
  final List<ExploreMineCounty> mine;

  /// v1 parity: the featured county isn't counted in MINE's chip.
  int get mineCount => mine.length;

  bool get isEmpty => featuredUnlock == null && mine.isEmpty;

  /// Narrows the board to counties whose name, or any preview place,
  /// matches [query] (case-insensitive). A blank query returns this.
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
    );
  }
}
