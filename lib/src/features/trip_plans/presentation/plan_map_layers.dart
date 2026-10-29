import 'dart:convert';

import 'package:flutter/painting.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Size;

import '../domain/plan_route.dart';
import 'plan_day_colors.dart';

/// The plan map's Mapbox sources and layers: each day's road in its colour
/// (dashed grey-ish when only a straight estimate is known) with a white
/// casing, and each day's stops as numbered pins. The chosen day is solid,
/// the others fade back.
abstract final class PlanMapLayers {
  static const lineSource = 'plan-day-lines';
  static const pinSource = 'plan-day-pins';

  static String _hex(Color color) =>
      '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

  static String linesJson(List<PlanMapDay> days, int? active) => jsonEncode({
    'type': 'FeatureCollection',
    'features': [
      for (final day in days)
        if (day.line.length > 1)
          {
            'type': 'Feature',
            'properties': {
              'color': _hex(PlanDayColors.of(day.number)),
              'dashed': day.estimated ? 1 : 0,
              'active': active == null || active == day.number ? 1 : 0,
            },
            'geometry': {
              'type': 'LineString',
              'coordinates': [
                for (final p in day.line) [p.lng, p.lat],
              ],
            },
          },
    ],
  });

  static String pinsJson(List<PlanMapDay> days, int? active) {
    final several = days.length > 1;
    return jsonEncode({
      'type': 'FeatureCollection',
      'features': [
        for (final day in days)
          for (var i = 0; i < day.stops.length; i++)
            {
              'type': 'Feature',
              'properties': {
                'color': _hex(PlanDayColors.of(day.number)),
                'label': several ? '${day.number}.${i + 1}' : '${i + 1}',
                'active': active == null || active == day.number ? 1 : 0,
              },
              'geometry': {
                'type': 'Point',
                'coordinates': [day.stops[i].lng, day.stops[i].lat],
              },
            },
      ],
    });
  }

  static Future<void> add(
    MapboxMap map, {
    required String lines,
    required String pins,
  }) async {
    final style = map.style;
    await style.addSource(GeoJsonSource(id: lineSource, data: lines));
    await style.addSource(GeoJsonSource(id: pinSource, data: pins));
    const white = 0xFFFFFFFF;
    final fade = [
      'case',
      [
        '==',
        ['get', 'active'],
        1,
      ],
      1.0,
      0.35,
    ];
    await style.addLayer(
      LineLayer(
        id: 'plan-line-casing',
        sourceId: lineSource,
        filter: [
          '==',
          ['get', 'dashed'],
          0,
        ],
        lineColor: white,
        lineWidth: 8,
        lineOpacityExpression: fade,
        lineCap: LineCap.ROUND,
        lineJoin: LineJoin.ROUND,
      ),
    );
    await style.addLayer(
      LineLayer(
        id: 'plan-line',
        sourceId: lineSource,
        filter: [
          '==',
          ['get', 'dashed'],
          0,
        ],
        lineColorExpression: ['get', 'color'],
        lineWidth: 5,
        lineOpacityExpression: fade,
        lineCap: LineCap.ROUND,
        lineJoin: LineJoin.ROUND,
      ),
    );
    await style.addLayer(
      LineLayer(
        id: 'plan-line-estimate',
        sourceId: lineSource,
        filter: [
          '==',
          ['get', 'dashed'],
          1,
        ],
        lineColorExpression: ['get', 'color'],
        lineWidth: 3,
        lineDasharray: [2, 2],
        lineOpacityExpression: fade,
        lineJoin: LineJoin.ROUND,
      ),
    );
    await style.addLayer(
      CircleLayer(
        id: 'plan-pins',
        sourceId: pinSource,
        circleColorExpression: ['get', 'color'],
        circleRadius: 13,
        circleOpacityExpression: fade,
        circleStrokeColor: white,
        circleStrokeWidth: 2.5,
      ),
    );
    await style.addLayer(
      SymbolLayer(
        id: 'plan-pin-numbers',
        sourceId: pinSource,
        textFieldExpression: ['get', 'label'],
        textSize: 11,
        textColor: white,
        textAllowOverlap: true,
        textIgnorePlacement: true,
      ),
    );
  }
}
