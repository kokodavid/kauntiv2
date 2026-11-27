import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/detection/data/detection_heartbeat.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('nothing is recorded until something runs', () async {
    const beat = DetectionHeartbeat();
    expect(await beat.lastCycle(), isNull);
    expect(await beat.lastGeofence(), isNull);
  });

  test('cycle and geofence times are kept separately', () async {
    const beat = DetectionHeartbeat();
    final cycle = DateTime.utc(2026, 11, 27, 8);
    final geofence = DateTime.utc(2026, 11, 26, 20);
    await beat.markCycle(cycle);
    await beat.markGeofence(geofence);
    expect(await beat.lastCycle(), cycle);
    expect(await beat.lastGeofence(), geofence);
  });
}
