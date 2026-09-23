import '../../../counties/county_paths.dart';
import '../domain/map_home_models.dart';

abstract interface class MapHomeRepository {
  Future<MapHomeBoardData> loadBoard({CountyPath? homeCounty});
}

class MockMapHomeRepository implements MapHomeRepository {
  const MockMapHomeRepository();

  static const _lockedSlugs = <String>{
    'bungoma',
    'busia',
    'garissa',
    'homa-bay',
    'isiolo',
    'kakamega',
    'kisii',
    'kisumu',
    'mandera',
    'migori',
    'nyamira',
    'siaya',
    'tana-river',
    'vihiga',
    'wajir',
    'west-pokot',
  };
  static const _passedThroughSlugs = <String>{'kitui', 'samburu'};
  static const _pendingSlugs = <String>{'marsabit'};
  static const _justUnlockedSlugs = <String>{'turkana'};

  @override
  Future<MapHomeBoardData> loadBoard({CountyPath? homeCounty}) async {
    final resolvedHomeCounty = homeCounty ?? CountyPaths.bySlug['nairobi'];
    return MapHomeBoardData(
      tierLabel: 'MZURURAJI',
      totalCounties: 47,
      homeCounty: resolvedHomeCounty,
      countyBadges: [
        for (final county in CountyPaths.all)
          MapHomeCountyBadge(
            county: county,
            state: _stateFor(county.slug),
            areaKm2: _factsBySlug[county.slug]?.$1,
            elevationM: _factsBySlug[county.slug]?.$2,
            durationMinutes: _factsBySlug[county.slug]?.$3,
          ),
      ],
      suggestions: [
        MapHomeSuggestion(
          county: CountyPaths.bySlug['nakuru']!,
          reason: MapHomeSuggestionReason.depthRank,
          distanceAway: '40 min away',
          isNear: true,
        ),
        MapHomeSuggestion(
          county: CountyPaths.bySlug['nyandarua']!,
          reason: MapHomeSuggestionReason.unclaimed,
          distanceAway: '2h 30m away',
          isNear: false,
        ),
        MapHomeSuggestion(
          county: CountyPaths.bySlug['turkana']!,
          reason: MapHomeSuggestionReason.savedHere,
          distanceAway: '3h 15m away',
          isNear: false,
          placeName: 'Central Island National Park',
          areaKm2: 5,
          elevationM: 375,
          visitDurationMinutes: 180,
          highlightImageUrl: null,
        ),
      ],
    );
  }

  static MapHomeCountyBadgeState _stateFor(String slug) {
    if (_justUnlockedSlugs.contains(slug)) {
      return MapHomeCountyBadgeState.justUnlocked;
    }
    if (_pendingSlugs.contains(slug)) return MapHomeCountyBadgeState.pending;
    if (_passedThroughSlugs.contains(slug)) {
      return MapHomeCountyBadgeState.passedThrough;
    }
    if (_lockedSlugs.contains(slug)) return MapHomeCountyBadgeState.locked;
    return MapHomeCountyBadgeState.earned;
  }

  static const _factsBySlug = <String, (num, num, int)>{
    'laikipia': (9723, 1800, 180),
    'nakuru': (7509, 1850, 240),
    'turkana': (68680, 610, 300),
  };
}
