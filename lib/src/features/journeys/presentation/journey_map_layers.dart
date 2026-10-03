import 'dart:convert';

import 'package:flutter/material.dart';
// Mapbox exports its own `Size`; this file means Flutter's.
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Size;

import '../../../design/app_colors.dart';
import '../../map_home/application/county_camera_fit.dart';
import 'journey_map_types.dart';

export 'journey_map_types.dart';

/// The sources and layers a Journey map draws with, and the GeoJSON that
/// feeds them. Kept apart from the widget so the map stays about camera
/// and updates.
abstract final class JourneyMapLayers {
  static const routeSource = 'journey-route';
  static const markerSource = 'journey-marker';
  static const endpointSource = 'journey-endpoints';
  static const playedSource = 'journey-played';
  static const routeLine = 'journey-route-line';

  static const _empty = {'type': 'FeatureCollection', 'features': <Object>[]};

  /// An empty GeoJSON collection (nothing to draw).
  static String get emptyJson => jsonEncode(_empty);

  /// Colours inside a style expression must be colour strings; a plain
  /// ARGB int is read as a number and rejected by Mapbox.
  static String hex(Color color) =>
      '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

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

  /// `start`/`end` plus every key moment, each tagged with a `kind` the
  /// endpoints layer's colour/size `match` expressions key off: `start`,
  /// `end`, or `moment-photo`/`moment-note` combined with `-pending` /
  /// `-passed` depending on whether [currentIndex] (the replay playhead;
  /// null, or a Trip not yet played past a moment's point, both read as
  /// "not passed yet") has reached that moment's own [JourneyMapMoment.index].
  static String endpointsJson({
    JourneyLatLng? start,
    JourneyLatLng? end,
    List<JourneyMapMoment> moments = const [],
    int? currentIndex,
  }) {
    String kindOf(JourneyMapMoment moment) {
      final passed = currentIndex != null && moment.index <= currentIndex;
      final shape = moment.kind == JourneyMapMomentKind.photo
          ? 'moment-photo'
          : 'moment-note';
      return '$shape-${passed ? 'passed' : 'pending'}';
    }

    return jsonEncode({
      'type': 'FeatureCollection',
      'features': [
        for (final moment in moments)
          {
            'type': 'Feature',
            'properties': {'kind': kindOf(moment)},
            'geometry': {
              'type': 'Point',
              'coordinates': [moment.at.longitude, moment.at.latitude],
            },
          },
        if (start != null)
          {
            'type': 'Feature',
            'properties': {'kind': 'start'},
            'geometry': {
              'type': 'Point',
              'coordinates': [start.longitude, start.latitude],
            },
          },
        if (end != null)
          {
            'type': 'Feature',
            'properties': {'kind': 'end'},
            'geometry': {
              'type': 'Point',
              'coordinates': [end.longitude, end.latitude],
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

  /// Adds every source and layer, bottom to top: the route ahead (light
  /// blue), the played line and tip (accent), lone-fix dots, pins (start,
  /// end, moments), the marker's soft halo, then the marker itself.
  static Future<void> add(
    StyleManager style, {
    required String route,
    required String played,
    required String marker,
    required String endpoints,
  }) async {
    final accent = AppColors.accent.toARGB32();
    final upcoming = AppColors.routeUpcoming.toARGB32();
    await style.addSource(GeoJsonSource(id: routeSource, data: route));
    await style.addSource(GeoJsonSource(id: playedSource, data: played));
    await style.addSource(GeoJsonSource(id: markerSource, data: marker));
    await style.addSource(GeoJsonSource(id: endpointSource, data: endpoints));
    for (final (id, source, color, filter) in [
      (routeLine, routeSource, upcoming, null),
      ('journey-played-line', playedSource, accent, null),
      ('journey-tip-line', markerSource, accent, _is('LineString')),
    ]) {
      await style.addLayer(
        LineLayer(
          id: id,
          sourceId: source,
          filter: filter,
          lineColor: color,
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
        circleColor: upcoming,
        circleRadius: 4,
      ),
    );
    // Start/end/moment colour key (Claude-Design reference): start is
    // solid accent blue, end near-black, both white-ringed - unchanged
    // regardless of replay state. A moment is white with a blue outline
    // until the playhead passes it, then flips to solid blue with a
    // white outline; photo moments draw a touch larger than note ones.
    // circleStrokeColor alone can't do the pending/passed swap (start
    // and "passed" both want a white ring, but "pending" wants a blue
    // one), so the ring colour needs its own match expression too.
    await style.addLayer(
      CircleLayer(
        id: 'journey-endpoints',
        sourceId: endpointSource,
        circleColorExpression: [
          'match',
          ['get', 'kind'],
          'start',
          hex(AppColors.accent),
          'end',
          hex(AppColors.foreground),
          'moment-photo-passed',
          hex(AppColors.accent),
          'moment-note-passed',
          hex(AppColors.accent),
          hex(Colors.white),
        ],
        circleStrokeColorExpression: [
          'match',
          ['get', 'kind'],
          'moment-photo-pending',
          hex(AppColors.accent),
          'moment-note-pending',
          hex(AppColors.accent),
          hex(Colors.white),
        ],
        circleRadiusExpression: [
          'match',
          ['get', 'kind'],
          'moment-photo-pending',
          6,
          'moment-photo-passed',
          6,
          'moment-note-pending',
          4.5,
          'moment-note-passed',
          4.5,
          6,
        ],
        circleStrokeWidth: 2,
      ),
    );
    // A soft halo behind the marker - a solid dot with a faint blue glow,
    // not a white-centred ring (Claude-Design colour key: "a blue dot
    // with a white ring and a faint blue halo at 18% opacity").
    await style.addLayer(
      CircleLayer(
        id: 'journey-marker-halo',
        sourceId: markerSource,
        filter: _is('Point'),
        circleColor: accent,
        circleOpacity: 0.18,
        circleRadius: 14,
      ),
    );
    await style.addLayer(
      CircleLayer(
        id: 'journey-marker',
        sourceId: markerSource,
        filter: _is('Point'),
        circleColor: accent,
        circleRadius: 7,
        circleStrokeColor: Colors.white.toARGB32(),
        circleStrokeWidth: 2,
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
