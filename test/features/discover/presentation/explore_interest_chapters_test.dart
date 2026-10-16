import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/core/domain/place_type.dart';
import 'package:kaunti47_v2/src/features/discover/domain/explore_board.dart';
import 'package:kaunti47_v2/src/features/discover/domain/explore_entries.dart';
import 'package:kaunti47_v2/src/features/discover/presentation/explore_interest_chapters.dart';
import 'package:kaunti47_v2/src/features/profile/domain/interest_matcher.dart';
import 'package:kaunti47_v2/src/features/profile/domain/interest_place_types.dart';
import 'package:kaunti47_v2/src/features/profile/domain/place_interest.dart';

ExploreEntry _entry(String id, PlaceType type, int county) => ExploreEntry(
  place: ExplorePlace(
    id: id,
    title: id,
    description: '',
    category: type,
    saved: false,
  ),
  countyCode: county,
  countyName: 'County $county',
  claimed: false,
);

void main() {
  // County 1 is coastal, county 2 is not.
  final matcher = InterestMatcher(
    InterestPlaceTypes.fallback,
    const CountyCoast({1}),
  );
  final entries = [
    _entry('sea-island', PlaceType.island, 1),
    _entry('lake-island', PlaceType.island, 2),
    _entry('falls', PlaceType.waterfall, 2),
    _entry('park', PlaceType.park, 2),
  ];

  test('Coast holds coastal-county islands, Water holds lake islands', () {
    final chapters = exploreInterestChapters(entries, [
      PlaceInterest.coast,
      PlaceInterest.water,
    ], matcher: matcher);
    final byInterest = {
      for (final c in chapters) c.interest: c.places.map((e) => e.place.id),
    };
    expect(byInterest[PlaceInterest.coast], ['sea-island']);
    expect(byInterest[PlaceInterest.water], ['lake-island', 'falls']);
  });

  test(
    'a place under two picked interests is listed once, first pick wins',
    () {
      final chapters = exploreInterestChapters(entries, [
        PlaceInterest.wild,
        PlaceInterest.nature,
      ], matcher: matcher);
      expect(chapters.map((c) => c.interest), [PlaceInterest.wild]);
      expect(chapters.single.places.single.place.id, 'park');
    },
  );

  test('places shown above are skipped before the row is filled', () {
    final many = [
      for (var i = 0; i < 9; i++) _entry('f$i', PlaceType.waterfall, 2),
    ];
    final chapters = exploreInterestChapters(
      many,
      [PlaceInterest.water],
      matcher: matcher,
      hide: {'f0', 'f1', 'f2', 'f3', 'f4'},
    );
    // Taking six first and then hiding would have left one card.
    expect(chapters.single.places.map((e) => e.place.id), [
      'f5',
      'f6',
      'f7',
      'f8',
    ]);
    expect(chapters.single.total, 9);
  });

  test('More places keeps every place that no pick covers', () {
    final rest = exploreUnmatched(entries, [PlaceInterest.coast], matcher);
    expect(rest.map((e) => e.place.id), ['lake-island', 'falls', 'park']);
  });
}
