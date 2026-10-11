import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/core/domain/map_place.dart';
import 'package:kaunti47_v2/src/counties/county_paths.dart';
import 'package:kaunti47_v2/src/features/map_home/domain/map_home_models.dart';
import 'package:kaunti47_v2/src/features/map_home/domain/map_home_nearby_cards.dart';
import 'package:kaunti47_v2/src/features/map_home/domain/map_home_nearby_places.dart';

MapHomeSuggestion county(int code, String away) => MapHomeSuggestion(
  county: CountyPaths.byCode[code]!,
  reason: MapHomeSuggestionReason.unclaimed,
  distanceAway: away,
  isNear: true,
);

MapHomeNearbyPlace place(String id, double meters) => MapHomeNearbyPlace(
  place: MapPlace(
    id: id,
    name: id,
    type: 'waterfall',
    countyCode: 47,
    lat: 0,
    lng: 0,
  ),
  county: CountyPaths.byCode[47]!,
  distanceMeters: meters,
  countyClaimed: true,
);

void main() {
  test('distance labels split into a value and a unit', () {
    expect(MapHomeNearbyCards.splitDistance('66 km away')!.value, '66');
    expect(MapHomeNearbyCards.splitDistance('4.2 km')!.unit, 'km');
    expect(MapHomeNearbyCards.splitDistance('800 m')!.unit, 'm');
    expect(MapHomeNearbyCards.splitDistance('Nearby'), isNull);
  });

  test('counties alone make cards before places load', () {
    final cards = MapHomeNearbyCards.build(
      unclaimed: [county(32, '31 km away'), county(1, '90 km away')],
      placeCounts: {32: 9},
    );
    expect(cards.map((c) => c.kind), everyElement(MapHomeNearbyKind.newCounty));
    expect(cards.first.subtitle, 'Unclaimed · 9 places');
    expect(cards.last.subtitle, 'Unclaimed');
  });

  test('places and counties alternate, capped', () {
    final cards = MapHomeNearbyCards.build(
      unclaimed: [
        for (final c in [32, 1, 2, 3, 4]) county(c, '10 km away'),
      ],
      placeCounts: const {},
      places: [place('a', 900), place('b', 5000), place('c', 9000)],
    );
    expect(cards.length, MapHomeNearbyCards.maxCards);
    expect(cards[0].kind, MapHomeNearbyKind.place);
    expect(cards[1].kind, MapHomeNearbyKind.newCounty);
    expect(cards[0].pill, 'Waterfall');
    expect(cards[0].distanceUnit, 'm');
  });
}
