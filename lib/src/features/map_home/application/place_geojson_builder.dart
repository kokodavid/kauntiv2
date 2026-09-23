import 'dart:convert';

import '../domain/map_place.dart';

/// Places as a GeoJSON point collection for the real map's pin layers.
abstract final class PlaceGeoJsonBuilder {
  /// Style-image id of a place's map marker: its own photo marker, or the
  /// shared badge for its type when it has no photo.
  static String markerIdFor(MapPlace place) => place.thumbnailUrl != null
      ? 'place-photo-${place.id}'
      : typeMarkerId(place.type);

  static String typeMarkerId(String type) => 'place-type-$type';

  static String build(List<MapPlace> places) {
    return jsonEncode({
      'type': 'FeatureCollection',
      'features': [
        for (final place in places)
          {
            'type': 'Feature',
            'properties': {
              'id': place.id,
              'name': place.name,
              'type': place.type,
              'marker': markerIdFor(place),
              'hasPhoto': place.thumbnailUrl != null,
            },
            'geometry': {
              'type': 'Point',
              'coordinates': [place.lng, place.lat],
            },
          },
      ],
    });
  }
}
