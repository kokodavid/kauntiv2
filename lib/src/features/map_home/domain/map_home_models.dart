import '../../../counties/county_paths.dart';
import 'county_badge_state.dart';
import 'map_home_stat_format.dart';

typedef MapHomeCountyBadgeState = CountyBadgeState;

class MapHomeCountyBadge {
  const MapHomeCountyBadge({
    required this.county,
    required this.state,
    this.areaKm2,
    this.elevationM,
    this.durationMinutes,
  });

  final CountyPath county;
  final MapHomeCountyBadgeState state;
  final num? areaKm2;
  final num? elevationM;
  final int? durationMinutes;
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
  List<({String value, String label})> get stats => [
    if (areaKm2 case final area?)
      (value: MapHomeStatFormat.area(area), label: 'Area'),
    if (elevationM case final elevation?)
      (value: MapHomeStatFormat.elevation(elevation), label: 'Elevation'),
    if (visitDurationMinutes case final minutes?)
      (value: MapHomeStatFormat.duration(minutes), label: 'Duration'),
  ];

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
  });

  final String tierLabel;
  final int totalCounties;
  final List<MapHomeCountyBadge> countyBadges;
  final CountyPath? homeCounty;
  final List<MapHomeSuggestion> suggestions;

  int get exploredCount => countyBadges
      .where((badge) => badge.state == MapHomeCountyBadgeState.earned)
      .length;
}
