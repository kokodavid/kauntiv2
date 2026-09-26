import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/core/widgets/app_place_row.dart';
import 'package:kaunti47_v2/src/features/badges/application/badges_providers.dart';
import 'package:kaunti47_v2/src/features/badges/domain/badge_collection.dart';
import 'package:kaunti47_v2/src/features/badges/domain/county_badge_detail.dart';
import 'package:kaunti47_v2/src/features/badges/presentation/badge_detail_sheet.dart';

Widget _app(CountyBadge badge, CountyBadgeDetail detail, {
  VoidCallback? onOpenCounty,
  ValueChanged<String>? onOpenPlace,
}) => ProviderScope(
  overrides: [
    countyBadgeDetailProvider(badge.county.code).overrideWith(
      (ref) async => detail,
    ),
    badgeUserLocationProvider.overrideWith(
      (ref) async => (latitude: -1.28, longitude: 36.82),
    ),
  ],
  child: MaterialApp(
    home: Scaffold(
      body: BadgeDetailSheet(
        badge: badge,
        claimed: 12,
        total: 47,
        onOpenCounty: onOpenCounty,
        onOpenPlace: onOpenPlace,
      ),
    ),
  ),
);

void main() {
  final collection = BadgeCollection.from(
    visitStates: const {47: 'explored', 22: 'passed_through'},
    ranks: const {47: 'regular'},
  );
  CountyBadge badge(int code) =>
      collection.badges.firstWhere((b) => b.county.code == code);

  testWidgets('an earned badge: date, next depth, time there, share', (
    tester,
  ) async {
    var opened = 0;
    await tester.pumpWidget(
      _app(
        badge(47),
        CountyBadgeDetail(
          earnedAt: DateTime(2026, 3, 12, 10),
          exploredVisits: 4,
          exploredMonths: 3,
          lastVisitedAt: DateTime(2026, 9, 20, 9),
          journeys: 2,
          journeyMeters: 38400,
        ),
        onOpenCounty: () => opened++,
      ),
    );
    await tester.pump();

    expect(find.text('Nairobi County'), findsOneWidget);
    expect(find.text('Regular · 12 of 47 counties'), findsOneWidget);
    expect(find.text('Earned 12 Mar 2026'), findsOneWidget);
    expect(
      find.text('2 more visits, in 2 different months, to become a local '
          'expert.'),
      findsOneWidget,
    );
    expect(find.text('Your time in Nairobi'), findsOneWidget);
    expect(find.text('4 visits'), findsOneWidget);
    expect(find.text('3 months'), findsOneWidget);
    expect(find.text('20 Sep 2026'), findsOneWidget);
    expect(find.text('2 Journeys'), findsOneWidget);
    expect(find.text('38 km'), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);

    await tester.ensureVisible(find.text('View county'));
    await tester.tap(find.text('View county'));
    expect(opened, 1);
  });

  testWidgets('not yet earned: how to earn it and places to start', (
    tester,
  ) async {
    final opened = <String>[];
    await tester.pumpWidget(
      _app(
        badge(22),
        const CountyBadgeDetail(
          suggestedPlaces: [
            BadgeSuggestedPlace(
              id: 'p2',
              name: 'Far Park',
              type: 'park',
              latitude: -1.0,
              longitude: 36.82,
            ),
            BadgeSuggestedPlace(
              id: 'p1',
              name: 'Karura Forest',
              type: 'park',
              summary: 'Urban forest',
              latitude: -1.24,
              longitude: 36.83,
            ),
          ],
        ),
        onOpenPlace: opened.add,
      ),
    );
    await tester.pump();

    expect(find.text('Share'), findsNothing);
    expect(find.textContaining('Spend about 2 hours here'), findsOneWidget);
    await tester.pump();
    expect(find.text('Nearest places to start'), findsOneWidget);
    // Nearest first, with its distance.
    final titles = tester
        .widgetList<AppPlaceRow>(find.byType(AppPlaceRow))
        .map((row) => row.title);
    expect(titles, ['Karura Forest', 'Far Park']);
    expect(find.text('· 4.6 km'), findsOneWidget);
    await tester.ensureVisible(find.text('Karura Forest'));
    await tester.tap(find.text('Karura Forest'));
    expect(opened, ['p1']);
  });
}
