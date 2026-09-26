import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/journeys/domain/journey_county_split.dart';
import 'package:kaunti47_v2/src/features/journeys/domain/journey_point.dart';

JourneyPoint _p(int minute, double lat, {int segment = 0}) => JourneyPoint(
  recordedAt: DateTime.utc(2026, 9, 26, 10, minute),
  latitude: lat,
  longitude: 36.82,
  accuracyMeters: 5,
  segmentNumber: segment,
);

void main() {
  // Latitude stands in for the county: north of -1.2 is 22, else 47;
  // beyond -1.0 is outside Kenya.
  int? county(double lat, double lng) =>
      lat > -1.0 ? null : (lat > -1.2 ? 22 : 47);

  test('distance goes to the county each step ends in', () {
    final meters = JourneyCountySplit.split([
      _p(0, -1.30),
      _p(1, -1.25), // 47
      _p(2, -1.15), // 22
      _p(3, -1.10), // 22
    ], county);
    expect(meters.keys, unorderedEquals([47, 22]));
    expect(meters[47], closeTo(5560, 20));
    expect(meters[22], closeTo(11120 + 5560, 40));
  });

  test('pauses and points outside Kenya add nothing', () {
    final meters = JourneyCountySplit.split([
      _p(0, -1.30),
      _p(30, -1.15, segment: 1), // new segment: no jump distance
      _p(31, -0.90, segment: 1), // outside Kenya
    ], county);
    expect(meters, {47: 0.0, 22: 0.0});
  });
}
