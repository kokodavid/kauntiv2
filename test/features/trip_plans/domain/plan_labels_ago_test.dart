import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/trip_plans/domain/plan_labels.dart';

void main() {
  final now = DateTime(2026, 11, 3, 12);

  test('ago reads naturally and gives up after a week', () {
    expect(PlanLabels.ago(null, now), isNull);
    expect(
      PlanLabels.ago(now.subtract(const Duration(seconds: 30)), now),
      'just now',
    );
    expect(
      PlanLabels.ago(now.subtract(const Duration(minutes: 5)), now),
      '5 min ago',
    );
    expect(
      PlanLabels.ago(now.subtract(const Duration(hours: 3)), now),
      '3 h ago',
    );
    expect(
      PlanLabels.ago(now.subtract(const Duration(days: 2)), now),
      '2 d ago',
    );
    expect(PlanLabels.ago(now.subtract(const Duration(days: 9)), now), isNull);
  });

  test('fresh is the last few minutes', () {
    expect(
      PlanLabels.isFresh(now.subtract(const Duration(minutes: 2)), now),
      isTrue,
    );
    expect(
      PlanLabels.isFresh(now.subtract(const Duration(minutes: 10)), now),
      isFalse,
    );
    expect(PlanLabels.isFresh(null, now), isFalse);
  });
}
