import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/counties/county_paths.dart';
import 'package:kaunti47_v2/src/features/map_home/domain/map_home_compact.dart';
import 'package:kaunti47_v2/src/features/map_home/domain/map_home_layout.dart';
import 'package:kaunti47_v2/src/features/map_home/domain/map_home_models.dart';

MapHomeSuggestion _unclaimed(String slug, String distance) => MapHomeSuggestion(
  county: CountyPaths.bySlug[slug]!,
  reason: MapHomeSuggestionReason.unclaimed,
  distanceAway: distance,
  isNear: false,
);

MapHomeBoardData _board({
  int claimed = 12,
  String home = 'kiambu',
  List<MapHomeSuggestion> unclaimed = const [],
  List<MapHomeSuggestion> suggestions = const [],
}) {
  final earned = CountyPaths.all.take(claimed).toList();
  return MapHomeBoardData(
    tier: null,
    totalCounties: 47,
    homeCounty: CountyPaths.bySlug[home],
    countyBadges: [
      for (final county in CountyPaths.all)
        MapHomeCountyBadge(
          county: county,
          state: earned.contains(county)
              ? MapHomeCountyBadgeState.earned
              : MapHomeCountyBadgeState.locked,
        ),
    ],
    suggestions: suggestions,
    unclaimed: unclaimed,
    unclaimedCount: 47 - claimed,
  );
}

void main() {
  test('the progress line counts claimed and left, without a tier yet', () {
    expect(
      MapHomeCompact.progressLine(_board(claimed: 5)),
      '5 of 47 claimed · 42 to go',
    );
  });

  test('a recording Trip points at the nearest unclaimed county', () {
    final data = _board(
      unclaimed: [
        _unclaimed('nyandarua', '12 km away'),
        _unclaimed('laikipia', '60 km away'),
      ],
      suggestions: [
        MapHomeSuggestion(
          county: CountyPaths.bySlug['nakuru']!,
          reason: MapHomeSuggestionReason.depthRank,
          distanceAway: '40 km away',
          isNear: true,
        ),
      ],
    );
    final compact = MapHomeCompact.forLayout(MapHomeLayout.recording, data)!;
    expect(compact.context, 'NEAREST UNCLAIMED');
    expect(compact.title, 'Nyandarua · 12 km');
  });

  test('the standard layout leads with the top suggestion', () {
    final data = _board(
      unclaimed: [_unclaimed('nyandarua', '12 km away')],
      suggestions: [
        MapHomeSuggestion(
          county: CountyPaths.bySlug['nakuru']!,
          reason: MapHomeSuggestionReason.depthRank,
          distanceAway: '40 km away',
          isNear: true,
        ),
      ],
    );
    final compact = MapHomeCompact.forLayout(MapHomeLayout.standard, data)!;
    expect(compact.context, 'NEXT BEST MOVE');
    expect(compact.county.slug, 'nakuru');
  });

  test('a new user is asked to claim their home county', () {
    final data = _board(
      claimed: 0,
      unclaimed: [_unclaimed('kiambu', '18 km away')],
    );
    final compact = MapHomeCompact.forLayout(MapHomeLayout.newUser, data)!;
    expect(compact.context, 'START HERE');
    expect(compact.title, 'Claim Kiambu, your home county');
    expect(compact.isHomeStart, isTrue);
  });

  test('a new user whose home county is not in the list still gets a card', () {
    final data = _board(claimed: 0);
    final compact = MapHomeCompact.forLayout(MapHomeLayout.newUser, data)!;
    expect(compact.county.slug, 'kiambu');
    expect(compact.suggestion.distanceAway, 'Your home county');
  });

  test('nothing to point at gives no card', () {
    expect(MapHomeCompact.forLayout(MapHomeLayout.standard, _board()), isNull);
  });
}
