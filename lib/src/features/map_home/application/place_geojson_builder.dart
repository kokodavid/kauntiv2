import 'dart:convert';

import '../domain/map_place.dart';

/// Places as a GeoJSON point collection for the Pro map's pin layers.
abstract final class PlaceGeoJsonBuilder {
  static String build(List<MapPlace> places) {
    return jsonEncode({
      'type': 'FeatureCollection',
      'features': [
        for (final place in places)
          {
            'type': 'Feature',
            'properties': {'id': place.id, 'name': place.name, 'type': place.type},
            'geometry': {
              'type': 'Point',
              'coordinates': [place.lng, place.lat],
            },
          },
      ],
    });
  }
}
