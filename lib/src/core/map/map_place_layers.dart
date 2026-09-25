import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import 'map_place_types.dart';

/// The place pins on a Mapbox map, shared by Home and Journeys: the
/// source, the dot and marker layers, and taps on them.
abstract final class MapPlaceLayers {
  static const placesSourceId = 'kaunti47-places';
  static const placeDotLayerId = 'kaunti47-places-dot';
  static const placeMarkerLayerId = 'kaunti47-places-marker';

  /// Zoom at which dots hand over to photo/badge markers.
  static const markerMinZoom = 6.0;

  /// Zoomed out: small dots coloured by type. From [markerMinZoom]: photo or
  /// badge markers (style images from `MapPlaceMarkers`) with the name
  /// underneath; overlapping markers hide, photos win over badges.
  static Future<void> addTo(StyleManager style, String geoJson) async {
    await style.addSource(GeoJsonSource(id: placesSourceId, data: geoJson));
    await style.addLayer(
      CircleLayer(
        id: placeDotLayerId,
        sourceId: placesSourceId,
        maxZoom: markerMinZoom,
        circleColorExpression: [
          'match',
          ['get', 'type'],
          for (final entry in MapPlaceTypes.known.entries) ...[
            entry.key,
            _hex(entry.value.$2),
          ],
          _hex(MapPlaceTypes.colorFor('')),
        ],
        circleRadius: 4,
        circleStrokeColor: Colors.white.toARGB32(),
        circleStrokeWidth: 1.5,
      ),
    );
    await style.addLayer(
      SymbolLayer(
        id: placeMarkerLayerId,
        sourceId: placesSourceId,
        minZoom: markerMinZoom,
        iconImageExpression: ['get', 'marker'],
        iconAnchor: IconAnchor.BOTTOM,
        iconSizeExpression: [
          'interpolate',
          ['linear'],
          ['zoom'],
          markerMinZoom,
          0.75,
          10,
          1.0,
        ],
        symbolSortKeyExpression: [
          'case',
          ['get', 'hasPhoto'],
          0,
          1,
        ],
        textFieldExpression: ['get', 'name'],
        textSize: 11,
        textAnchor: TextAnchor.TOP,
        textOffset: [0, 0.2],
        textOptional: true,
        textColor: const Color(0xFF22291F).toARGB32(),
        textHaloColor: Colors.white.toARGB32(),
        textHaloWidth: 1.2,
      ),
    );
  }

  /// Taps on a pin report its place `id`.
  static void addTapHandler(MapboxMap map, void Function(Object? id) onPlace) {
    for (final layerId in [placeDotLayerId, placeMarkerLayerId]) {
      map.addInteraction(
        TapInteraction(
          FeaturesetDescriptor(layerId: layerId),
          (feature, _) => onPlace(feature.properties['id']),
        ),
        interactionID: 'kaunti47-place-tap-$layerId',
      );
    }
  }

  static String _hex(Color color) {
    final rgb = color.toARGB32() & 0xFFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0')}';
  }
}
