import '../../../core/domain/app_stat_format.dart';
import '../../../counties/county_paths.dart';
import 'county_badge_state.dart';
import 'map_home_promotion.dart';

export 'county_badge_state.dart' show CountyBadgeStateLabel;

typedef MapHomeCountyBadgeState = CountyBadgeState;

class MapHomeCountyBadge {
  const MapHomeCountyBadge({
    required this.county,
    required this.state,
    this.areaKm2,
    this.elevationM,
    this.durationMinutes,
    this.highlightImageUrl,
    this.headquarters,
    this.placeNames = const [],
  });

  final CountyPath county;
  final MapHomeCountyBadgeState state;
  final num? areaKm2;
  final num? elevationM;
  final int? durationMinutes;

  /// For the county preview card (same content as Explore's cards).
  final String? highlightImageUrl;

  /// The county headquarters town (`counties.capital`).
  final String? headquarters;

  /// Places on file here, for the "N places to see" line.
  final List<String> placeNames;
}

class MapHomeSuggestion {
  const MapHomeSuggestion({
    required this.county,
    required this.reason,
    required this.distanceAway,
    required this.isNear,
    this.placeName,
    this.areaKm2,
    this.elevationM,
    this.visitDurationMinutes,
    this.highlightImageUrl,
  });

  final CountyPath county;
  final MapHomeSuggestionReason reason;
  final String distanceAway;
  final bool isNear;
  final String? placeName;
  final double? areaKm2;
  final int? elevationM;
  final int? visitDurationMinutes;
  final String? highlightImageUrl;

  String get title => placeName ?? county.name;

  String get reasonLabel {
    return switch (reason) {
      MapHomeSuggestionReason.depthRank => 'Depth rank nearby',
      MapHomeSuggestionReason.savedHere => 'Saved place here',
      MapHomeSuggestionReason.unclaimed => 'Unclaimed county',
    };
  }

  /// Area / Elevation / Duration that are on file, as (value, label).
  List<({String value, String label})> get stats => AppStatFormat.stats(
    areaKm2: areaKm2,
    elevationM: elevationM,
    durationMinutes: visitDurationMinutes,
  );

  /// What to hand a maps app for directions: the place when there is one,
  /// else the county.
  String get directionsQuery => placeName == null
      ? '${county.name} County, Kenya'
      : '$placeName, ${county.name} County, Kenya';
}

enum MapHomeSuggestionReason { depthRank, savedHere, unclaimed }

class MapHomeBoardData {
  const MapHomeBoardData({
    required this.tierLabel,
    required this.totalCounties,
    required this.countyBadges,
    required this.homeCounty,
    required this.suggestions,
    this.promotion,
    this.unclaimed = const [],
    this.unclaimedCount = 0,
  });

  final String tierLabel;
  final int totalCounties;
  final List<MapHomeCountyBadge> countyBadges;
  final CountyPath? homeCounty;
  final List<MapHomeSuggestion> suggestions;

  /// The active For You promotion, if any: it takes the top card.
  final MapHomePromotedPlace? promotion;

  /// Unclaimed counties, nearest first (only the first few are loaded).
  final List<MapHomeSuggestion> unclaimed;

  /// How many counties are still unclaimed in total ("All N left").
  final int unclaimedCount;

  /// The top card when nothing is promoted: a saved place or depth-rank
  /// pick first, else the nearest unclaimed county.
  MapHomeSuggestion? get fallbackTop =>
      suggestions
          .where((s) => s.reason != MapHomeSuggestionReason.unclaimed)
          .firstOrNull ??
      unclaimed.firstOrNull ??
      suggestions.firstOrNull;

  /// The most counties "Nearby and unclaimed" shows; "All N left" opens
  /// the rest in Explore.
  static const maxUnclaimedCards = 6;

  /// "Nearby and unclaimed": up to [maxUnclaimedCards], minus any county
  /// already on the top card.
  List<MapHomeSuggestion> get unclaimedRow {
    final top = promotion == null ? fallbackTop : null;
    return [
      for (final entry in unclaimed)
        if (top == null ||
            top.reason != MapHomeSuggestionReason.unclaimed ||
            entry.county.code != top.county.code)
          entry,
    ].take(maxUnclaimedCards).toList();
  }

  int get exploredCount => countyBadges
      .where((badge) => badge.state == MapHomeCountyBadgeState.earned)
      .length;
}
