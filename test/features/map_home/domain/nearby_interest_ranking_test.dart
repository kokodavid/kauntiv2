import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/core/domain/map_place.dart';
import 'package:kaunti47_v2/src/counties/county_paths.dart';
import 'package:kaunti47_v2/src/features/map_home/domain/map_home_models.dart';
import 'package:kaunti47_v2/src/features/map_home/domain/map_home_nearby_cards.dart';
import 'package:kaunti47_v2/src/features/map_home/domain/map_home_nearby_places.dart';
import 'package:kaunti47_v2/src/features/profile/domain/place_interest.dart';

MapPlace _place(String id, String type, double lat) =>
    MapPlace(id: id, name: id, type: type, countyCode: 47, lat: lat, lng: 36.8);

void main() {
  const from = (latitude: 0.0, longitude: 36.8);

  test('a matching place edges ahead of a slightly nearer one', () {
    // ~10 km and ~14 km away: 14 * 0.6 = 8.4 beats 10.
    final places = [
      _place('near-museum', 'museum', 0.09),
      _place('farther-falls', 'waterfall', 0.126),
    ];
    PlaceInterest? water(String t) =>
        t == 'waterfall' ? PlaceInterest.water : null;
    final plain = MapHomeNearbyPlaces.nearest(
      places: places,
      from: from,
      claimedCountyCodes: const {},
    );
    final leaning = MapHomeNearbyPlaces.nearest(
      places: places,
      from: from,
      claimedCountyCodes: const {},
      interestFor: water,
    );
    expect(plain.first.place.id, 'near-museum');
    expect(leaning.first.place.id, 'farther-falls');
    expect(leaning.first.matchedInterest, PlaceInterest.water);
    expect(leaning.last.matchedInterest, isNull);
  });

  test('a far match does not jump a much nearer place', () {
    final result = MapHomeNearbyPlaces.nearest(
      places: [_place('a', 'museum', 0.02), _place('b', 'waterfall', 0.9)],
      from: from,
      claimedCountyCodes: const {},
      interestFor: (t) => t == 'waterfall' ? PlaceInterest.water : null,
    );
    expect(result.first.place.id, 'a');
  });

  test('cards say when something is picked for you', () {
    final matched = MapHomeNearbyPlace(
      place: _place('Chania Falls', 'waterfall', 0.1),
      county: CountyPaths.byCode[47]!,
      distanceMeters: 12000,
      countyClaimed: false,
      matchedInterest: PlaceInterest.water,
    );
    final county = MapHomeSuggestion(
      county: CountyPaths.byCode[47]!,
      reason: MapHomeSuggestionReason.unclaimed,
      distanceAway: '30 km away',
      isNear: true,
      matchedInterest: PlaceInterest.water,
      matchedPlaceName: 'Chania Falls',
    );
    final cards = MapHomeNearbyCards.build(
      unclaimed: [county],
      placeCounts: const {47: 3},
      places: [matched],
    );
    expect(cards.first.pill, 'For you · Waterfall');
    expect(cards.last.subtitle, 'Unclaimed · has Chania Falls');
  });
}
