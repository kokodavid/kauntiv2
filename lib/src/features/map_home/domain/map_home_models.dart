import '../../../counties/county_paths.dart';
import 'county_badge_state.dart';

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

  Iterable<String> get statLabels sync* {
    final area = areaKm2;
    if (area != null) yield '${area.toStringAsFixed(0)} km2';
    final elevation = elevationM;
    if (elevation != null) yield '${elevation}m';
    final duration = visitDurationMinutes;
    if (duration != null) yield '$duration min';
  }
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
