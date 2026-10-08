import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/trip_planner/domain/saved_trip.dart';

void main() {
  test('the key ignores pick order unless the user set the order', () {
    expect(SavedTrip.keyFor(['b', 'a']), SavedTrip.keyFor(['a', 'b']));
    expect(
      SavedTrip.keyFor(['b', 'a'], custom: true),
      isNot(SavedTrip.keyFor(['a', 'b'], custom: true)),
    );
    expect(SavedTrip.keyFor(['a'], custom: true), isNot(SavedTrip.keyFor(['a'])));
  });

  test('suggests a name that fits', () {
    expect(SavedTrip.suggestName('Ol Donyo Sabuk', 0), 'Ol Donyo Sabuk');
    expect(SavedTrip.suggestName('Ol Donyo Sabuk', 1), 'Ol Donyo Sabuk + 1 stop');
    expect(SavedTrip.suggestName('Ol Donyo Sabuk', 3), 'Ol Donyo Sabuk + 3 stops');
    expect(
      SavedTrip.suggestName('x' * 200, 2).length,
      lessThanOrEqualTo(SavedTrip.maxNameLength),
    );
  });

  test('reads a row, and skips one that is incomplete', () {
    final trip = SavedTrip.fromRow({
      'id': 't1',
      'name': 'Day out',
      'destination_place_id': 'p9',
      'stop_place_ids': ['p1', 'p2'],
      'custom_order': true,
    });
    expect(trip?.stopPlaceIds, ['p1', 'p2']);
    expect(trip?.customOrder, isTrue);
    expect(SavedTrip.fromRow({'id': 't1'}), isNull);
  });
}
