import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/counties/county_paths.dart';
import 'package:kaunti47_v2/src/features/map_home/domain/map_home_models.dart';
import 'package:kaunti47_v2/src/features/map_home/domain/map_home_promotion.dart';

MapHomeSuggestion _s(int code, MapHomeSuggestionReason reason) =>
    MapHomeSuggestion(
      county: CountyPaths.byCode[code]!,
      reason: reason,
      distanceAway: '10 km away',
      isNear: true,
    );

MapHomeBoardData _board({
  List<MapHomeSuggestion> suggestions = const [],
  List<MapHomeSuggestion> unclaimed = const [],
  MapHomePromotedPlace? promotion,
}) => MapHomeBoardData(
  tierLabel: 'MGENI',
  totalCounties: 47,
  countyBadges: const [],
  homeCounty: null,
  suggestions: suggestions,
  unclaimed: unclaimed,
  unclaimedCount: unclaimed.length,
  promotion: promotion,
);

void main() {
  const unclaimed = MapHomeSuggestionReason.unclaimed;
  const saved = MapHomeSuggestionReason.savedHere;

  test('fallback top prefers a saved or depth pick over unclaimed', () {
    final board = _board(
      suggestions: [_s(1, unclaimed), _s(2, saved)],
      unclaimed: [_s(3, unclaimed)],
    );
    expect(board.fallbackTop?.county.code, 2);
    expect(board.unclaimedRow.map((s) => s.county.code), [3]);
  });

  test('an unclaimed fallback top is not repeated in the row', () {
    final board = _board(unclaimed: [_s(3, unclaimed), _s(4, unclaimed)]);
    expect(board.fallbackTop?.county.code, 3);
    expect(board.unclaimedRow.map((s) => s.county.code), [4]);
  });

  test('with a promotion the whole unclaimed row shows', () {
    final board = _board(
      unclaimed: [_s(3, unclaimed), _s(4, unclaimed)],
      promotion: MapHomePromotedPlace(
        placeId: 'p',
        placeName: 'Lodge',
        county: CountyPaths.byCode[5]!,
        disclosureLabel: 'AD',
        sponsorName: 'Lodge Ltd',
        latitude: -1.5,
        longitude: 37.1,
      ),
    );
    expect(board.unclaimedRow.map((s) => s.county.code), [3, 4]);
    expect(board.promotion!.directionsQuery, '-1.5,37.1');
  });

  test('a promotion without coordinates routes by name', () {
    final county = CountyPaths.byCode[5]!;
    final promo = MapHomePromotedPlace(
      placeId: 'p',
      placeName: 'Lodge',
      county: county,
      disclosureLabel: 'AD',
      sponsorName: 'Lodge Ltd',
    );
    expect(promo.directionsQuery, 'Lodge, ${county.name} County, Kenya');
  });

  test('the row shows at most six counties', () {
    final board = _board(
      unclaimed: [for (var code = 1; code <= 7; code++) _s(code, unclaimed)],
      promotion: MapHomePromotedPlace(
        placeId: 'p',
        placeName: 'Lodge',
        county: CountyPaths.byCode[20]!,
        disclosureLabel: 'AD',
        sponsorName: 'Lodge Ltd',
      ),
    );
    expect(board.unclaimedRow, hasLength(MapHomeBoardData.maxUnclaimedCards));
  });
}
