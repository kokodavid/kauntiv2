import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/detection/domain/trip_start_reminder_rules.dart';

void main() {
  final now = DateTime.utc(2026, 11, 25, 12);

  bool due({
    bool enabled = true,
    bool eligible = true,
    bool recording = false,
    DateTime? ended,
    DateTime? reminded,
  }) => TripStartReminderRules.isDue(
    enabled: enabled,
    eligible: eligible,
    recording: recording,
    now: now,
    lastTripEndedAt: ended,
    lastRemindedAt: reminded,
  );

  test('is due on a first crossing for someone who can start a Trip', () {
    expect(due(), isTrue);
  });

  test('is quiet when the switch is off or a Trip cannot start', () {
    expect(due(enabled: false), isFalse);
    expect(due(eligible: false), isFalse);
  });

  test('is quiet while a Trip is recording', () {
    expect(due(recording: true), isFalse);
  });

  test('is quiet for 30 minutes after a Trip ended, then due again', () {
    expect(due(ended: now.subtract(const Duration(minutes: 10))), isFalse);
    expect(due(ended: now.subtract(const Duration(minutes: 31))), isTrue);
  });

  test('sends at most one reminder in 24 hours', () {
    expect(due(reminded: now.subtract(const Duration(hours: 23))), isFalse);
    expect(due(reminded: now.subtract(const Duration(hours: 25))), isTrue);
  });
}
