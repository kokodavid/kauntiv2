import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/core/domain/map_place.dart';
import 'package:kaunti47_v2/src/features/trip_planner/domain/nearby_places.dart';

MapPlace place(String id, double lat, double lng) => MapPlace(
  id: id,
  name: id,
  type: 'park',
  countyCode: 47,
  lat: lat,
  lng: lng,
);

void main() {
  test('nearest first, without the place itself or far ones', () {
    final result = NearbyPlaces.near(
      lat: -1.29,
      lng: 36.82,
      exceptId: 'self',
      places: [
        place('self', -1.29, 36.82),
        place('far', 5, 40),
        place('b', -1.30, 36.90),
        place('a', -1.295, 36.825),
      ],
    );
    expect(result.map((n) => n.place.id), ['a', 'b']);
  });

  test('is capped', () {
    final result = NearbyPlaces.near(
      lat: 0,
      lng: 0,
      exceptId: 'x',
      limit: 2,
      places: [for (var i = 1; i <= 5; i++) place('p$i', 0, i * 0.01)],
    );
    expect(result.length, 2);
  });

  test('labels', () {
    const m = NearbyPlace(
      place: MapPlace(
        id: 'a',
        name: 'a',
        type: 't',
        countyCode: 1,
        lat: 0,
        lng: 0,
      ),
      distanceMeters: 4200,
    );
    expect(m.distanceLabel, '4.2 km');
  });
}
