import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../../core/map/map_place_layers.dart';
import '../../../design/app_colors.dart';
import '../domain/map_home_models.dart';
import 'map_home_county_map_painter.dart';

/// Base styles the real map offers (style button). Terrain is the default;
/// satellite and 3D are candidates for Pro later.
enum RealMapBaseStyle {
  light('Light', MapboxStyles.LIGHT, 'assets/images/map_style_light.jpg'),
  outdoors(
    'Terrain',
    MapboxStyles.OUTDOORS,
    'assets/images/map_style_terrain.jpg',
  ),
  satellite(
    'Satellite',
    MapboxStyles.SATELLITE_STREETS,
    'assets/images/map_style_satellite.jpg',
  );

  const RealMapBaseStyle(this.label, this.uri, this.thumbnail);

  final String label;
  final String uri;

  /// A small picture of the style, for the style picker.
  final String thumbnail;
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

  static const demSourceId = 'mapbox-dem';
  static const skyLayerId = 'kaunti47-sky';

  /// Terrain height by zoom: dramatic across the country, gentler close up
  /// where a strong lift warps streets and pins. Flat (0) when 3D is off.
  static Object _exaggeration(bool enabled) => enabled
      ? [
          'interpolate',
          ['linear'],
          ['zoom'],
          5,
          1.6,
          10,
          1.3,
          14,
          1.0,
        ]
      : 0;

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
        'exaggeration': _exaggeration(enabled),
      }),
    );
    if (!await style.styleLayerExists(skyLayerId)) {
      await style.addLayer(
        SkyLayer(
          id: skyLayerId,
          skyType: SkyType.ATMOSPHERE,
          skyAtmosphereSunIntensity: 15,
          // A soft pale haze at the horizon when the camera is tilted.
          skyAtmosphereColor: const Color(0xFFE8EEF1).toARGB32(),
          skyAtmosphereHaloColor: const Color(0xFFBFD8EE).toARGB32(),
        ),
      );
    }
  }

  /// Flattens or raises the terrain without removing it (the Flutter SDK
  /// has no clean way to remove terrain once set).
  static Future<void> setTerrainEnabled(StyleManager style, bool enabled) =>
      style.setStyleTerrainProperty('exaggeration', _exaggeration(enabled));

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
    MapPlaceLayers.addTapHandler(map, onPlace);
  }

  /// Outlines only [badge]'s county; null outlines nothing.
  static Future<void> setHighlight(MapboxMap map, MapHomeCountyBadge? badge) =>
      map.style.setStyleLayerProperty(
        highlightLayerId,
        'filter',
        highlightFilter(badge?.county.code),
      );

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
