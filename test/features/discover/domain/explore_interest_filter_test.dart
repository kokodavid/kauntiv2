import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/core/domain/place_type.dart';
import 'package:kaunti47_v2/src/features/discover/domain/explore_board.dart';
import 'package:kaunti47_v2/src/features/discover/domain/explore_entries.dart';
import 'package:kaunti47_v2/src/features/discover/domain/explore_filters.dart';
import 'package:kaunti47_v2/src/features/discover/domain/explore_results.dart';
import 'package:kaunti47_v2/src/features/profile/domain/place_interest.dart';

ExploreEntry _entry(String id, PlaceType type) => ExploreEntry(
  place: ExplorePlace(
    id: id,
    title: id,
    description: '',
    category: type,
    saved: false,
  ),
  countyCode: 1,
  countyName: 'County',
  claimed: false,
);

void main() {
  final entries = [
    _entry('a', PlaceType.waterfall),
    _entry('b', PlaceType.hike),
    _entry('c', PlaceType.beach),
  ];

  test('interest types list what is on the board for each interest', () {
    final types = exploreInterestTypes(entries, const [
      PlaceInterest.water,
      PlaceInterest.coast,
    ]);
    expect(types[PlaceInterest.water], {'waterfall', 'beach'});
    expect(types[PlaceInterest.coast], {'beach'});
  });

  test('typeKeys keeps only those types and counts as one sheet filter', () {
    const filters = ExploreFilters(typeKeys: {'waterfall', 'hike'});
    expect(filters.sheetCount, 1);
    expect(filters.isEmpty, isFalse);
    expect(entries.where(filters.matches).map((e) => e.place.id), ['a', 'b']);
  });

  test('a dock category replaces the interest filter', () {
    const filters = ExploreFilters(typeKeys: {'waterfall', 'hike'});
    final next = filters.copyWith(typeKey: 'beach');
    expect(next.typeKeys, isNull);
    expect(next.typeKey, 'beach');
  });
}
