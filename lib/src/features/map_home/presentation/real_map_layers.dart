import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../../design/app_colors.dart';
import '../domain/map_home_models.dart';
import 'map_home_county_map_painter.dart';
import 'real_map_place_widgets.dart';

/// Base styles the real map offers (style button). Terrain is the default;
/// satellite and 3D are candidates for Pro later.
enum RealMapBaseStyle {
  light('Light', MapboxStyles.LIGHT),
  outdoors('Terrain', MapboxStyles.OUTDOORS),
  satellite('Satellite', MapboxStyles.SATELLITE_STREETS);

  const RealMapBaseStyle(this.label, this.uri);

  final String label;
  final String uri;
}

/// Adds the county source and its layers to the current Mapbox style.
/// Called on every style load, since switching base style drops them.
abstract final class RealMapLayers {
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
        // Claimed counties get a bold border in their state colour, drawn
        // above the thin white edges of unclaimed neighbours.
        lineColorExpression: _stateColorExpression(),
        lineWidthExpression: [
          'match',
          ['get', 'state'],
          _locked,
          1,
          2.5,
        ],
        lineOpacityExpression: [
          'match',
          ['get', 'state'],
          _locked,
          0.6,
          0.95,
        ],
        lineSortKeyExpression: [
          'match',
          ['get', 'state'],
          _locked,
          0,
          1,
        ],
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
  static const placeMarkerLayerId = 'kaunti47-places-marker';

  /// Zoom at which dots hand over to photo/badge markers.
  static const markerMinZoom = 6.0;

  /// Zoomed out: small dots coloured by type. From [markerMinZoom]: photo or
  /// badge markers (style images from `RealMapPlaceMarkers`) with the name
  /// underneath; overlapping markers hide, photos win over badges.
  static Future<void> addPlacesTo(StyleManager style, String geoJson) async {
    await style.addSource(GeoJsonSource(id: placesSourceId, data: geoJson));
    await style.addLayer(
      CircleLayer(
        id: placeDotLayerId,
        sourceId: placesSourceId,
        maxZoom: markerMinZoom,
        circleColorExpression: [
          'match',
          ['get', 'type'],
          for (final entry in RealMapPlaceTypes.known.entries) ...[
            entry.key,
            _hex(entry.value.$2),
          ],
          _hex(RealMapPlaceTypes.colorFor('')),
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

  /// Taps on counties report their `code`, taps on pins their place `id`.
  static void addTapHandlers(
    MapboxMap map, {
    required void Function(Object? code) onCounty,
    required void Function(Object? id) onPlace,
  }) {
    map.addInteraction(
      TapInteraction(
        FeaturesetDescriptor(layerId: fillLayerId),
        (feature, _) => onCounty(feature.properties['code']),
      ),
      interactionID: 'kaunti47-county-tap',
    );
    // Added after the county tap so a pin wins over the county under it.
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

  /// Outline only the county with [code]; null outlines nothing.
  static List<Object> highlightFilter(int? code) => [
    '==',
    ['get', 'code'],
    code ?? -1,
  ];

  /// Same state colours as the drawn map ([MapHomeCountyStyle]).
  static final _locked = MapHomeCountyBadgeState.locked.name;

  /// "Fog of war" on real terrain: unclaimed counties are hazed grey,
  /// claimed ones stay clear with only a faint tint of their state colour,
  /// so explored land shows as vivid terrain inside a coloured border. (A
  /// solid blue fill read as water on the Mapbox base styles.)
  static List<Object> _fillColorExpression() => [
    'match',
    ['get', 'state'],
    _locked,
    _hex(AppColors.mapFog),
    _stateColorExpression(),
  ];

  static List<Object> _fillOpacityExpression() => [
    'match',
    ['get', 'state'],
    _locked,
    0.38,
    MapHomeCountyBadgeState.pending.name,
    0.04,
    0.08,
  ];

  /// Same state colours as the drawn map ([MapHomeCountyStyle]); unclaimed
  /// counties' white edges.
  static List<Object> _stateColorExpression() => [
    'match',
    ['get', 'state'],
    'home',
    _hex(
      MapHomeCountyStyle.forState(
        MapHomeCountyBadgeState.earned,
        isHome: true,
      ).fill,
    ),
    for (final state in MapHomeCountyBadgeState.values)
      if (state != MapHomeCountyBadgeState.locked) ...[
        state.name,
        _hex(MapHomeCountyStyle.forState(state).fill),
      ],
    '#FFFFFF',
  ];

  static String _hex(Color color) {
    final rgb = color.toARGB32() & 0xFFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0')}';
  }
}
