import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/counties/county_paths.dart';
import 'package:kaunti47_v2/src/features/map_home/domain/map_home_models.dart';
import 'package:kaunti47_v2/src/features/profile/domain/place_interest.dart';

MapHomeSuggestion _suggestion({PlaceInterest? interest, String? place}) =>
    MapHomeSuggestion(
      county: CountyPaths.byCode[47]!,
      reason: MapHomeSuggestionReason.unclaimed,
      distanceAway: '12 km away',
      isNear: true,
      matchedInterest: interest,
      matchedPlaceName: place,
    );

void main() {
  test('an unmatched unclaimed county keeps the plain label', () {
    final s = _suggestion();
    expect(s.matchLabel, isNull);
    expect(s.reasonLabel, 'Unclaimed county');
  });

  test('a matched county says why it was suggested', () {
    final s = _suggestion(interest: PlaceInterest.water, place: 'Chania Falls');
    expect(s.matchLabel, 'Because you like waterfalls');
    expect(s.reasonLabel, 'Because you like waterfalls');
    expect(s.title, CountyPaths.byCode[47]!.name);
  });
}
