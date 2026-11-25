import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/detection/data/trip_start_reminder_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const state = TripStartReminderState();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('starts on, not eligible, not recording, nothing recorded', () async {
    expect(await state.enabled(), isTrue);
    expect(await state.eligible(), isFalse);
    expect(await state.recording(), isFalse);
    expect(await state.lastTripEndedAt(), isNull);
    expect(await state.lastRemindedAt(), isNull);
  });

  test('keeps the mirrored settings', () async {
    await state.setEnabled(false);
    await state.setEligible(true);
    expect(await state.enabled(), isFalse);
    expect(await state.eligible(), isTrue);
  });

  test('stopping a Trip records when it ended; starting does not', () async {
    final at = DateTime.utc(2026, 11, 25, 9);
    await state.setRecording(true);
    expect(await state.recording(), isTrue);
    expect(await state.lastTripEndedAt(), isNull);
    await state.setRecording(false, at: at);
    expect(await state.recording(), isFalse);
    expect(await state.lastTripEndedAt(), at);
  });

  test('remembers when it last reminded', () async {
    final at = DateTime.utc(2026, 11, 25, 9);
    await state.markReminded(now: at);
    expect(await state.lastRemindedAt(), at);
  });
}
