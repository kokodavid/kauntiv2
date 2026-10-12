import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/core/domain/saved_at_label.dart';

void main() {
  final now = DateTime(2026, 10, 12, 15);

  test('no time, no label', () => expect(savedAtLabel(null, now), isNull));

  test('today reads as a time, or just now', () {
    expect(savedAtLabel(DateTime(2026, 10, 12, 9, 41), now), 'Saved 9:41 AM');
    expect(
      savedAtLabel(DateTime(2026, 10, 12, 9, 41), now, verboseToday: true),
      'Saved today, 9:41 AM',
    );
    expect(
      savedAtLabel(
        DateTime(2026, 10, 12, 14, 59, 40),
        DateTime(2026, 10, 12, 15),
      ),
      'Saved just now',
    );
  });

  test('older copies read as days, weeks, then a date', () {
    expect(savedAtLabel(DateTime(2026, 10, 11, 9), now), 'Saved yesterday');
    expect(savedAtLabel(DateTime(2026, 10, 9, 9), now), 'Saved 3 days ago');
    expect(savedAtLabel(DateTime(2026, 9, 21, 9), now), 'Saved 3 weeks ago');
    expect(savedAtLabel(DateTime(2026, 8, 12, 9), now), 'Saved 12 Aug');
  });
}
