import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../domain/map_home_models.dart';
import 'map_home_county_map_painter.dart';
import 'pro_map_place_widgets.dart';

/// Base styles offered in the Pro map spike, so they can be compared on a
/// device.
enum ProMapBaseStyle {
  light('Light', MapboxStyles.LIGHT),
  outdoors('Terrain', MapboxStyles.OUTDOORS),
  satellite('Satellite', MapboxStyles.SATELLITE_STREETS);

  const ProMapBaseStyle(this.label, this.uri);

  final String label;
  final String uri;
}

/// Adds the county source and its layers to the current Mapbox style.
/// Called on every style load, since switching base style drops them.
abstract final class ProMapLayers {
  static const sourceId = 'kaunti47-counties';
  static const fillLayerId = 'kaunti47-counties-fill';
  static const outlineLayerId = 'kaunti47-counties-outline';
  static const highlightLayerId = 'kaunti47-counties-highlight';

  static Future<void> addTo(StyleManager style, String geoJson) async {
    await style.addSource(GeoJsonSource(id: sourceId, data: geoJson));
    await style.addLayer(
      FillLayer(
        id: fillLayerId,
        sourceId: sourceId,
        fillColorExpression: _fillColorExpression(),
        fillOpacityExpression: _fillOpacityExpression(),
      ),
    );
    await style.addLayer(
      LineLayer(
        id: outlineLayerId,
        sourceId: sourceId,
        lineColor: Colors.white.toARGB32(),
        lineWidth: 1,
        lineOpacity: 0.9,
      ),
    );
    await style.addLayer(
      LineLayer(
        id: highlightLayerId,
        sourceId: sourceId,
        lineColor: const Color(0xFF22291F).toARGB32(),
        lineWidth: 2.5,
        filter: highlightFilter(null),
      ),
    );
  }

  static const placesSourceId = 'kaunti47-places';
  static const placeDotLayerId = 'kaunti47-places-dot';
  static const placeLabelLayerId = 'kaunti47-places-label';

  /// Place pins coloured by type, growing with zoom; names from zoom 7.
  static Future<void> addPlacesTo(StyleManager style, String geoJson) async {
    await style.addSource(GeoJsonSource(id: placesSourceId, data: geoJson));
    await style.addLayer(
      CircleLayer(
        id: placeDotLayerId,
        sourceId: placesSourceId,
        circleColorExpression: [
          'match',
          ['get', 'type'],
          for (final entry in ProMapPlaceTypes.known.entries) ...[
            entry.key,
            _hex(entry.value.$2),
          ],
          _hex(ProMapPlaceTypes.colorFor('')),
        ],
        circleRadiusExpression: [
          'interpolate',
          ['linear'],
          ['zoom'],
          5,
          3.5,
          9,
          7,
          12,
          9,
        ],
        circleStrokeColor: Colors.white.toARGB32(),
        circleStrokeWidth: 1.5,
      ),
    );
    await style.addLayer(
      SymbolLayer(
        id: placeLabelLayerId,
        sourceId: placesSourceId,
        minZoom: 7,
        textFieldExpression: ['get', 'name'],
        textSize: 11,
        textOffset: [0, 1.1],
        textAnchor: TextAnchor.TOP,
        textOptional: true,
        textColor: const Color(0xFF22291F).toARGB32(),
        textHaloColor: Colors.white.toARGB32(),
        textHaloWidth: 1.2,
      ),
    );
  }

  static const demSourceId = 'mapbox-dem';
  static const skyLayerId = 'kaunti47-sky';
  static const terrainExaggeration = 1.5;

  /// Mapbox terrain elevation under the whole style, plus an atmosphere
  /// sky for when the camera is tilted. Fill and line layers drape over it.
  static Future<void> addTerrainTo(
    StyleManager style, {
    required bool enabled,
  }) async {
    if (!await style.styleSourceExists(demSourceId)) {
      await style.addSource(
        RasterDemSource(
          id: demSourceId,
          url: 'mapbox://mapbox.mapbox-terrain-dem-v1',
          tileSize: 514,
          maxzoom: 14,
        ),
      );
    }
    await style.setStyleTerrain(
      jsonEncode({
        'source': demSourceId,
        'exaggeration': enabled ? terrainExaggeration : 0,
      }),
    );
    if (!await style.styleLayerExists(skyLayerId)) {
      await style.addLayer(
        SkyLayer(
          id: skyLayerId,
          skyType: SkyType.ATMOSPHERE,
          skyAtmosphereSunIntensity: 15,
        ),
      );
    }
  }

  /// Flattens or raises the terrain without removing it (the Flutter SDK
  /// has no clean way to remove terrain once set).
  static Future<void> setTerrainEnabled(StyleManager style, bool enabled) =>
      style.setStyleTerrainProperty(
        'exaggeration',
        enabled ? terrainExaggeration : 0,
      );

  /// Outline only the county with [code]; null outlines nothing.
  static List<Object> highlightFilter(int? code) => [
    '==',
    ['get', 'code'],
    code ?? -1,
  ];

  /// Same state colours as the drawn map ([MapHomeCountyStyle]).
  static List<Object> _fillColorExpression() => [
    'match',
    ['get', 'state'],
    'home',
    _hex(
      MapHomeCountyStyle.forState(
        MapHomeCountyBadgeState.earned,
        isHome: true,
      ).fill,
    ),
    for (final state in MapHomeCountyBadgeState.values) ...[
      state.name,
      _hex(MapHomeCountyStyle.forState(state).fill),
    ],
    '#FFFFFF',
  ];

  /// Unclaimed counties stay nearly clear so the real terrain shows; the
  /// rest are tinted enough to read over satellite imagery.
  static List<Object> _fillOpacityExpression() => [
    'match',
    ['get', 'state'],
    MapHomeCountyBadgeState.locked.name,
    0.08,
    MapHomeCountyBadgeState.pending.name,
    0.35,
    0.55,
  ];

  static String _hex(Color color) {
    final rgb = color.toARGB32() & 0xFFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0')}';
  }
}
