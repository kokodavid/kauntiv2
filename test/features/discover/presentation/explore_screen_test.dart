import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/counties/county_paths.dart';
import 'package:kaunti47_v2/src/features/discover/application/explore_providers.dart';
import 'package:kaunti47_v2/src/features/discover/domain/explore_board.dart';
import 'package:kaunti47_v2/src/features/discover/domain/explore_lists.dart';
import 'package:kaunti47_v2/src/features/discover/presentation/explore_screen.dart';

Widget _app(Future<ExploreBoard> Function() load) => ProviderScope(
  // No automatic retry, so an error test leaves no pending timers.
  retry: (retryCount, error) => null,
  overrides: [exploreBoardProvider.overrideWith((ref) => load())],
  child: const MaterialApp(home: Scaffold(body: ExploreScreen())),
);

void main() {
  testWidgets('shows the skeleton, then MINE with its count', (tester) async {
    await tester.pumpWidget(
      _app(
        () async => ExploreBoard(
          featuredUnlock: null,
          mine: [
            ExploreMineCounty(
              county: CountyPaths.byCode[1]!,
              statusLabel: 'EXPLORED',
              placeCount: 0,
              isLocalExpert: false,
              previewPlaces: const [],
            ),
          ],
        ),
      ),
    );
    expect(find.byKey(const Key('explore-resolving-state')), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('MINE · 1'), findsOneWidget);
    expect(find.text(CountyPaths.byCode[1]!.name), findsOneWidget);
  });

  testWidgets('shows the empty MINE card for a new traveller', (tester) async {
    await tester.pumpWidget(
      _app(() async => const ExploreBoard(featuredUnlock: null, mine: [])),
    );
    await tester.pumpAndSettle();
    expect(find.text('Nothing here yet'), findsOneWidget);
  });

  testWidgets('a load error offers a retry', (tester) async {
    await tester.pumpWidget(_app(() async => throw StateError('offline')));
    await tester.pumpAndSettle();
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('switches to UNCLAIMED and SAVED', (tester) async {
    final county = CountyPaths.byCode[9]!;
    await tester.pumpWidget(
      _app(
        () async => ExploreBoard(
          featuredUnlock: null,
          mine: const [],
          unclaimed: [
            ExploreUnclaimedCounty(
              county: county,
              blurb: 'No places on file yet for this county.',
              percentHaveBeen: null,
              placeCount: 0,
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('UNCLAIMED · 1'), findsOneWidget);

    await tester.tap(find.text('UNCLAIMED · 1'));
    await tester.pumpAndSettle();
    expect(find.text("CLOSEST ONE YOU DON'T HAVE"), findsOneWidget);
    expect(find.text(county.name), findsOneWidget);

    await tester.tap(find.text('SAVED · 0'));
    await tester.pumpAndSettle();
    expect(find.text('Nothing saved yet'), findsOneWidget);
  });
}
