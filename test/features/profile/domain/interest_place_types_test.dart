import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/profile/domain/interest_matcher.dart';
import 'package:kaunti47_v2/src/features/profile/domain/interest_place_types.dart';
import 'package:kaunti47_v2/src/features/profile/domain/place_interest.dart';

void main() {
  final types = InterestPlaceTypes.fallback;

  test('a place type matches the first pick that counts it', () {
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
    expect(types.matchFor('zoo', PlaceInterest.values), isNull);
    expect(types.matchFor('park', const []), isNull);
  });

  test('hikes belong to Activities, not Water', () {
    expect(types.matchFor('hike', [PlaceInterest.water]), isNull);
    expect(
      types.matchFor('hike', [PlaceInterest.water, PlaceInterest.activities]),
      PlaceInterest.activities,
    );
  });

  test('lakes and hot springs are Water', () {
    expect(types.matchFor('lake', [PlaceInterest.water]), PlaceInterest.water);
    expect(
      types.matchFor('hot_spring', [PlaceInterest.water]),
      PlaceInterest.water,
    );
  });

  test('Coast only counts in coastal counties; lake islands are Water', () {
    final picks = [PlaceInterest.coast, PlaceInterest.water];
    expect(types.matchFor('island', picks, coastal: true), PlaceInterest.coast);
    expect(
      types.matchFor('island', picks, coastal: false),
      PlaceInterest.water,
    );
    expect(
      types.matchFor('island', [PlaceInterest.coast], coastal: false),
      isNull,
    );
    // County not known yet: the link still counts.
    expect(
      types.matchFor('island', [PlaceInterest.coast]),
      PlaceInterest.coast,
    );
  });

  test('the matcher reads the county from its coastal list', () {
    final matcher = InterestMatcher(
      InterestPlaceTypes.fromRows(const []),
      const CountyCoast({1}),
    );
    expect(matcher.coast.isCoastal(1), isTrue);
    expect(matcher.coast.isCoastal(2), isFalse);
    expect(CountyCoast.unknown.isCoastal(1), isNull);
    final real = InterestMatcher(
      InterestPlaceTypes.fallback,
      const CountyCoast({1}),
    );
    expect(
      real.matchFor('beach', [PlaceInterest.coast], countyCode: 1),
      PlaceInterest.coast,
    );
    expect(
      real.matchFor('beach', [PlaceInterest.coast], countyCode: 2),
      isNull,
    );
  });

  test('rows from the backend table replace the bundled mapping', () {
    final fromRows = InterestPlaceTypes.fromRows([
      {'interest_key': 'food', 'place_type': ' Cafe '},
      {'interest_key': 'water', 'place_type': ''},
    ]);
    expect(fromRows.matchFor('cafe', [PlaceInterest.food]), PlaceInterest.food);
    expect(fromRows.matchFor('park', PlaceInterest.values), isNull);
  });

  test('an interest added in the backend works without an app update', () {
    const trails = PlaceInterest('trails', 'Trails', 'trails');
    final fromRows = InterestPlaceTypes.fromRows([
      {
        'interest_key': 'trails',
        'place_type': 'hike',
        'is_primary': true,
        'county_scope': 'any',
      },
    ]);
    expect(fromRows.matchFor('hike', [trails]), trails);
    expect(fromRows.interestKeysFor('hike'), {'trails'});
    expect(fromRows.typesFor(trails), {'hike'});
  });

  test('interests are equal by key and keep unlisted saved keys', () {
    expect(const PlaceInterest('water', 'Renamed', 'x'), PlaceInterest.water);
    final stored = PlaceInterest.fromStoredKeys(['coast', 'bogus', 'coast']);
    expect(stored.map((i) => i.key), ['coast', 'bogus']);
    expect(PlaceInterest.withPick([PlaceInterest.coast], PlaceInterest.water), [
      PlaceInterest.water,
      PlaceInterest.coast,
    ]);
  });
}
