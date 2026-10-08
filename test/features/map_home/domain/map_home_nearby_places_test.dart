import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/core/domain/map_place.dart';
import 'package:kaunti47_v2/src/features/map_home/domain/map_home_nearby_places.dart';

MapPlace place(String id, double lat, double lng, {int county = 47}) =>
    MapPlace(
      id: id,
      name: id,
      type: 'park',
      countyCode: county,
      lat: lat,
      lng: lng,
    );

void main() {
  const nairobi = (latitude: -1.2921, longitude: 36.8219);

  test('distance is about right', () {
    // Nairobi to Nakuru is ~140 km as the crow flies.
    final m = MapHomeNearbyPlaces.distanceMeters(
      -1.2921,
      36.8219,
      -0.3031,
      36.0800,
    );
    expect(m / 1000, inInclusiveRange(125, 150));
  });

  test('nearest first, capped, claimed flag set', () {
    final result = MapHomeNearbyPlaces.nearest(
      places: [
        place('far', -0.3031, 36.0800, county: 32),
        place('near', -1.30, 36.83),
        place('mid', -1.20, 36.90),
      ],
      from: nairobi,
      claimedCountyCodes: {47},
      limit: 2,
    );
    expect(result.map((r) => r.place.id), ['near', 'mid']);
    expect(result.first.countyClaimed, isTrue);
  });

  test('places in an unknown county are skipped', () {
    final result = MapHomeNearbyPlaces.nearest(
      places: [place('x', -1.3, 36.8, county: 999)],
      from: nairobi,
      claimedCountyCodes: {},
    );
    expect(result, isEmpty);
  });

  test('labels', () {
    expect(MapHomeNearbyPlaces.distanceLabel(820), '800 m');
    expect(MapHomeNearbyPlaces.distanceLabel(4200), '4.2 km');
    expect(MapHomeNearbyPlaces.distanceLabel(66400), '66 km');
  });
}
