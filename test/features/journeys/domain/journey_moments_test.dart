import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/journeys/domain/journey_moments.dart';
import 'package:kaunti47_v2/src/features/journeys/domain/journey_point.dart';

JourneyPoint _p(int minute, double lat, {int segment = 0}) => JourneyPoint(
  recordedAt: DateTime.utc(2026, 9, 25, 10, minute),
  latitude: lat,
  longitude: 36.82,
  accuracyMeters: 5,
  segmentNumber: segment,
);

void main() {
  test('a recording break is a moment at the last point before it', () {
    final moments = JourneyMoments.find([
      _p(0, -1.30),
      _p(1, -1.29),
      _p(26, -1.10, segment: 1),
    ]);
    expect(moments, hasLength(1));
    expect(moments.single.kind, JourneyMomentKind.recordingBreak);
    expect(moments.single.index, 1);
    expect(moments.single.duration, const Duration(minutes: 25));
  });

  test('staying put for 10+ minutes is a long stop; a short one is not', () {
    final moments = JourneyMoments.find([
      _p(0, -1.30),
      _p(1, -1.29), // arrives
      _p(6, -1.2901), // ~11 m away
      _p(13, -1.2902), // still there, 12 min after arriving
      _p(14, -1.28), // leaves
      _p(15, -1.2801), // 1 min pause: too short
      _p(16, -1.27),
    ]);
    expect(moments, hasLength(1));
    expect(moments.single.kind, JourneyMomentKind.longStop);
    expect(moments.single.index, 1);
    expect(moments.single.duration, const Duration(minutes: 12));
  });

  test('a county crossing needs the new county to hold', () {
    // Latitude stands in for the county: north of -1.2 is county 22.
    int? county(double lat, double lng) => lat > -1.2 ? 22 : 47;
    final moments = JourneyMoments.find(
      [
        _p(0, -1.30),
        _p(1, -1.19), // jitter across the line…
        _p(2, -1.21), // …and back: not a crossing
        _p(3, -1.19),
        _p(4, -1.18),
        _p(5, -1.17),
      ],
      countyAt: county,
      countyName: (code) => code == 22 ? 'Kiambu' : 'Nairobi',
    );
    expect(moments, hasLength(1));
    expect(moments.single.kind, JourneyMomentKind.countyCrossing);
    expect(moments.single.index, 5);
    expect(moments.single.name, 'Kiambu');
  });

  test('one point at the route end does not confirm a county crossing', () {
    int? county(double lat, double lng) => lat > -1.2 ? 22 : 47;
    final moments = JourneyMoments.find(
      [_p(0, -1.30), _p(1, -1.29), _p(2, -1.19)],
      countyAt: county,
    );
    expect(moments, isEmpty);
  });

  test('unknown boundary points break a crossing candidate', () {
    int? county(double lat, double lng) {
      if (lat == -1.20) return null;
      return lat > -1.2 ? 22 : 47;
    }
    final moments = JourneyMoments.find(
      [
        _p(0, -1.30),
        _p(1, -1.19),
        _p(2, -1.18),
        _p(3, -1.20),
        _p(4, -1.17),
        _p(5, -1.16),
        _p(6, -1.15),
      ],
      countyAt: county,
    );
    expect(moments, hasLength(1));
    expect(moments.single.index, 6);
  });

  test('places within 10 km show once, at the closest point', () {
    JourneyPlaceMark place(String name, double lat, {bool saved = false}) =>
        JourneyPlaceMark(
          id: name,
          countyCode: 47,
          name: name,
          latitude: lat,
          longitude: 36.82,
          saved: saved,
        );
    final moments = JourneyMoments.find(
      [_p(0, -1.30), _p(1, -1.29), _p(2, -1.28), _p(3, -1.27)],
      places: [
        place('Near', -1.2805, saved: true), // ~55 m from point 2
        place('Nearby', -1.20), // ~7.8 km past the last point
        place('Far', -1.10), // ~19 km: too far
      ],
    );
    expect(moments.map((m) => m.name), ['Near', 'Nearby']);
    expect(moments.first.kind, JourneyMomentKind.savedPlace);
    expect(moments.first.index, 2);
    expect(moments.first.distanceMeters, closeTo(56, 5));
    expect(moments.last.kind, JourneyMomentKind.nearbyPlace);
    expect(moments.last.index, 3);
  });

  test('the next stop is strictly after the position', () {
    const moments = [
      JourneyMoment(kind: JourneyMomentKind.longStop, index: 2),
      JourneyMoment(kind: JourneyMomentKind.savedPlace, index: 2, name: 'A'),
      JourneyMoment(kind: JourneyMomentKind.countyCrossing, index: 5),
    ];
    expect(JourneyMoments.nextStopAfter(0, moments), 2);
    // Paused at 2: resuming heads for 5, not 2 again.
    expect(JourneyMoments.nextStopAfter(2, moments), 5);
    expect(JourneyMoments.nextStopAfter(5.5, moments), isNull);
    expect(JourneyMoments.at(2, moments), hasLength(2));
  });
}
