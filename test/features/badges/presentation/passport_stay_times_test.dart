import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/badges/domain/county_badge_detail.dart';
import 'package:kaunti47_v2/src/features/badges/presentation/passport_stay_times.dart';

Widget _wrap(CountyBadgeDetail detail) => MaterialApp(
  home: Scaffold(body: PassportStayTimes(detail: detail)),
);

void main() {
  testWidgets('shows nothing when no stay has a recorded length', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const CountyBadgeDetail()));
    expect(find.textContaining('timed visit'), findsNothing);
  });

  testWidgets('adds the stays up without listing each visit', (tester) async {
    await tester.pumpWidget(
      _wrap(
        CountyBadgeDetail(
          timedVisits: 2,
          totalStay: const Duration(minutes: 90),
          recentStays: [
            CountyStay(
              enteredAt: DateTime(2026, 11, 20, 10),
              explored: false,
              stay: const Duration(minutes: 50),
            ),
            CountyStay(
              enteredAt: DateTime(2026, 11, 18, 10),
              explored: false,
              stay: const Duration(minutes: 40),
            ),
          ],
        ),
      ),
    );
    expect(find.text('About 1 h 30 across 2 timed visits'), findsOneWidget);
    expect(find.text('50 min'), findsNothing);
    expect(find.textContaining('single stay of 2 hours'), findsOneWidget);
  });

  testWidgets('notes that stays over a day are left out of the total', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        CountyBadgeDetail(
          timedVisits: 1,
          longVisits: 1,
          totalStay: const Duration(minutes: 30),
          recentStays: [
            CountyStay(
              enteredAt: DateTime(2026, 11, 1, 10),
              explored: true,
              stay: const Duration(days: 15),
            ),
          ],
        ),
      ),
    );
    expect(find.textContaining('left out of the total'), findsOneWidget);
  });
}
