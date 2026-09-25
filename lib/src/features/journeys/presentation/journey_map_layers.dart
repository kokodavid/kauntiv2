import 'dart:convert';

import 'package:flutter/material.dart';
// Mapbox exports its own `Size`; this file means Flutter's.
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Size;

import '../../../design/app_colors.dart';
import '../../map_home/application/county_camera_fit.dart';

/// A position on the map.
typedef JourneyLatLng = ({double latitude, double longitude});

/// A pin on the route: `start`, `end` or `moment` (a replay key moment).
typedef JourneyMapPin = ({String kind, JourneyLatLng at});

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

  /// Pins as a GeoJSON collection, each tagged with its `kind`.
  static String pinsJson(List<JourneyMapPin> pins) =>
      jsonEncode({'type': 'FeatureCollection', 'features': _points(pins)});

  /// The replay marker plus the short line from the last played point to
  /// it, so the drawn route reaches the marker between points. Both go in
  /// one source: one native update per frame.
  static String markerJson(JourneyLatLng? marker, {JourneyLatLng? tipFrom}) {
    if (marker == null) return emptyJson;
    return jsonEncode({
      'type': 'FeatureCollection',
      'features': [
        ..._points([(kind: 'marker', at: marker)]),
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

  static List<Map<String, Object>> _points(List<JourneyMapPin> pins) => [
    for (final (:kind, :at) in pins)
      {
        'type': 'Feature',
        'properties': {'kind': kind},
        'geometry': {
          'type': 'Point',
          'coordinates': [at.longitude, at.latitude],
        },
      },
  ];

  /// Keeps the Mapbox logo and attribution above an overlay covering the
  /// bottom [inset] of the map.
  static Future<void> liftOrnaments(MapboxMap map, double inset) async {
    if (inset <= 0) return;
    await map.logo.updateSettings(LogoSettings(marginBottom: inset + 8));
    await map.attribution.updateSettings(
      AttributionSettings(marginBottom: inset + 8),
    );
  }

  static List<Object> _is(String type) => [
    '==',
    ['geometry-type'],
    type,
  ];

  /// Adds every source and layer, bottom to top: faded route, played line,
  /// tip, lone-fix dots, pins (start, end, moments), marker.
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
          'end',
          hex(AppColors.danger),
          hex(AppColors.foreground),
        ],
        circleRadiusExpression: [
          'match',
          ['get', 'kind'],
          'moment',
          5,
          6,
        ],
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

  /// A camera framing [bounds] in a map [width] x [height] (the part not
  /// under overlays), with [padding] for those overlays.
  static CameraOptions frame(
    ({double south, double west, double north, double east}) bounds, {
    required double width,
    required double height,
    required MbxEdgeInsets padding,
  }) => CameraOptions(
    center: Point(
      coordinates: Position(
        (bounds.west + bounds.east) / 2,
        (bounds.south + bounds.north) / 2,
      ),
    ),
    zoom: CountyCameraFit.zoomToFit(
      (
        minLng: bounds.west,
        minLat: bounds.south,
        maxLng: bounds.east,
        maxLat: bounds.north,
      ),
      width: width,
      height: height,
      fill: 0.75,
      minZoom: 4,
      maxZoom: 16,
    ),
    padding: padding,
  );
}
