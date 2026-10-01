import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/journeys/data/device_journey_location_source.dart';
import 'package:location/location.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
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

  test('accepts zero from the plugin on background disable', () async {
    const channel = MethodChannel('lyokone/location');
    var disableCalls = 0;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'enableBackgroundMode') {
        final enabled = (call.arguments as Map<Object?, Object?>)['enable'];
        if (enabled == false) {
          disableCalls++;
          return 0;
        }
      }
      return 1;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

    final source = DeviceJourneyLocationSource();
    await source.start();
    await source.stop();
    await source.stop();
    expect(disableCalls, 1);
  });
}
