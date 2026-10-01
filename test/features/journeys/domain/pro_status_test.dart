import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/journeys/domain/journey_ids.dart';
import 'package:kaunti47_v2/src/features/journeys/domain/journey_summary.dart';
import 'package:kaunti47_v2/src/features/journeys/domain/pro_status.dart';

void main() {
  final now = DateTime.utc(2026, 9, 25, 12);

  test('an active open-ended period allows a start', () {
    final status = ProStatus(active: true, checkedAt: now);
    expect(status.allowsStartAt(now), isTrue);
  });

  test('a period that has ended does not', () {
    final status = ProStatus(
      active: true,
      checkedAt: now.subtract(const Duration(days: 2)),
      activeUntil: now.subtract(const Duration(hours: 1)),
    );
    expect(status.allowsStartAt(now), isFalse);
    expect(
      ProStatus(active: false, checkedAt: now).allowsStartAt(now),
      isFalse,
    );
  });

  test('ids are version 4 UUIDs', () {
    final id = JourneyIds.newId();
    expect(
      RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      ).hasMatch(id),
      isTrue,
    );
    expect(JourneyIds.newId(), isNot(id));
  });

  test('default titles use the local date', () {
    expect(
      JourneyTitles.defaultFor(DateTime(2026, 9, 25, 9)),
      'Trip on 25 Sep 2026',
    );
  });

  test('a free Trip allowance with slots left allows starting', () {
    final trial = JourneyTrialStatus(
      tripsUsed: 2,
      tripLimit: 3,
      resetsAt: DateTime.utc(2026, 10, 1),
    );
    expect(trial.hasRemaining, isTrue);
    expect(trial.tripsRemaining, 1);
  });

  test('a free Trip allowance used up does not', () {
    final trial = JourneyTrialStatus(
      tripsUsed: 3,
      tripLimit: 3,
      resetsAt: DateTime.utc(2026, 10, 1),
    );
    expect(trial.hasRemaining, isFalse);
    expect(trial.tripsRemaining, 0);
  });
}
