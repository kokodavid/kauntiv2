import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/core/domain/place_type.dart';
import 'package:kaunti47_v2/src/counties/county_paths.dart';
import 'package:kaunti47_v2/src/features/discover/domain/explore_board.dart';
import 'package:kaunti47_v2/src/features/discover/domain/explore_entries.dart';
import 'package:kaunti47_v2/src/features/discover/domain/explore_headline.dart';
import 'package:kaunti47_v2/src/features/discover/domain/explore_lists.dart';
import 'package:kaunti47_v2/src/features/profile/domain/place_interest.dart';

CountyPath _county(String name, int code) =>
    CountyPath(slug: name.toLowerCase(), name: name, code: code, pathData: '');

ExploreUnclaimedCounty _unclaimed(String name, int code, {num? meters}) =>
    ExploreUnclaimedCounty(
      county: _county(name, code),
      blurb: '',
      percentHaveBeen: null,
      placeCount: 1,
      distanceMeters: meters,
    );

ExploreMineCounty _mine(String name, int code) => ExploreMineCounty(
  county: _county(name, code),
  statusLabel: 'Explored',
  placeCount: 1,
  isLocalExpert: false,
  previewPlaces: const [],
);

ExploreEntry _entry(String id, PlaceType type, num km) => ExploreEntry(
  place: ExplorePlace(
    id: id,
    title: id,
    description: '',
    category: type,
    saved: false,
    distanceMeters: km * 1000,
  ),
  countyCode: 1,
  countyName: 'County',
  claimed: false,
);

void main() {
  test('with badges the next-badge sentence is parked: plain count', () {
    final headline = exploreHeadline(
      board: ExploreBoard(
        featuredUnlock: null,
        mine: [_mine('Nairobi', 47)],
        unclaimed: [
          _unclaimed('Machakos', 16, meters: 120000),
          _unclaimed('Kajiado', 12, meters: 74000),
          _unclaimed('Lamu', 5),
        ],
      ),
      entries: const [],
      interests: const [],
      locationUnavailable: false,
    );
    expect(headline.text, '3 counties still to claim.');
  });

  test('nothing claimed: nearest of what they like within the radius', () {
    final headline = exploreHeadline(
      board: ExploreBoard(
        featuredUnlock: null,
        mine: const [],
        unclaimed: [_unclaimed('Kajiado', 12, meters: 74000)],
      ),
      entries: [
        _entry('a', PlaceType.waterfall, 40),
        _entry('b', PlaceType.waterfall, 60),
        _entry('c', PlaceType.waterfall, 400),
      ],
      interests: const [PlaceInterest.water],
      locationUnavailable: false,
    );
    expect(
      headline.text,
      '2 waterfalls within 100 km of you. All 1 counties still to claim.',
    );
    expect(headline.typeKey, 'waterfall');
    expect(
      exploreHeadlinePlaces([
        _entry('a', PlaceType.waterfall, 40),
        _entry('b', PlaceType.waterfall, 60),
        _entry('c', PlaceType.waterfall, 400),
      ], 'waterfall').map((e) => e.place.id),
      ['a', 'b'],
    );
  });

  test('location off names the home county', () {
    final headline = exploreHeadline(
      board: ExploreBoard(
        featuredUnlock: null,
        mine: const [],
        unclaimed: [_unclaimed('Kajiado', 12)],
      ),
      entries: const [],
      interests: const [],
      locationUnavailable: true,
      homeCountyName: 'Kiambu',
    );
    expect(headline.text, 'Starting from Kiambu, your home county.');
  });

  test('everything claimed', () {
    final headline = exploreHeadline(
      board: ExploreBoard(
        featuredUnlock: null,
        mine: [_mine('Nairobi', 47), _mine('Kiambu', 22)],
      ),
      entries: const [],
      interests: const [],
      locationUnavailable: false,
    );
    expect(headline.text, 'All 2 claimed.');
  });

  test('rotation takes the liked types nearby in turn', () {
    ExploreHeadline at(int rotation) => exploreHeadline(
      board: ExploreBoard(
        featuredUnlock: null,
        mine: const [],
        unclaimed: [_unclaimed('Kajiado', 12, meters: 74000)],
      ),
      entries: [
        _entry('a', PlaceType.waterfall, 40),
        _entry('b', PlaceType.waterfall, 60),
        _entry('c', PlaceType.beach, 30),
      ],
      interests: const [PlaceInterest.water, PlaceInterest.coast],
      locationUnavailable: false,
      rotation: rotation,
    );
    expect(at(0).typeKey, 'waterfall');
    expect(at(1).typeKey, 'beach');
    expect(at(2).typeKey, 'waterfall');
  });

  test('nothing liked nearby: names the nearest liked place', () {
    final headline = exploreHeadline(
      board: ExploreBoard(
        featuredUnlock: null,
        mine: [_mine('Nairobi', 47)],
        unclaimed: [_unclaimed('Kajiado', 12, meters: 74000)],
      ),
      entries: [_entry('Diani', PlaceType.beach, 480)],
      interests: const [PlaceInterest.coast],
      locationUnavailable: false,
    );
    expect(headline.text, 'Nearest beach is Diani, 480 km away.');
    expect(headline.typeKey, 'beach');
    expect(headline.withinRadius, isFalse);
  });
}
