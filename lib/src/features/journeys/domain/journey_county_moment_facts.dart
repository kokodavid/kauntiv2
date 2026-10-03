import '../../badges/domain/badge_collection.dart';

/// What the "Entered county" timeline card needs about one crossing:
/// static facts about the county - never guessed, a fact simply missing
/// from Supabase is left off rather than shown as a placeholder, this
/// app's established rule everywhere else these facts appear - plus the
/// traveller's own current standing there.
class JourneyCountyMomentFacts {
  const JourneyCountyMomentFacts({
    this.capital,
    this.population,
    this.rarityPct,
    this.highlightImageUrl,
    this.placesCount = 0,
    this.firstPlaceThumbnailUrl,
    this.depth = CountyDepth.none,
    this.passCount = 1,
  });

  final String? capital;
  final int? population;
  final num? rarityPct;
  final String? highlightImageUrl;
  final int placesCount;
  final String? firstPlaceThumbnailUrl;
  final CountyDepth depth;

  /// Visits on file right now, including any since this Trip - a present-
  /// day snapshot, not what the count was the moment this past Trip
  /// happened. [isFirstVisit] is only exact for a county never visited
  /// again since.
  final int passCount;

  bool get isFirstVisit => passCount <= 1;

  /// The synced highlight photo, or the first synced place's thumbnail
  /// when there isn't one; null means the card falls back to a flat fill.
  String? get heroImageUrl => highlightImageUrl ?? firstPlaceThumbnailUrl;

  bool get hasPhoto => heroImageUrl != null;

  /// The single fact line the card shows, in priority order: capital +
  /// population, else capital + rarity, else whichever one fact is on
  /// file. Null hides the fact row entirely rather than showing a dash.
  String? get factLine {
    final cap = capital;
    if (cap != null && population != null) {
      return 'Capital $cap · ${_compactPopulation(population!)} people';
    }
    if (cap != null && rarityPct != null) {
      return 'Capital $cap · ${rarityPct!.round()}% of travellers have '
          'been here';
    }
    if (cap != null) return 'Capital $cap';
    if (population != null) return '${_compactPopulation(population!)} people';
    if (rarityPct != null) {
      return '${rarityPct!.round()}% of travellers have been here';
    }
    return null;
  }

  String get placesLabel =>
      placesCount > 0 ? '$placesCount place${placesCount == 1 ? '' : 's'}' : '';

  static String _compactPopulation(int value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).round()}K';
    return '$value';
  }
}
