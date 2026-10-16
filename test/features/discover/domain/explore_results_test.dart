import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/core/domain/place_type.dart';
import 'package:kaunti47_v2/src/features/discover/domain/explore_board.dart';
import 'package:kaunti47_v2/src/features/discover/domain/explore_entries.dart';
import 'package:kaunti47_v2/src/features/discover/domain/explore_filters.dart';
import 'package:kaunti47_v2/src/features/discover/domain/explore_results.dart';

ExploreEntry _entry(
  String id, {
  PlaceType type = PlaceType.waterfall,
  num? km,
  bool claimed = false,
  String? photo,
  int county = 1,
}) => ExploreEntry(
  place: ExplorePlace(
    id: id,
    title: id,
    description: '',
    category: type,
    saved: false,
    thumbnailUrl: photo,
    distanceMeters: km == null ? null : km * 1000,
  ),
  countyCode: county,
  countyName: 'County $county',
  claimed: claimed,
);

void main() {
  group('ExploreFilters', () {
    test('the dock category does not count as a sheet filter', () {
      const filters = ExploreFilters(typeKey: 'waterfall');
      expect(filters.sheetCount, 0);
      expect(filters.isEmpty, isFalse);
      expect(const ExploreFilters.none().isEmpty, isTrue);
    });

    test('matches type, claim state, photos, county and distance', () {
      final near = _entry('a', km: 40, photo: 'x');
      final far = _entry('b', km: 300, claimed: true, county: 2);
      expect(const ExploreFilters(typeKey: 'hike').matches(near), isFalse);
      expect(const ExploreFilters(unclaimedOnly: true).matches(far), isFalse);
      expect(const ExploreFilters(countyCode: 2).matches(near), isFalse);
      expect(const ExploreFilters(maxKm: 100).matches(near), isTrue);
      expect(const ExploreFilters(maxKm: 100).matches(far), isFalse);
    });

    test('a distance limit leaves out places with no distance', () {
      expect(const ExploreFilters(maxKm: 100).matches(_entry('a')), isFalse);
    });
  });

  group('buildExploreResults', () {
    final entries = [
      _entry('zaina', km: 94),
      _entry('gura', km: 112),
      _entry('thomsons', km: 141),
      _entry('diani', km: 482),
      _entry('shela', km: 707),
    ];

    test('groups by distance and names the first band "under"', () {
      final results = buildExploreResults(
        entries,
        const ExploreFilters(maxKm: 250),
        hasLocation: true,
      );
      expect(results.count, 3);
      expect(results.bands.map((b) => b.label), [
        'UNDER 100 KM',
        '100 - 250 KM',
      ]);
      expect(results.bands.first.entries.single.place.id, 'zaina');
    });

    test('counts places beyond the limit and offers the next stop', () {
      final results = buildExploreResults(
        entries,
        const ExploreFilters(maxKm: 100),
        hasLocation: true,
      );
      expect(results.count, 1);
      expect(results.furtherCount, 4);
      expect(results.nextStopKm, 250);
    });

    test('past the last stop the footer offers everything', () {
      final results = buildExploreResults(
        entries,
        const ExploreFilters(maxKm: 250),
        hasLocation: true,
      );
      expect(results.nextStopKm, isNull);
      expect(results.furtherCount, 2);
    });

    test('without a location there is one unlabelled band', () {
      final results = buildExploreResults(
        [_entry('a'), _entry('b')],
        const ExploreFilters(typeKey: 'waterfall'),
        hasLocation: false,
      );
      expect(results.bands.single.label, isEmpty);
      expect(results.count, 2);
    });

    test('sorts nearest first, no distance last', () {
      final results = buildExploreResults(
        [_entry('none'), _entry('far', km: 90), _entry('near', km: 10)],
        const ExploreFilters.none(),
        hasLocation: true,
      );
      final ids = [
        for (final band in results.bands)
          for (final entry in band.entries) entry.place.id,
      ];
      expect(ids, ['near', 'far', 'none']);
      expect(results.bands.last.label, 'NO DISTANCE');
    });
  });

  group('exploreSentence', () {
    test('names the count, the type and the claim state', () {
      final sentence = exploreSentence(
        const ExploreFilters(typeKey: 'waterfall', unclaimedOnly: true),
        3,
      );
      expect(sentence.lead, '3 waterfalls');
      expect(sentence.tail, " in counties you haven't claimed");
    });

    test('uses the singular for one and falls back to places', () {
      expect(
        exploreSentence(const ExploreFilters(typeKey: 'hike'), 1).lead,
        '1 hike',
      );
      expect(
        exploreSentence(const ExploreFilters(maxKm: 50), 2).tail,
        ' within 50 km of you',
      );
      expect(exploreNoun(null, 5), 'places');
      expect(exploreNoun('cultural_site', 2), 'cultural sites');
    });
  });
}
