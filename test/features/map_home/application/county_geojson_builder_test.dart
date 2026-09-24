import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/counties/county_paths.dart';
import 'package:kaunti47_v2/src/features/map_home/application/county_geojson_builder.dart';
import 'package:kaunti47_v2/src/features/map_home/domain/map_home_models.dart';

void main() {
  const boundaries = '''
{"type":"FeatureCollection","features":[
  {"type":"Feature","properties":{"code":47,"slug":"nairobi"},"geometry":null},
  {"type":"Feature","properties":{"code":1,"slug":"mombasa"},"geometry":null},
  {"type":"Feature","properties":{"code":23,"slug":"turkana"},"geometry":null}
]}''';

  Map<int, Object?> statesOf(String geoJson) {
    final features =
        (jsonDecode(geoJson) as Map<String, Object?>)['features']!
            as List<Object?>;
    return {
      for (final f in features.cast<Map<String, Object?>>())
        (f['properties']! as Map<String, Object?>)['code']! as int:
            (f['properties']! as Map<String, Object?>)['state'],
    };
  }

  test('sets state from badges, home overrides earned, missing is locked', () {
    final nairobi = CountyPaths.byCode[47]!;
    final mombasa = CountyPaths.byCode[1]!;

    final geoJson = CountyGeoJsonBuilder.withBadgeStates(
      boundariesGeoJson: boundaries,
      badges: [
        MapHomeCountyBadge(
          county: nairobi,
          state: MapHomeCountyBadgeState.earned,
        ),
        MapHomeCountyBadge(
          county: mombasa,
          state: MapHomeCountyBadgeState.passedThrough,
        ),
      ],
      homeCountySlug: nairobi.slug,
    );

    expect(statesOf(geoJson), {1: 'passedThrough', 23: 'locked', 47: 'home'});
  });
}
