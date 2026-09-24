import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/map_home/application/real_map_start_focus.dart';

void main() {
  const home = (minLng: 36.6, minLat: -1.4, maxLng: 37.1, maxLat: -1.1);

  test('a fix inside Kenya opens on the user', () {
    final focus = RealMapStartFocus.decide(
      location: (latitude: -1.2864, longitude: 36.8172),
      homeCounty: home,
    );
    expect(focus, isA<FocusOnUser>());
  });

  test('a fix outside Kenya (emulator default) opens on the home county', () {
    final focus = RealMapStartFocus.decide(
      location: (latitude: 37.422, longitude: -122.084),
      homeCounty: home,
    );
    expect(focus, isA<FocusOnHomeCounty>());
  });

  test('no fix and no home county falls back to all of Kenya', () {
    final focus = RealMapStartFocus.decide(location: null, homeCounty: null);
    expect(focus, isA<FocusOnKenya>());
  });
}
