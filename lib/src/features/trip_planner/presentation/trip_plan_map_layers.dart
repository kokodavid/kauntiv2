import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Size;

import '../../../design/app_colors.dart';
import '../domain/trip_route.dart';

/// The Mapbox sources and layers of the planned road: the line, then the
/// pins (green start, numbered blue stops, red end) with a halo and a
/// bigger pin on the selected one.
abstract final class TripPlanMapLayers {
  static const routeSource = 'plan-route';
  static const markerSource = 'plan-markers';

  /// Start, each stop in driving order, then the end: the order markers are
  /// numbered and selected in. A single point is just the place.
  static List<TripRoutePoint> markers(
    List<TripRoutePoint> points,
    List<TripRoutePoint> stops,
  ) {
    if (points.isEmpty) return const [];
    if (points.length < 2) return [points.first];
    return [points.first, ...stops, points.last];
  }

  static String routeJson(List<TripRoutePoint> points) => jsonEncode({
    'type': 'Feature',
    'properties': <String, Object>{},
    'geometry': {
      'type': 'LineString',
      'coordinates': [
        for (final p in points) [p.lng, p.lat],
      ],
    },
  });

  static String markersJson(List<TripRoutePoint> markers, int? selected) {
    final last = markers.length - 1;
    return jsonEncode({
      'type': 'FeatureCollection',
      'features': [
        for (var i = 0; i < markers.length; i++)
          {
            'type': 'Feature',
            'properties': {
              'kind': markers.length == 1
                  ? 'end'
                  : i == 0
                  ? 'start'
                  : i == last
                  ? 'end'
                  : 'stop',
              'label': i == 0 || i == last ? '' : '$i',
              'selected': i == selected ? 1 : 0,
            },
            'geometry': {
              'type': 'Point',
              'coordinates': [markers[i].lng, markers[i].lat],
            },
          },
      ],
    });
  }

  static String _hex(Color color) =>
      '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

  static Future<void> add(
    MapboxMap map, {
    required String route,
    required String markers,
    required bool dashed,
    required bool hasRoute,
  }) async {
    final style = map.style;
    await style.addSource(GeoJsonSource(id: routeSource, data: route));
    await style.addSource(GeoJsonSource(id: markerSource, data: markers));
    if (hasRoute) {
      if (!dashed) {
        await style.addLayer(
          LineLayer(
            id: 'plan-route-casing',
            sourceId: routeSource,
            lineColor: Colors.white.toARGB32(),
            lineWidth: 9,
            lineCap: LineCap.ROUND,
            lineJoin: LineJoin.ROUND,
          ),
        );
      }
      await style.addLayer(
        LineLayer(
          id: 'plan-route-line',
          sourceId: routeSource,
          lineColor: (dashed ? AppColors.mutedForeground : AppColors.accent)
              .toARGB32(),
          lineWidth: dashed ? 3 : 5,
          lineDasharray: dashed ? [2, 2] : null,
          lineCap: dashed ? LineCap.BUTT : LineCap.ROUND,
          lineJoin: LineJoin.ROUND,
        ),
      );
    }
    await style.addLayer(
      CircleLayer(
        id: 'plan-marker-halo',
        sourceId: markerSource,
        filter: [
          '==',
          ['get', 'selected'],
          1,
        ],
        circleRadius: 23,
        circleColor: AppColors.accent.toARGB32(),
        circleOpacity: 0.25,
      ),
    );
    await style.addLayer(
      CircleLayer(
        id: 'plan-markers',
        sourceId: markerSource,
        circleColorExpression: [
          'match',
          ['get', 'kind'],
          'start',
          _hex(AppColors.legendHome),
          'stop',
          _hex(AppColors.accent),
          _hex(AppColors.danger),
        ],
        circleRadiusExpression: [
          'case',
          [
            '==',
            ['get', 'selected'],
            1,
          ],
          17,
          [
            '==',
            ['get', 'kind'],
            'stop',
          ],
          13,
          8,
        ],
        circleStrokeColor: Colors.white.toARGB32(),
        circleStrokeWidth: 2.5,
      ),
    );
    await style.addLayer(
      SymbolLayer(
        id: 'plan-stop-numbers',
        sourceId: markerSource,
        filter: [
          '==',
          ['get', 'kind'],
          'stop',
        ],
        textFieldExpression: ['get', 'label'],
        textSize: 13,
        textColor: Colors.white.toARGB32(),
        textAllowOverlap: true,
        textIgnorePlacement: true,
      ),
    );
  }
}
