import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/trip_plans/data/plan_place_search_client.dart';
import 'package:kaunti47_v2/src/features/trip_plans/domain/trip_plan.dart';

void main() {
  test('reads Mapbox v6 features into exact points', () {
    const body = '''
{"type":"FeatureCollection","features":[
 {"type":"Feature","geometry":{"type":"Point","coordinates":[36.8047,-1.2635]},
  "properties":{"name":"Total Energies Westlands","name_preferred":"Total Energies Westlands",
   "place_formatted":"Westlands, Nairobi, Kenya","feature_type":"poi"}},
 {"type":"Feature","geometry":{"type":"Point","coordinates":[39.67,-4.04]},
  "properties":{"name":"Nyali Road","place_formatted":"Mombasa, Kenya","feature_type":"street"}},
 {"type":"Feature","geometry":{"type":"Point","coordinates":[1,2]},"properties":{"name":" "}}
]}''';
    final found = MapboxPlanPlaceSearch.parse(body);
    expect(found.length, 2);
    expect(found.first.name, 'Total Energies Westlands');
    expect(found.first.lat, -1.2635);
    expect(found.first.lng, 36.8047);
    expect(
      found.first.label,
      'Total Energies Westlands, Westlands, Nairobi, Kenya',
    );
    final start = found.first.toStart();
    expect(start.kind, PlanStartKind.point);
    expect(start.lat, -1.2635);
  });

  test('an unreadable body is a search failure', () {
    expect(
      () => MapboxPlanPlaceSearch.parse('not json'),
      throwsA(isA<PlanPlaceSearchFailure>()),
    );
  });
}
