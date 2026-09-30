import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/core/widgets/app_shimmer.dart';
import 'package:kaunti47_v2/src/features/badges/application/badges_providers.dart';
import 'package:kaunti47_v2/src/features/badges/domain/badge_collection.dart';
import 'package:kaunti47_v2/src/features/badges/domain/county_badge_detail.dart';
import 'package:kaunti47_v2/src/features/badges/presentation/badge_grid_cell.dart';
import 'package:kaunti47_v2/src/features/badges/presentation/badges_loading.dart';
import 'package:kaunti47_v2/src/features/badges/presentation/badges_screen.dart';

void main() {
  testWidgets('shows the count, tier and every county; tap opens its sheet', (
    tester,
  ) async {
    final opened = <int>[];
    final collection = BadgeCollection.from(
      visitStates: {for (var code = 1; code <= 12; code++) code: 'explored'},
      ranks: const {1: 'regular'},
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          badgeCollectionProvider.overrideWith((ref) async => collection),
          countyBadgeDetailProvider(
            1,
          ).overrideWith((ref) async => const CountyBadgeDetail()),
        ],
        child: MaterialApp(
          home: BadgesScreen(onOpenCounty: (_, code) => opened.add(code)),
        ),
      ),
    );
    await tester.pump();

    await tester.pump(); // the slider measures its first card

    expect(find.text('Collection'), findsOneWidget);
    expect(find.text('Badges'), findsOneWidget);
    expect(find.text('Msafiri'), findsOneWidget); // header pill
    expect(find.text('12'), findsOneWidget);
    expect(find.text('of 47 counties claimed'), findsOneWidget);
    expect(find.text('25% OF KENYA'), findsOneWidget);
    expect(find.text('35 LEFT'), findsOneWidget);
    expect(find.text('ALL 47 COUNTIES'), findsOneWidget);

    // Swipe the slider to the tiers card.
    await tester.drag(find.byType(PageView), const Offset(-600, 0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Next: Mzururaji'), findsOneWidget);
    await tester.ensureVisible(find.text('Next: Mzururaji'));
    await tester.pump(const Duration(milliseconds: 300));

    // Its footer expands the progress to the next medal.
    await tester.tap(find.text('Next: Mzururaji'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(); // apply the slider's measured expanded height
    expect(find.text('12 of 25 counties'), findsOneWidget);
    expect(find.text('Earned'), findsOneWidget);
    expect(find.text('13 to go'), findsNWidgets(2));
    expect(find.text('35 more'), findsOneWidget);

    // Tapping a badge opens its sheet (details load from the provider).
    await tester.ensureVisible(find.byType(BadgeGridCell).first);
    await tester.pump();
    await tester.tap(find.byType(BadgeGridCell).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Mombasa County'), findsOneWidget);
    expect(opened, isEmpty);
  });

  testWidgets('shows the shimmer skeleton while the collection loads', (
    tester,
  ) async {
    final pending = Completer<BadgeCollection>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          badgeCollectionProvider.overrideWith((ref) => pending.future),
        ],
        child: const MaterialApp(home: BadgesScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(BadgesLoading), findsOneWidget);
    expect(find.byType(AppSkeleton), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Collection'), findsOneWidget);
  });
}
