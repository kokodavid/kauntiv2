import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/trip_plans/domain/plan_calendar.dart';

void main() {
  test('months run from the first date\'s month to the last date\'s', () {
    final months = PlanCalendar.months(
      DateTime(2026, 11, 20),
      DateTime(2027, 2, 3),
    );
    expect(months, [
      DateTime(2026, 11),
      DateTime(2026, 12),
      DateTime(2027, 1),
      DateTime(2027, 2),
    ]);
  });

  test('a month grid starts on Monday and fills whole weeks', () {
    // 1 Oct 2026 is a Thursday: three blanks, then 1..31, then blanks.
    final grid = PlanCalendar.grid(DateTime(2026, 10));
    expect(grid.length % 7, 0);
    expect(grid.take(3), everyElement(isNull));
    expect(grid[3], DateTime(2026, 10, 1));
    expect(grid.whereType<DateTime>().length, 31);
    expect(grid.whereType<DateTime>().last, DateTime(2026, 10, 31));
  });

  test('a month starting on Monday has no leading blanks', () {
    // 1 Feb 2027 is a Monday.
    final grid = PlanCalendar.grid(DateTime(2027, 2));
    expect(grid.first, DateTime(2027, 2, 1));
  });

  test('spoken dates read in full', () {
    expect(
      PlanCalendar.spoken(DateTime(2026, 10, 30)),
      'Friday 30 October 2026',
    );
  });
}
