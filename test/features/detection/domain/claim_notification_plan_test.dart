import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/detection/domain/claim_notification_plan.dart';
import 'package:kaunti47_v2/src/features/detection/domain/visit_models.dart';

void main() {
  const dwell = Duration(hours: 2);
  final t0 = DateTime.utc(2026, 11, 27, 10);

  CountyArrivalNudge nudge(int code, DateTime at) =>
      CountyArrivalNudge(countyCode: code, enteredAt: at);

  test('schedules entry + dwell for a new candidate', () {
    final plan = ClaimNotificationPlan.build(
      candidates: [nudge(42, t0)],
      scheduled: {},
      dwell: dwell,
      now: t0.add(const Duration(minutes: 1)),
    );
    expect(plan.schedule.single.claimsAt, t0.add(dwell));
    expect(plan.cancel, isEmpty);
  });

  test('cancels when the candidate is gone (left early)', () {
    final plan = ClaimNotificationPlan.build(
      candidates: const [],
      scheduled: {42},
      dwell: dwell,
      now: t0.add(const Duration(minutes: 30)),
    );
    expect(plan.schedule, isEmpty);
    expect(plan.cancel, {42});
  });

  test('skips the home county and claims already due', () {
    final plan = ClaimNotificationPlan.build(
      candidates: [nudge(47, t0), nudge(1, t0.subtract(const Duration(hours: 3)))],
      scheduled: {1},
      dwell: dwell,
      now: t0.add(const Duration(minutes: 5)),
      homeCounty: 47,
    );
    expect(plan.schedule, isEmpty);
    expect(plan.cancel, {1});
  });
}
