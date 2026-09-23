import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/map_home/application/county_camera_fit.dart';

void main() {
  const geoJson = '''
{"type":"FeatureCollection","features":[{"type":"Feature",
 "properties":{"code":47},
 "geometry":{"type":"MultiPolygon","coordinates":[[[[36.6,-1.4],[37.1,-1.4],
 [37.1,-1.1],[36.6,-1.1],[36.6,-1.4]]]]}}]}''';

  test('bounds per county code from MultiPolygon coordinates', () {
    final bounds = CountyCameraFit.boundsByCode(geoJson)[47]!;
    expect(bounds.minLng, 36.6);
    expect(bounds.maxLng, 37.1);
    expect(bounds.minLat, -1.4);
    expect(bounds.maxLat, -1.1);
    expect(CountyCameraFit.centerOf(bounds).lng, closeTo(36.85, 1e-9));
  });

  test('small counties zoom in further than large ones, within clamps', () {
    const small = (minLng: 36.6, minLat: -1.4, maxLng: 37.1, maxLat: -1.1);
    const large = (minLng: 34.0, minLat: 1.0, maxLng: 36.5, maxLat: 5.0);
    final smallZoom = CountyCameraFit.zoomToFit(small, width: 390, height: 460);
    final largeZoom = CountyCameraFit.zoomToFit(large, width: 390, height: 460);
    expect(smallZoom, greaterThan(largeZoom));
    expect(largeZoom, greaterThanOrEqualTo(5.5));
    expect(smallZoom, lessThanOrEqualTo(11));
  });
}
