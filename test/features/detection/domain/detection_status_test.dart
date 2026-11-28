import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/detection/domain/detection_status.dart';

DetectionStatus _derive({
  bool background = true,
  bool foreground = true,
  bool services = true,
}) => DetectionStatus.derive(
  backgroundGranted: background,
  foregroundGranted: foreground,
  servicesEnabled: services,
);

void main() {
  test('Always granted is live', () {
    final s = _derive();
    expect(s.tier, DetectionTier.live);
    expect(s.reason, DetectionReason.none);
  });

  test('While using only is catch-up', () {
    final s = _derive(background: false);
    expect(s.tier, DetectionTier.catchUp);
    expect(s.reason, DetectionReason.backgroundMissing);
  });

  test('no permission at all is off', () {
    final s = _derive(background: false, foreground: false);
    expect(s.tier, DetectionTier.off);
    expect(s.reason, DetectionReason.noPermission);
  });

  test('location switched off beats any permission', () {
    final s = _derive(services: false);
    expect(s.tier, DetectionTier.off);
    expect(s.reason, DetectionReason.servicesOff);
  });

  test('the heartbeat is carried and never lowers the tier', () {
    final old = DateTime.utc(2026, 1, 1);
    final s = DetectionStatus.derive(
      backgroundGranted: true,
      foregroundGranted: true,
      servicesEnabled: true,
      lastCycleAt: old,
      lastGeofenceAt: old,
    );
    expect(s.tier, DetectionTier.live);
    expect(s.lastGeofenceAt, old);
    final beat = s.withHeartbeat(lastCycleAt: DateTime.utc(2026, 1, 2));
    expect(beat.lastCycleAt, DateTime.utc(2026, 1, 2));
    expect(beat.lastGeofenceAt, old);
  });
}
