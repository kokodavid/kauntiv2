import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/badges/application/badges_providers.dart';
import 'package:kaunti47_v2/src/features/badges/domain/badge_collection.dart';
import 'package:kaunti47_v2/src/features/badges/presentation/badge_grid_cell.dart';
import 'package:kaunti47_v2/src/features/badges/presentation/badges_screen.dart';

void main() {
  testWidgets('shows the count, tier and every county; tap opens it', (
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
        ],
        child: MaterialApp(
          home: BadgesScreen(onOpenCounty: (_, code) => opened.add(code)),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Badges'), findsOneWidget);
    expect(find.text('Tier 2'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('of 47 counties claimed'), findsOneWidget);
    expect(find.text('25% OF KENYA'), findsOneWidget);
    expect(find.text('35 LEFT'), findsOneWidget);
    expect(find.text('ALL 47 COUNTIES'), findsOneWidget);

    await tester.tap(find.byType(BadgeGridCell).first);
    expect(opened, [1]);
  });
}
