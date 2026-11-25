import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/trip_plans/domain/custom_place_draft.dart';
import 'package:kaunti47_v2/src/features/trip_plans/domain/plan_place.dart';
import 'package:kaunti47_v2/src/features/trip_plans/domain/plan_place_suggestion.dart';

void main() {
  test('a custom place from the server reads as custom with no type', () {
    final place = PlanPlace.fromJson({
      'id': 'c1',
      'name': 'Airbnb in Nakuru',
      'type': 'custom',
      'county_code': 32,
      'lat': -0.3,
      'lng': 36.07,
      'custom': true,
      'address': 'Milimani, Nakuru',
    });
    expect(place, isNotNull);
    expect(place!.isCustom, isTrue);
    expect(place.type, '');
    expect(place.address, 'Milimani, Nakuru');
  });

  test('a Kaunti47 place is not custom', () {
    final place = PlanPlace.fromJson({
      'id': 'p1',
      'name': 'Hell\'s Gate',
      'type': 'park',
      'county_code': 32,
    });
    expect(place!.isCustom, isFalse);
    expect(place.type, 'park');
  });

  test('a search result keeps its name, address and county', () {
    final draft = CustomPlaceDraft.fromSuggestion(
      const PlanPlaceSuggestion(
        name: 'Java House',
        address: 'Westlands, Nairobi',
        lat: -1.26,
        lng: 36.8,
      ),
      countyCode: 47,
    );
    expect(draft.source, CustomPlaceSource.search);
    expect(draft.countyCode, 47);
    expect(draft.address, 'Westlands, Nairobi');
  });

  test('a pin is trimmed and clipped to 80 letters', () {
    final draft = CustomPlaceDraft.pin(
      name: '  ${'a' * 100}  ',
      lat: 0,
      lng: 37,
    );
    expect(draft.name.length, 80);
    expect(draft.source, CustomPlaceSource.pin);
  });
}
