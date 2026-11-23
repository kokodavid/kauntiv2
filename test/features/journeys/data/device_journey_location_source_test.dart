import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/journeys/data/device_journey_location_source.dart';
import 'package:kaunti47_v2/src/features/journeys/domain/journey_transport_mode.dart';
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
    // Start first clears a service left alive from a previous process; both
    // stop calls also disable it so recovery teardown remains idempotent.
    expect(disableCalls, 3);
  });

  test('uses less frequent, lighter sampling for slower travel modes', () {
    final drive = DeviceJourneyLocationSource.samplingForMode(
      JourneyTransportMode.drive,
    );
    final cycle = DeviceJourneyLocationSource.samplingForMode(
      JourneyTransportMode.cycle,
    );
    final walk = DeviceJourneyLocationSource.samplingForMode(
      JourneyTransportMode.walk,
    );

    // Walking and cycling cover ground slowly enough that a less frequent,
    // lower-accuracy fix barely changes the recorded route but meaningfully
    // cuts how long the GPS chip stays active -- so unlike before, their
    // distance filter is now looser too, not just their time interval.
    expect(cycle.intervalMs, greaterThan(drive.intervalMs));
    expect(cycle.backgroundIntervalMs, greaterThan(drive.backgroundIntervalMs));
    expect(cycle.distanceMeters, greaterThan(drive.distanceMeters));
    expect(cycle.accuracy, LocationAccuracy.balanced);

    expect(walk.intervalMs, greaterThan(cycle.intervalMs));
    expect(walk.backgroundIntervalMs, greaterThan(cycle.backgroundIntervalMs));
    expect(walk.distanceMeters, greaterThan(cycle.distanceMeters));
    expect(walk.accuracy, LocationAccuracy.balanced);

    // Driving still needs a frequent, high-accuracy fix to track a fast
    // route faithfully.
    expect(drive.accuracy, LocationAccuracy.high);
  });
}
