import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/config/app_config.dart';
import 'package:kaunti47_v2/src/core/domain/connectivity_state.dart';
import 'package:kaunti47_v2/src/core/services/app_config_provider.dart';
import 'package:kaunti47_v2/src/core/services/connectivity_provider.dart';
import 'package:kaunti47_v2/src/counties/county_paths.dart';
import 'package:kaunti47_v2/src/features/discover/application/explore_providers.dart';
import 'package:kaunti47_v2/src/features/discover/domain/explore_board.dart';
import 'package:kaunti47_v2/src/features/discover/domain/explore_lists.dart';
import 'package:kaunti47_v2/src/features/discover/presentation/explore_screen.dart';

class _Online extends Connectivity {
  @override
  ConnectivityState build() =>
      const ConnectivityState(status: ConnectivityStatus.online);

  @override
  Future<void> recheck() async {}
}

Widget _app(Future<ExploreBoard> Function() load) => ProviderScope(
  // No automatic retry, so an error test leaves no pending timers.
  retry: (retryCount, error) => null,
  overrides: [
    appConfigProvider.overrideWithValue(const AppConfig.dev()),
    connectivityProvider.overrideWith(_Online.new),
    exploreBoardProvider.overrideWith((ref) => load()),
  ],
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
    expect(
      find.text('Places will appear here as the guide grows.'),
      findsOneWidget,
    );
  });

  testWidgets('shows the empty MINE card for a new traveller', (tester) async {
    await tester.pumpWidget(
      _app(() async => const ExploreBoard(featuredUnlock: null, mine: [])),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Places will appear here as the guide grows.'),
      findsOneWidget,
    );
  });

  testWidgets('a load error offers a retry', (tester) async {
    await tester.pumpWidget(_app(() async => throw StateError('offline')));
    await tester.pumpAndSettle();
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('Counties shows the claimed sentence and All/Mine/Open', (
    tester,
  ) async {
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

    await tester.tap(find.text('Counties'));
    await tester.pumpAndSettle();
    expect(find.text('All 1'), findsOneWidget);
    expect(find.text('Mine 0'), findsOneWidget);
    expect(find.text('Open 1'), findsOneWidget);
    expect(find.text(county.name), findsOneWidget);

    await tester.tap(find.text('Mine 0'));
    await tester.pumpAndSettle();
    expect(find.text('No counties here yet'), findsOneWidget);
  });

  testWidgets('Field Guide header switches modes and opens Saved', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(() async => const ExploreBoard(featuredUnlock: null, mine: [])),
    );
    await tester.pumpAndSettle();

    expect(find.text('Places'), findsOneWidget);

    await tester.tap(find.text('Counties'));
    await tester.pumpAndSettle();
    expect(find.text('Places'), findsOneWidget);

    await tester.tap(find.byTooltip('Saved'));
    await tester.pumpAndSettle();
    expect(find.text('Saved'), findsOneWidget);
    expect(find.text('Bookmark a place and it shows up here.'), findsOneWidget);
  });
}
