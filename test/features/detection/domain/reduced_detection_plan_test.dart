import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/detection/domain/detection_status.dart';
import 'package:kaunti47_v2/src/features/detection/domain/reduced_detection_plan.dart';

void main() {
  final now = DateTime.utc(2026, 11, 27, 10);

  test('a drop schedules one notice 24 h after it began', () {
    final plan = ReducedDetectionPlan.decide(
      tier: DetectionTier.catchUp,
      now: now,
    );
    expect(plan.action, ReducedAction.schedule);
    expect(plan.at, now.add(const Duration(hours: 24)));
    expect(plan.since, now);
  });

  test('already scheduled this episode never schedules again', () {
    final plan = ReducedDetectionPlan.decide(
      tier: DetectionTier.off,
      now: now.add(const Duration(days: 3)),
      since: now,
      scheduledThisEpisode: true,
    );
    expect(plan.action, ReducedAction.none);
  });

  test('recovering cancels and ends the episode', () {
    final plan = ReducedDetectionPlan.decide(
      tier: DetectionTier.live,
      now: now,
      since: now.subtract(const Duration(hours: 5)),
      scheduledThisEpisode: true,
    );
    expect(plan.action, ReducedAction.cancel);
  });

  test('live with nothing pending does nothing', () {
    expect(
      ReducedDetectionPlan.decide(tier: DetectionTier.live, now: now).action,
      ReducedAction.none,
    );
  });

  test('a second episode after recovery gets its own notice', () {
    final plan = ReducedDetectionPlan.decide(tier: DetectionTier.off, now: now);
    expect(plan.action, ReducedAction.schedule);
  });

  test('copy names the cause', () {
    expect(
      ReducedDetectionPlan.copy(DetectionReason.backgroundMissing).body,
      contains('All the time'),
    );
    expect(
      ReducedDetectionPlan.copy(DetectionReason.servicesOff).title,
      'Location is off',
    );
  });
}
