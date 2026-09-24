import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/core/domain/app_stat_format.dart';
import 'package:kaunti47_v2/src/counties/county_paths.dart';
import 'package:kaunti47_v2/src/features/map_home/domain/map_home_models.dart';

MapHomeSuggestion _suggestion({
  String? placeName,
  double? area,
  int? elevation,
  int? minutes,
}) => MapHomeSuggestion(
  county: CountyPaths.byCode[47]!,
  reason: MapHomeSuggestionReason.unclaimed,
  distanceAway: '45 km away',
  isNear: true,
  placeName: placeName,
  areaKm2: area,
  elevationM: elevation,
  visitDurationMinutes: minutes,
);

void main() {
  test('stat format', () {
    expect(AppStatFormat.area(3108.4), '3,108 KM²');
    expect(AppStatFormat.elevation(2348), '2,348m');
    expect(AppStatFormat.duration(45), '45m');
    expect(AppStatFormat.duration(1200), '20h');
    expect(AppStatFormat.duration(90), '1h 30m');
    expect(AppStatFormat.thousands(1234567), '1,234,567');
  });

  test('stats list only what is on file, in order', () {
    expect(_suggestion().stats, isEmpty);
    expect(
      _suggestion(area: 342, minutes: 1200).stats,
      [(value: '342 KM²', label: 'Area'), (value: '20h', label: 'Duration')],
    );
  });

  test('directions go to the place when there is one', () {
    final county = CountyPaths.byCode[47]!.name;
    expect(_suggestion().directionsQuery, '$county County, Kenya');
    expect(
      _suggestion(placeName: 'Karura Forest').directionsQuery,
      'Karura Forest, $county County, Kenya',
    );
  });
}
