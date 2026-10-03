import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/journeys/domain/journey_media_capture.dart';
import 'package:kaunti47_v2/src/features/journeys/domain/journey_moments.dart';
import 'package:kaunti47_v2/src/features/journeys/domain/journey_point.dart';

JourneyPoint _p(int minute, double lat, {int segment = 0, double? altitude}) =>
    JourneyPoint(
      recordedAt: DateTime.utc(2026, 9, 25, 10, minute),
      latitude: lat,
      longitude: 36.82,
      accuracyMeters: 5,
      segmentNumber: segment,
      altitudeMeters: altitude,
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
    final moments = JourneyMoments.find([
      _p(0, -1.30),
      _p(1, -1.29),
      _p(2, -1.19),
    ], countyAt: county);
    expect(moments, isEmpty);
  });

  test('unknown boundary points break a crossing candidate', () {
    int? county(double lat, double lng) {
      if (lat == -1.20) return null;
      return lat > -1.2 ? 22 : 47;
    }

    final moments = JourneyMoments.find([
      _p(0, -1.30),
      _p(1, -1.19),
      _p(2, -1.18),
      _p(3, -1.20),
      _p(4, -1.17),
      _p(5, -1.16),
      _p(6, -1.15),
    ], countyAt: county);
    expect(moments, hasLength(1));
    expect(moments.single.index, 6);
  });

  test('a photo lands at the point closest to when it was taken', () {
    JourneyMediaItem photo(String id, int minute) => JourneyMediaItem(
      id: id,
      url: 'https://example.com/$id.jpg',
      capturedAt: DateTime.utc(2026, 9, 25, 10, minute),
    );
    final moments = JourneyMoments.find(
      [_p(0, -1.30), _p(1, -1.29), _p(2, -1.28), _p(3, -1.27)],
      photos: [
        photo('near-2', 2), // taken right at point 2
        photo('between', 0), // taken before point 0, closest to point 0
      ],
    );
    expect(moments.map((m) => m.kind), [
      JourneyMomentKind.photo,
      JourneyMomentKind.photo,
    ]);
    final byId = {for (final m in moments) m.photo!.id: m};
    expect(byId['near-2']!.index, 2);
    expect(byId['between']!.index, 0);
    expect(byId['near-2']!.isPhoto, isTrue);
  });

  test('the highest point becomes a moment there', () {
    final moments = JourneyMoments.find([
      _p(0, -1.30, altitude: 1600),
      _p(1, -1.29, altitude: 1680), // the peak
      _p(2, -1.28, altitude: 1650),
      _p(3, -1.27, altitude: 1610),
    ]);
    expect(moments.map((m) => m.kind), [JourneyMomentKind.elevationPeak]);
    expect(moments.single.index, 1);
    expect(moments.single.elevationMeters, 1680);
  });

  test('a peak under the minimum gain is not a moment', () {
    final moments = JourneyMoments.find([
      _p(0, -1.30, altitude: 1600),
      _p(1, -1.29, altitude: 1615), // only 15 m above the lowest: noise
      _p(2, -1.28, altitude: 1605),
    ]);
    expect(moments, isEmpty);
  });

  test('no altitude data means no elevation-peak moment', () {
    final moments = JourneyMoments.find([_p(0, -1.30), _p(1, -1.29)]);
    expect(moments, isEmpty);
  });

  test('the next stop is strictly after the position', () {
    const moments = [
      JourneyMoment(kind: JourneyMomentKind.longStop, index: 2),
      JourneyMoment(kind: JourneyMomentKind.recordingBreak, index: 2),
      JourneyMoment(kind: JourneyMomentKind.countyCrossing, index: 5),
    ];
    expect(JourneyMoments.nextStopAfter(0, moments), 2);
    // Paused at 2: resuming heads for 5, not 2 again.
    expect(JourneyMoments.nextStopAfter(2, moments), 5);
    expect(JourneyMoments.nextStopAfter(5.5, moments), isNull);
    expect(JourneyMoments.at(2, moments), hasLength(2));
  });
}
