import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/journeys/domain/motion_rules.dart';

void main() {
  final t0 = DateTime.utc(2026, 10, 7, 12);
  DateTime at(int seconds) => t0.add(Duration(seconds: seconds));

  test('starts unknown and settles still on a first slow fix', () {
    final tracker = MotionTracker();
    expect(tracker.state, MotionState.unknown);
    expect(tracker.addFix(speed: 0.1, at: at(0)), MotionState.still);
  });

  test('driving speed held for 15 s is moving', () {
    final tracker = MotionTracker();
    expect(tracker.addFix(speed: 12, at: at(0)), MotionState.unknown);
    expect(tracker.addFix(speed: 12, at: at(10)), MotionState.unknown);
    expect(tracker.addFix(speed: 12, at: at(16)), MotionState.moving);
  });

  test('a walking pace counts', () {
    final tracker = MotionTracker();
    for (var s = 0; s <= 20; s += 5) {
      tracker.addFix(speed: 1.4, at: at(s));
    }
    expect(tracker.state, MotionState.moving);
  });

  test('GPS noise on a table is not movement', () {
    final tracker = MotionTracker();
    for (var s = 0; s <= 60; s += 5) {
      tracker.addFix(speed: 0.4, at: at(s));
    }
    expect(tracker.state, MotionState.still);
  });

  test('a brief stop does not end moving', () {
    final tracker = MotionTracker();
    for (var s = 0; s <= 20; s += 5) {
      tracker.addFix(speed: 10, at: at(s));
    }
    for (var s = 25; s <= 60; s += 5) {
      tracker.addFix(speed: 0, at: at(s));
    }
    expect(tracker.state, MotionState.moving);
  });

  test('90 s at rest ends moving', () {
    final tracker = MotionTracker();
    for (var s = 0; s <= 20; s += 5) {
      tracker.addFix(speed: 10, at: at(s));
    }
    for (var s = 25; s <= 120; s += 5) {
      tracker.addFix(speed: 0, at: at(s));
    }
    expect(tracker.state, MotionState.still);
  });

  test('a gap between fixes breaks the run', () {
    final tracker = MotionTracker();
    tracker.addFix(speed: 10, at: at(0));
    tracker.addFix(speed: 10, at: at(60));
    expect(tracker.addFix(speed: 10, at: at(70)), MotionState.unknown);
  });

  test('missing fixes mean still', () {
    final tracker = MotionTracker();
    for (var s = 0; s <= 20; s += 5) {
      tracker.addFix(speed: 10, at: at(s));
    }
    expect(tracker.tick(at(60)), MotionState.moving);
    expect(tracker.tick(at(115)), MotionState.still);
  });

  test('null and invalid speeds are ignored', () {
    final tracker = MotionTracker();
    expect(tracker.addFix(speed: null, at: at(0)), MotionState.unknown);
    expect(tracker.addFix(speed: double.nan, at: at(1)), MotionState.unknown);
    expect(tracker.addFix(speed: -1, at: at(2)), MotionState.unknown);
  });
}
