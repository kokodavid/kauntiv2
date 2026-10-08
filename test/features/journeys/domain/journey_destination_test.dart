import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/journeys/domain/journey_destination.dart';

void main() {
  const stop = JourneyStop(
    placeId: 'p1',
    name: 'Fourteen Falls',
    latitude: -1.2,
    longitude: 37.1,
  );

  test('stops survive a JSON round trip in order', () {
    const second = JourneyStop(
      placeId: 'p2',
      name: 'Thika Falls',
      latitude: -1,
      longitude: 37.07,
    );
    final back = JourneyStop.listFrom(JourneyStop.encodeList([stop, second]));
    expect(back.map((s) => s.placeId), ['p1', 'p2']);
    expect(back.last.longitude, 37.07);
  });

  test('unreadable stop data is ignored', () {
    expect(JourneyStop.listFrom(null), isEmpty);
    expect(JourneyStop.listFrom('not json'), isEmpty);
    expect(JourneyStop.listFrom([{'name': 'no id'}, 3]), isEmpty);
  });

  test('a destination with too many or invalid stops is not valid', () {
    JourneyDestination with_(List<JourneyStop> stops) => JourneyDestination(
      placeId: 'd',
      name: 'Dest',
      latitude: -1,
      longitude: 37,
      viaStops: stops,
    );
    expect(with_([stop]).isValid, isTrue);
    expect(
      with_(List.filled(JourneyDestination.maxViaStops + 1, stop)).isValid,
      isFalse,
    );
    expect(
      with_(const [
        JourneyStop(placeId: 'x', name: 'Bad', latitude: 99, longitude: 0),
      ]).isValid,
      isFalse,
    );
  });
}
