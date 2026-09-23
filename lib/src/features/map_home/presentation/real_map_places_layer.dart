import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../application/place_geojson_builder.dart';
import '../domain/map_place.dart';
import 'real_map_layers.dart';
import 'real_map_place_markers.dart';

/// Owns the real map's place pins for one screen: waits for the places to
/// load once, then adds their source, layers and marker images to every
/// style that loads, and resolves tapped pins back to places.
class RealMapPlacesLayer {
  RealMapPlacesLayer(this._places);

  final Future<List<MapPlace>>? _places;
  final _markers = RealMapPlaceMarkers();
  Map<String, MapPlace> _byId = const {};

  bool get isEnabled => _places != null;

  MapPlace? placeFor(Object? id) => _byId[id];

  /// Adds the pins to [style]. Returns false if the places failed to load.
  Future<bool> addTo(StyleManager style) async {
    final pending = _places;
    if (pending == null) return true;
    final List<MapPlace> places;
    try {
      places = await pending;
    } on Object {
      return false;
    }
    _byId = {for (final place in places) place.id: place};
    await RealMapLayers.addPlacesTo(style, PlaceGeoJsonBuilder.build(places));
    await _markers.addTo(style, places);
    return true;
  }
}
