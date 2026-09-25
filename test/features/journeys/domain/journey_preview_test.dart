import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/journeys/domain/journey_point.dart';
import 'package:kaunti47_v2/src/features/journeys/domain/journey_preview.dart';
import 'package:kaunti47_v2/src/features/journeys/domain/journey_route.dart';

JourneyPoint _p(double lat, double lng, {int segment = 0, int second = 0}) =>
    JourneyPoint(
      recordedAt: DateTime.utc(2026, 9, 25, 10, 0, second),
      latitude: lat,
      longitude: lng,
      accuracyMeters: 5,
      segmentNumber: segment,
    );

void main() {
  test('encodes the reference polyline', () {
    // Google's documented example.
    expect(
      JourneyPreview.encode([
        _p(38.5, -120.2),
        _p(40.7, -120.95),
        _p(43.252, -126.453),
      ]),
      '_p~iF~ps|U_ulLnnqC_mqNvxq`@',
    );
  });

  test('thins long routes, keeping segment ends and gaps', () {
    final route = JourneyRoute([
      for (var i = 0; i < 1000; i++) _p(-1.3 + i / 1e5, 36.8),
      for (var i = 0; i < 500; i++) _p(-1.0 + i / 1e5, 36.9, segment: 1),
    ]);
    final thin = JourneyPreview.thin(route);
    expect(thin, hasLength(2));
    final count = thin[0].length + thin[1].length;
    expect(count, lessThanOrEqualTo(JourneyPreview.maxPoints));
    expect(thin[0].first, route.segments[0].first);
    expect(thin[0].last, route.segments[0].last);
    expect(thin[1].last, route.segments[1].last);
  });

  test('short routes are left alone', () {
    final route = JourneyRoute([_p(-1.3, 36.8), _p(-1.29, 36.81)]);
    expect(JourneyPreview.thin(route).single, hasLength(2));
  });
}
