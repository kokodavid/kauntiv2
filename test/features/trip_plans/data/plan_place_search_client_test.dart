import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/trip_plans/data/geoapify_plan_place_search.dart';
import 'package:kaunti47_v2/src/features/trip_plans/data/plan_place_search_client.dart';

void main() {
  test('reads Geoapify results, businesses included', () {
    const body = '''
{"results":[
 {"name":"Shell Westlands","address_line1":"Shell Westlands",
  "address_line2":"Waiyaki Way, Nairobi, Kenya","lon":36.8031,"lat":-1.2641,
  "result_type":"amenity","category":"commercial.fuel"},
 {"address_line1":"Kimathi Street","address_line2":"Nairobi, Kenya",
  "lon":36.8219,"lat":-1.2833},
 {"address_line1":"No coordinates here"},
 {"lon":1,"lat":2}
],"query":{"text":"shell"}}''';
    final found = GeoapifyPlanPlaceSearch.parse(body);
    expect(found.length, 2);
    expect(found.first.name, 'Shell Westlands');
    expect(found.first.address, 'Waiyaki Way, Nairobi, Kenya');
    expect(found.first.lat, -1.2641);
    expect(found.first.lng, 36.8031);
    expect(found.last.name, 'Kimathi Street');
  });

  test('an unreadable Geoapify body is a search failure', () {
    expect(
      () => GeoapifyPlanPlaceSearch.parse('{oops'),
      throwsA(isA<PlanPlaceSearchFailure>()),
    );
  });
}
