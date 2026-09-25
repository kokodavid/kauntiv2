import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/journeys/domain/journey_point.dart';
import 'package:kaunti47_v2/src/features/journeys/domain/journey_route.dart';

JourneyPoint _p(int second, double lat, double lng, int segment) =>
    JourneyPoint(
      recordedAt: DateTime.utc(2026, 9, 25, 10, 0, second),
      latitude: lat,
      longitude: lng,
      accuracyMeters: 5,
      segmentNumber: segment,
    );

void main() {
  final route = JourneyRoute([
    _p(0, -1.2921, 36.8219, 0),
    _p(10, -1.3000, 36.8300, 0),
    // After a pause: a new segment, far away, not measured from the last.
    _p(20, -0.5000, 36.0000, 1),
  ]);

  test('splits segments and measures within them only', () {
    expect(route.segments.map((s) => s.length), [2, 1]);
    expect(route.distanceMeters, inInclusiveRange(1200, 1350));
  });

  test('bounds cover every point', () {
    final b = route.bounds!;
    expect(b.south, -1.3);
    expect(b.north, -0.5);
    expect(b.west, 36.0);
    expect(b.east, 36.83);
    expect(JourneyRoute(const []).bounds, isNull);
  });

  test('GeoJSON draws a line per segment and a lone fix as a point', () {
    final features = route.toGeoJson()['features']! as List<Object?>;
    final types = [
      for (final f in features.cast<Map<String, Object?>>())
        (f['geometry']! as Map<String, Object?>)['type'],
    ];
    expect(types, ['LineString', 'Point']);
  });

  test('formats distance, duration and the live clock', () {
    expect(JourneyFormat.distance(null), '—');
    expect(JourneyFormat.distance(640), '640 m');
    expect(JourneyFormat.distance(12400), '12 km');
    expect(JourneyFormat.distance(3450), '3.5 km');
    expect(JourneyFormat.duration(const Duration(seconds: 45)), '45 s');
    expect(JourneyFormat.duration(const Duration(minutes: 12)), '12 min');
    expect(
      JourneyFormat.duration(const Duration(hours: 1, minutes: 5)),
      '1 h 05 min',
    );
    expect(
      JourneyFormat.clock(const Duration(hours: 0, minutes: 4, seconds: 9)),
      '0:04:09',
    );
  });
}
