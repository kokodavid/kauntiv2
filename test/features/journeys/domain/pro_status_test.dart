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
    expect(ProStatus(active: false, checkedAt: now).allowsStartAt(now), isFalse);
  });

  test('a cached status only counts while recent', () {
    final recent = ProStatus(
      active: true,
      checkedAt: now.subtract(const Duration(days: 6)),
    );
    final stale = ProStatus(
      active: true,
      checkedAt: now.subtract(const Duration(days: 8)),
    );
    expect(recent.allowsStartAt(now, fromCache: true), isTrue);
    expect(stale.allowsStartAt(now, fromCache: true), isFalse);
    expect(stale.allowsStartAt(now), isTrue);
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
      'Journey on 25 Sep 2026',
    );
  });
}
