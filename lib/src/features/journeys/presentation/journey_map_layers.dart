import 'dart:convert';

import 'package:flutter/material.dart';
// Mapbox exports its own `Size`; this file means Flutter's.
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Size;

import '../../../design/app_colors.dart';

/// A position on the map.
typedef JourneyLatLng = ({double latitude, double longitude});

/// The sources and layers a Journey map draws with, and the GeoJSON that
/// feeds them. Kept apart from the widget so the map stays about camera
/// and updates.
abstract final class JourneyMapLayers {
  static const routeSource = 'journey-route';
  static const markerSource = 'journey-marker';
  static const endpointSource = 'journey-endpoints';
  static const playedSource = 'journey-played';
  static const routeLine = 'journey-route-line';

  /// The full route fades while replay draws the played part over it.
  static const fadedOpacity = 0.3;

  static const _empty = {'type': 'FeatureCollection', 'features': <Object>[]};

  /// An empty GeoJSON collection (nothing to draw).
  static String get emptyJson => jsonEncode(_empty);

  /// Colours inside a style expression must be colour strings; a plain
  /// ARGB int is read as a number and rejected by Mapbox.
  static String hex(Color color) =>
      '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

  /// Points as a GeoJSON collection, each tagged with its `kind`.
  static String pointsJson(Map<String, JourneyLatLng?> points) =>
      jsonEncode({'type': 'FeatureCollection', 'features': _points(points)});

  /// The replay marker plus the short line from the last played point to
  /// it, so the drawn route reaches the marker between points. Both go in
  /// one source: one native update per frame.
  static String markerJson(JourneyLatLng? marker, {JourneyLatLng? tipFrom}) {
    if (marker == null) return emptyJson;
    return jsonEncode({
      'type': 'FeatureCollection',
      'features': [
        ..._points({'marker': marker}),
        if (tipFrom != null)
          {
            'type': 'Feature',
            'properties': {'kind': 'tip'},
            'geometry': {
              'type': 'LineString',
              'coordinates': [
                [tipFrom.longitude, tipFrom.latitude],
                [marker.longitude, marker.latitude],
              ],
            },
          },
      ],
    });
  }

  static List<Map<String, Object>> _points(
    Map<String, JourneyLatLng?> points,
  ) => [
    for (final MapEntry(key: kind, value: point) in points.entries)
      if (point != null)
        {
          'type': 'Feature',
          'properties': {'kind': kind},
          'geometry': {
            'type': 'Point',
            'coordinates': [point.longitude, point.latitude],
          },
        },
  ];

  static List<Object> _is(String type) => [
    '==',
    ['geometry-type'],
    type,
  ];

  /// Adds every source and layer, bottom to top: faded route, played line,
  /// tip, lone-fix dots, start / end pins, marker.
  static Future<void> add(
    StyleManager style, {
    required String route,
    required String played,
    required String marker,
    required String endpoints,
    required double routeOpacity,
  }) async {
    final accent = AppColors.accent.toARGB32();
    await style.addSource(GeoJsonSource(id: routeSource, data: route));
    await style.addSource(GeoJsonSource(id: playedSource, data: played));
    await style.addSource(GeoJsonSource(id: markerSource, data: marker));
    await style.addSource(GeoJsonSource(id: endpointSource, data: endpoints));
    for (final (id, source, opacity, filter) in [
      (routeLine, routeSource, routeOpacity, null),
      ('journey-played-line', playedSource, 1.0, null),
      ('journey-tip-line', markerSource, 1.0, _is('LineString')),
    ]) {
      await style.addLayer(
        LineLayer(
          id: id,
          sourceId: source,
          filter: filter,
          lineColor: accent,
          lineOpacity: opacity,
          lineWidth: 4.5,
          lineCap: LineCap.ROUND,
          lineJoin: LineJoin.ROUND,
        ),
      );
    }
    await style.addLayer(
      CircleLayer(
        id: 'journey-route-dots',
        sourceId: routeSource,
        filter: _is('Point'),
        circleColor: accent,
        circleRadius: 4,
      ),
    );
    await style.addLayer(
      CircleLayer(
        id: 'journey-endpoints',
        sourceId: endpointSource,
        circleColorExpression: [
          'match',
          ['get', 'kind'],
          'start',
          hex(AppColors.legendHome),
          hex(AppColors.danger),
        ],
        circleRadius: 6,
        circleStrokeColor: Colors.white.toARGB32(),
        circleStrokeWidth: 2,
      ),
    );
    await style.addLayer(
      CircleLayer(
        id: 'journey-marker',
        sourceId: markerSource,
        filter: _is('Point'),
        circleColor: Colors.white.toARGB32(),
        circleRadius: 7,
        circleStrokeColor: accent,
        circleStrokeWidth: 3,
      ),
    );
  }
}
