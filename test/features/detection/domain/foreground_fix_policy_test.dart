import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/detection/domain/foreground_fix_policy.dart';

void main() {
  final now = DateTime.utc(2026, 11, 27, 10);

  bool read({
    bool forced = false,
    bool pending = false,
    DateTime? last,
  }) => ForegroundFixPolicy.shouldRead(
    forced: forced,
    hasPending: pending,
    now: now,
    lastReadAt: last,
  );

  test('open or resume always reads', () {
    expect(read(forced: true), isTrue);
  });

  test('nothing pending never polls', () {
    expect(read(last: now.subtract(const Duration(hours: 1))), isFalse);
    expect(read(), isFalse);
  });

  test('pending reads every two minutes', () {
    expect(read(pending: true, last: now.subtract(const Duration(minutes: 1))), isFalse);
    expect(read(pending: true, last: now.subtract(const Duration(minutes: 2))), isTrue);
    expect(read(pending: true), isTrue);
  });
}
