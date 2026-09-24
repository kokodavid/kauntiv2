import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/counties/county_paths.dart';
import 'package:kaunti47_v2/src/features/detection/data/geofence_service.dart';

void main() {
  test('the window is the county plus its neighbours', () {
    expect(GeofenceService.windowFor(47), {47, 16, 22, 34});
  });

  test('every window fits iOS\'s 20-region limit and has geometry', () {
    for (final county in CountyPaths.all) {
      final window = GeofenceService.windowFor(county.code);
      expect(window.length, lessThanOrEqualTo(20), reason: county.name);
      for (final code in window) {
        expect(CountyPaths.centroids[code], isNotNull, reason: '$code');
        expect(
          CountyPaths.geofenceRadiusMeters[code],
          isNotNull,
          reason: '$code',
        );
      }
    }
  });
}
