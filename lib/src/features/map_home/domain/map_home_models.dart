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
    required this.label,
    required this.distanceAway,
  });

  final CountyPath county;
  final String label;
  final String distanceAway;
}

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
