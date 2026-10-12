import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../domain/county_shape.dart';
import '../domain/trip_route.dart';

/// The county boundaries bundled with the app
/// (`assets/geo/kenya_counties.geojson`), as shapes for the route check.
class CountyShapesSource {
  const CountyShapesSource({this.loadText = _fromAssets});

  final Future<String> Function() loadText;

  static Future<String> _fromAssets() =>
      rootBundle.loadString('assets/geo/kenya_counties.geojson');

  Future<List<CountyShape>> load() async => parse(await loadText());

  static List<CountyShape> parse(String geoJson) {
    final collection = jsonDecode(geoJson) as Map<String, Object?>;
    final shapes = <CountyShape>[];
    for (final raw in collection['features']! as List<Object?>) {
      final feature = raw! as Map<String, Object?>;
      final code =
          ((feature['properties']! as Map<String, Object?>)['code']! as num)
              .toInt();
      final geometry = feature['geometry']! as Map<String, Object?>;
      final coordinates = geometry['coordinates']! as List<Object?>;
      final polygons = switch (geometry['type']) {
        'Polygon' => [_polygon(coordinates)],
        'MultiPolygon' => [
          for (final polygon in coordinates)
            _polygon(polygon! as List<Object?>),
        ],
        _ => <CountyPolygon>[],
      };
      shapes.add(CountyShape(code: code, polygons: polygons));
    }
    return shapes;
  }

  static CountyPolygon _polygon(List<Object?> rings) {
    final parsed = [for (final ring in rings) _ring(ring! as List<Object?>)];
    return CountyPolygon(outer: parsed.first, holes: parsed.skip(1).toList());
  }

  static List<TripRoutePoint> _ring(List<Object?> ring) => [
    for (final p in ring)
      TripRoutePoint(
        ((p! as List<Object?>)[1]! as num).toDouble(),
        ((p as List<Object?>)[0]! as num).toDouble(),
      ),
  ];
}
