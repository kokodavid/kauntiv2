import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/map_home/application/place_geojson_builder.dart';
import 'package:kaunti47_v2/src/features/map_home/domain/map_place.dart';

void main() {
  test('a place with a thumbnail gets its own photo marker id', () {
    const place = MapPlace(
      id: 'p1',
      name: 'Lake Naivasha',
      type: 'shore',
      countyCode: 32,
      lat: -0.77,
      lng: 36.35,
      thumbnailUrl: 'https://example.test/naivasha.jpg',
    );
    expect(PlaceGeoJsonBuilder.markerIdFor(place), 'place-photo-p1');
  });

  test('builds one point feature per place in lng, lat order', () {
    final geoJson = PlaceGeoJsonBuilder.build(const [
      MapPlace(
        id: 'fort-jesus',
        name: 'Fort Jesus Museum',
        type: 'museum',
        countyCode: 1,
        lat: -4.071,
        lng: 39.682,
      ),
    ]);

    final features =
        (jsonDecode(geoJson) as Map<String, Object?>)['features']!
            as List<Object?>;
    final feature = features.single! as Map<String, Object?>;
    expect(feature['properties'], {
      'id': 'fort-jesus',
      'name': 'Fort Jesus Museum',
      'type': 'museum',
      'marker': 'place-type-museum',
      'hasPhoto': false,
    });
    expect((feature['geometry']! as Map<String, Object?>)['coordinates'], [
      39.682,
      -4.071,
    ]);
  });
}
