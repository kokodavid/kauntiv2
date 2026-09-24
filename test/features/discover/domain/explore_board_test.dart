import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/counties/county_paths.dart';
import 'package:kaunti47_v2/src/features/discover/data/explore_rows.dart';
import 'package:kaunti47_v2/src/features/discover/domain/explore_board.dart';
import 'package:kaunti47_v2/src/features/discover/domain/explore_labels.dart';
import 'package:kaunti47_v2/src/features/discover/domain/explore_lists.dart';
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

Map<String, dynamic> _row(String id, {bool promoted = false}) => {
  'id': id,
  'name': 'Place $id',
  'type': 'park',
  'summary': 'Summary $id',
  'place_promotions': promoted
      ? [
          {
            'disclosure_label': 'AD',
            'starts_at': DateTime.now()
                .subtract(const Duration(days: 1))
                .toUtc()
                .toIso8601String(),
            'ends_at': null,
            'deactivated_at': null,
          },
        ]
      : const [],
};

void main() {
  final mombasa = CountyPaths.byCode[1]!;
  final board = ExploreBoard(
    featuredUnlock: ExploreFeaturedUnlock(
      county: mombasa,
      rarityLabel: 'Rarity not tracked yet',
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
      expect(ExploreLabels.rarity(null), 'Rarity not tracked yet');
      expect(ExploreLabels.rarity(4.4), 'Only 4% have been here');
      expect(ExploreLabels.rarity(12), '12% have been here');
    });

    test('mine status', () {
      expect(
        ExploreLabels.mineStatus(isLocalExpert: true, visits: 3),
        'Local expert · 3 visits',
      );
      expect(
        ExploreLabels.mineStatus(isLocalExpert: false, visits: 3),
        'Explored',
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

  group('UNCLAIMED', () {
    ExploreUnclaimedCounty entry(int code, {num? meters, int? percent}) =>
        ExploreUnclaimedCounty(
          county: CountyPaths.byCode[code]!,
          blurb: 'blurb $code',
          percentHaveBeen: percent,
          placeCount: 0,
          distanceMeters: meters,
        );

    test('nearest first, unknown distances last in original order', () {
      final sorted = ExploreUnclaimedCounty.nearestFirst([
        entry(1),
        entry(2, meters: 900),
        entry(3),
        entry(4, meters: 100),
      ]);
      expect(sorted.map((e) => e.county.code), [4, 2, 1, 3]);
    });

    test('status line: rarity, else distance, else headquarters', () {
      expect(entry(1, percent: 3).statusLine, 'Only 3% have been');
      expect(
        ExploreUnclaimedCounty(
          county: CountyPaths.byCode[1]!,
          blurb: '',
          percentHaveBeen: null,
          placeCount: 0,
          distanceLabel: '45 km away',
          headquarters: 'Kerugoya',
        ).statusLine,
        '45 km away',
      );
      expect(
        ExploreUnclaimedCounty(
          county: CountyPaths.byCode[1]!,
          blurb: '',
          percentHaveBeen: null,
          placeCount: 0,
          headquarters: 'Kerugoya',
        ).statusLine,
        'HQ · Kerugoya',
      );
    });

    test('rarity label', () {
      expect(entry(1).rarityLabel, 'Rarity not tracked yet');
      expect(entry(1, percent: 3).rarityLabel, 'Only 3% have been');
      expect(entry(1, percent: 30).rarityLabel, '30% have been');
    });

    test('search also matches the blurb', () {
      final withUnclaimed = ExploreBoard(
        featuredUnlock: null,
        mine: const [],
        unclaimed: [entry(5)],
      );
      expect(withUnclaimed.filtered('blurb 5').unclaimedCount, 1);
      expect(withUnclaimed.filtered('nothing').unclaimedCount, 0);
    });

    test('blurb names up to two places', () {
      expect(ExploreLabels.blurb([]), 'No places on file yet for this county.');
      expect(ExploreLabels.blurb(['A']), '1 place to see, including A.');
      expect(
        ExploreLabels.blurb(['A', 'B', 'C']),
        '3 places to see, including A and B.',
      );
    });
  });

  group('SAVED', () {
    test('status labels (v1 parity)', () {
      expect(
        ExploreSavedGroup.statusFor(
          rank: 'local_expert',
          savedPlaces: 3,
          stillToSee: 1,
        ),
        (ExploreSavedStatus.localExpert, 'Local expert · 1 still to see'),
      );
      expect(
        ExploreSavedGroup.statusFor(
          rank: 'visitor',
          savedPlaces: 0,
          stillToSee: 0,
        ),
        (ExploreSavedStatus.badgeEarned, 'Badge earned · nothing picked yet'),
      );
      expect(
        ExploreSavedGroup.statusFor(rank: null, savedPlaces: 2, stillToSee: 2),
        (ExploreSavedStatus.locked, 'Locked · 2 saved'),
      );
      expect(
        ExploreSavedGroup.statusFor(rank: null, savedPlaces: 0, stillToSee: 0),
        (ExploreSavedStatus.savedOnly, 'Saved county · nothing picked yet'),
      );
    });

    test('savedCount counts places across groups', () {
      final group = ExploreSavedGroup(
        county: CountyPaths.byCode[4]!,
        status: ExploreSavedStatus.locked,
        statusLabel: 'LOCKED · 2 SAVED',
        places: [_place('x', 'X'), _place('y', 'Y')],
      );
      final saved = ExploreBoard(
        featuredUnlock: null,
        mine: const [],
        saved: [group],
      );
      expect(saved.savedCount, 2);
    });
  });

  group('promoted preview places', () {
    test('places active AD second when normal places can surround it', () {
      final rows = ExploreRows.previewRows([
        _row('normal-a'),
        _row('normal-b'),
        _row('ad', promoted: true),
        _row('normal-c'),
      ]);
      expect(rows.map((row) => row['id']), ['normal-a', 'ad', 'normal-b']);
    });

    test('uses active AD first when it is the county only place', () {
      final rows = ExploreRows.previewRows([_row('ad', promoted: true)]);
      expect(rows.map((row) => row['id']), ['ad']);
    });

    test('maps active AD metadata onto ExplorePlace', () {
      final place = ExploreRows.place(
        _row('ad', promoted: true),
        id: 'ad',
        saved: false,
        location: null,
      );
      expect(place.isPromoted, isTrue);
      expect(place.promotionLabel, 'AD');
    });
  });

  test('featured county stats list what is on file', () {
    expect(exploreCountyStats(noCountyFacts), isEmpty);
    expect(
      exploreCountyStats((areaKm2: 1205, elevationM: null, durationMinutes: 90)),
      [(value: '1,205 KM²', label: 'Area'), (value: '1h 30m', label: 'Duration')],
    );
  });
}
