import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/core/widgets/app_shimmer.dart';
import 'package:kaunti47_v2/src/features/badges/application/badges_providers.dart';
import 'package:kaunti47_v2/src/features/badges/application/passport_share_providers.dart';
import 'package:kaunti47_v2/src/features/badges/domain/badge_collection.dart';
import 'package:kaunti47_v2/src/features/badges/domain/county_badge_detail.dart';
import 'package:kaunti47_v2/src/features/badges/presentation/passport_screen.dart';
import 'package:kaunti47_v2/src/features/badges/presentation/passport_skeleton.dart';
import 'package:kaunti47_v2/src/features/profile/application/public_profile_providers.dart';
import 'package:kaunti47_v2/src/features/profile/domain/public_profile.dart';

void main() {
  final collection = BadgeCollection.from(
    visitStates: {1: 'explored', 22: 'explored', 30: 'passed_through'},
    ranks: const {22: 'regular'},
  );

  Widget app(Stream<BadgeCollection> stream, {bool shareOn = false}) =>
      ProviderScope(
        overrides: [
          badgeCollectionProvider.overrideWith((ref) => stream),
          passportShareFlagProvider.overrideWith((ref) async => shareOn),
          myPublicProfileProvider.overrideWith(
            (ref) async =>
                const PublicProfile(displayName: 'David', handle: 'mochoge'),
          ),
          for (final code in [1, 2, 3, 22])
            countyBadgeDetailProvider(
              code,
            ).overrideWith((ref) async => const CountyBadgeDetail()),
        ],
        child: const MaterialApp(home: PassportScreen()),
      );

  testWidgets('opens straight on the landing while the cover is off', (
    tester,
  ) async {
    await tester.pumpWidget(app(Stream.value(collection)));
    await tester.pump();
    await tester.pump();

    expect(find.text('COUNTY PASSPORT'), findsNothing);
    expect(find.text('Passport'), findsOneWidget);
    expect(find.text('Central'), findsOneWidget);
    expect(find.text('Search 47 counties'), findsOneWidget);
    expect(
      find.textContaining('2 / 47', findRichText: true),
      findsOneWidget,
    ); // counties explored
  });

  testWidgets('shows a neutral skeleton while the passport loads', (
    tester,
  ) async {
    final pending = Completer<BadgeCollection>();
    await tester.pumpWidget(app(Stream.fromFuture(pending.future)));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(PassportSkeleton), findsOneWidget);
    expect(find.byType(AppSkeleton), findsWidgets);
    expect(find.text('Mombasa'), findsNothing);
    expect(find.text('COUNTY PASSPORT'), findsNothing);
  });

  testWidgets(
    'no Share button while the dashboard switch is off',
    (tester) async {
      await tester.pumpWidget(app(Stream.value(collection)));
      await tester.pump();
      await tester.pump();
      expect(find.byTooltip('Share your Passport'), findsNothing);
    },
    skip: passportShareAlwaysOn,
  );

  testWidgets('the switch on shows Share, which opens the sheet', (
    tester,
  ) async {
    await tester.pumpWidget(app(Stream.value(collection), shareOn: true));
    await tester.pump();
    await tester.pump();
    expect(find.byTooltip('Share your Passport'), findsOneWidget);

    await tester.tap(find.byTooltip('Share your Passport'));
    await tester.pumpAndSettle();
    expect(find.text('Share your Passport'), findsOneWidget);
    expect(find.text('Show on image'), findsOneWidget);
    expect(find.text('Background art'), findsOneWidget);
  });
}
