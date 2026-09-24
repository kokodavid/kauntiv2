import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/counties/county_paths.dart';
import 'package:kaunti47_v2/src/features/discover/domain/explore_board.dart';
import 'package:kaunti47_v2/src/features/discover/domain/explore_labels.dart';
import 'package:kaunti47_v2/src/features/discover/domain/place_category.dart';

ExplorePlace _place(String id, String title) => ExplorePlace(
  id: id,
  title: title,
  description: '$title summary',
  category: PlaceCategory.park,
  saved: false,
);

ExploreMineCounty _county(int code, List<ExplorePlace> places) =>
    ExploreMineCounty(
      county: CountyPaths.byCode[code]!,
      statusLabel: 'EXPLORED',
      placeCount: places.length,
      isLocalExpert: false,
      previewPlaces: places,
    );

void main() {
  final mombasa = CountyPaths.byCode[1]!;
  final board = ExploreBoard(
    featuredUnlock: ExploreFeaturedUnlock(
      county: mombasa,
      rarityLabel: 'RARITY NOT TRACKED YET',
      previewPlaces: [_place('a', 'Fort Jesus')],
      totalPlaceCount: 1,
    ),
    mine: [
      _county(2, [_place('b', 'Shimba Hills')]),
      _county(3, [_place('c', 'Mnarani Ruins')]),
    ],
  );

  group('ExploreBoard.filtered', () {
    test('blank query returns the same board', () {
      expect(board.filtered('  '), same(board));
    });

    test('matches county names and place text, case-insensitively', () {
      final byPlace = board.filtered('shimba');
      expect(byPlace.featuredUnlock, isNull);
      expect(byPlace.mine.map((c) => c.county.code), [2]);

      final byFeatured = board.filtered(mombasa.name.toUpperCase());
      expect(byFeatured.featuredUnlock, isNotNull);
    });

    test('no match leaves an empty board', () {
      expect(board.filtered('zzz').isEmpty, isTrue);
    });

    test('mineCount excludes the featured county (v1 parity)', () {
      expect(board.mineCount, 2);
    });
  });

  group('ExploreLabels', () {
    test('rarity shows the gap when not tracked', () {
      expect(ExploreLabels.rarity(null), 'RARITY NOT TRACKED YET');
      expect(ExploreLabels.rarity(4.4), 'ONLY 4% HAVE BEEN HERE');
      expect(ExploreLabels.rarity(12), '12% HAVE BEEN HERE');
    });

    test('mine status', () {
      expect(
        ExploreLabels.mineStatus(isLocalExpert: true, visits: 3),
        'LOCAL EXPERT · 3 VISITS',
      );
      expect(
        ExploreLabels.mineStatus(isLocalExpert: false, visits: 3),
        'EXPLORED',
      );
    });

    test('distance labels', () {
      expect(ExploreLabels.distance(null), isNull);
      expect(ExploreLabels.distance(420), '420 m away');
      expect(ExploreLabels.distance(12400), '12 km away');
      expect(
        ExploreLabels.placeDistance(
          from: null,
          latitude: -1.28,
          longitude: 36.82,
        ),
        isNull,
      );
      // Nairobi CBD to Mombasa is roughly 440 km in a straight line.
      final label = ExploreLabels.placeDistance(
        from: (latitude: -1.2864, longitude: 36.8172),
        latitude: -4.0435,
        longitude: 39.6682,
      );
      expect(label, matches(RegExp(r'^4[34]\d km away$')));
    });
  });
}
