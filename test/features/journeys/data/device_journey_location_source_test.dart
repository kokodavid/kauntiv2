import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/journeys/data/device_journey_location_source.dart';
import 'package:location/location.dart';

void main() {
  final base = <String, dynamic>{
    'latitude': -1.286389,
    'longitude': 36.817223,
    'accuracy': 8.0,
    'time': 1790337600123.0,
    'isMock': false,
  };

  test('converts a native fix without losing milliseconds', () {
    final fix = DeviceJourneyLocationSource.usableFix(
      LocationData.fromJson(base),
    );
    expect(fix?.recordedAt.millisecondsSinceEpoch, 1790337600123);
    expect(fix?.latitude, -1.286389);
  });

  test('ignores mock, missing and inaccurate fixes', () {
    for (final change in [
      {'isMock': true},
      {'accuracy': null},
      {'accuracy': 120.0},
      {'time': null},
      {'latitude': 91.0},
    ]) {
      expect(
        DeviceJourneyLocationSource.usableFix(
          LocationData.fromJson({...base, ...change}),
        ),
        isNull,
      );
    }
  });
}
