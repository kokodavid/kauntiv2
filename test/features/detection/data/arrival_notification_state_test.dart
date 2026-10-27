import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/detection/data/arrival_notification_state.dart';
import 'package:kaunti47_v2/src/features/detection/domain/visit_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const state = ArrivalNotificationState();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('defaults: enabled, no home county, not in the foreground', () async {
    expect(await state.enabled(), isTrue);
    expect(await state.homeCounty(), isNull);
    expect(await state.inForeground(), isFalse);
    expect(await state.permissionAsked(), isFalse);
  });

  test('mirrors the home county and the switch', () async {
    await state.setHomeCounty(47);
    await state.setEnabled(false);
    expect(await state.homeCounty(), 47);
    expect(await state.enabled(), isFalse);
    await state.setHomeCounty(null);
    expect(await state.homeCounty(), isNull);
  });

  test('the foreground heartbeat expires and can be cleared', () async {
    final beat = DateTime.utc(2026, 10, 12, 9);
    await state.setForeground(true, now: beat);
    expect(
      await state.inForeground(now: beat.add(const Duration(seconds: 30))),
      isTrue,
    );
    expect(
      await state.inForeground(now: beat.add(const Duration(seconds: 50))),
      isFalse,
    );
    await state.setForeground(false);
    expect(await state.inForeground(now: beat), isFalse);
  });

  test('a notified crossing is remembered with its county cooldown', () async {
    final entered = DateTime.utc(2026, 10, 12, 8);
    final notifiedAt = DateTime.utc(2026, 10, 12, 8, 1);
    await state.markNotified(
      CountyArrivalNudge(countyCode: 12, enteredAt: entered),
      now: notifiedAt,
    );
    expect(await state.notifiedKeys(), {'12@${entered.toIso8601String()}'});
    expect((await state.lastNotifiedByCounty())[12], notifiedAt);
  });

  test('clear forgets everything', () async {
    await state.setHomeCounty(47);
    await state.markPermissionAsked();
    await state.clear();
    expect(await state.homeCounty(), isNull);
    expect(await state.permissionAsked(), isFalse);
  });

  test('a dismissed prompt comes back after the snooze', () async {
    final t = DateTime.utc(2026, 10, 21, 12);
    expect(await state.promptDismissed(now: t), isFalse);
    await state.dismissPrompt(now: t);
    expect(
      await state.promptDismissed(now: t.add(const Duration(days: 2))),
      isTrue,
    );
    expect(
      await state.promptDismissed(
        now: t.add(ArrivalNotificationState.promptSnooze),
      ),
      isFalse,
    );
  });
}
