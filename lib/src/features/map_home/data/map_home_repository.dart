import '../../../counties/county_paths.dart';
import '../domain/map_home_models.dart';

class MockMapHomeRepository {
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

  MapHomeBoardData loadBoard({CountyPath? homeCounty}) {
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
          label: 'Depth rank nearby',
          distanceAway: '40 min away',
        ),
        MapHomeSuggestion(
          county: CountyPaths.bySlug['nyandarua']!,
          label: 'Unclaimed county',
          distanceAway: '2h 30m away',
        ),
        MapHomeSuggestion(
          county: CountyPaths.bySlug['turkana']!,
          label: 'Saved place here',
          distanceAway: '3h 15m away',
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
