import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/profile/domain/interest_place_types.dart';
import 'package:kaunti47_v2/src/features/profile/domain/place_interest.dart';

void main() {
  test('a place type matches the first pick that counts it', () {
    const types = InterestPlaceTypes.fallback;
    expect(
      types.matchFor('Waterfall', [PlaceInterest.coast, PlaceInterest.water]),
      PlaceInterest.water,
    );
    // A park counts for nature and wildlife: the earlier pick wins.
    expect(
      types.matchFor('park', [PlaceInterest.wild, PlaceInterest.nature]),
      PlaceInterest.wild,
    );
  });

  test('an unknown type or no picks matches nothing', () {
    const types = InterestPlaceTypes.fallback;
    expect(types.matchFor('zoo', PlaceInterest.values), isNull);
    expect(types.matchFor('park', const []), isNull);
  });

  test('rows from the backend table replace the bundled mapping', () {
    final types = InterestPlaceTypes.fromRows([
      {'interest_key': 'food', 'place_type': ' Cafe '},
      {'interest_key': 'nonsense', 'place_type': 'park'},
      {'interest_key': 'water', 'place_type': ''},
    ]);
    expect(types.matchFor('cafe', [PlaceInterest.food]), PlaceInterest.food);
    expect(types.matchFor('park', PlaceInterest.values), isNull);
  });
}
