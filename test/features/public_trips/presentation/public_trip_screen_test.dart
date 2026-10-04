import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/config/app_config.dart';
import 'package:kaunti47_v2/src/core/services/app_config_provider.dart';
import 'package:kaunti47_v2/src/features/auth/application/auth_providers.dart';
import 'package:kaunti47_v2/src/features/public_trips/application/public_trip_viewer_providers.dart';
import 'package:kaunti47_v2/src/features/public_trips/domain/public_trip_failure.dart';
import 'package:kaunti47_v2/src/features/public_trips/presentation/public_trip_screen.dart';

import '../fake_public_trip_viewer_repository.dart';

Future<void> _pump(
  WidgetTester tester,
  FakePublicTripViewerRepository repo, {
  OpenPublicTripDirections? onOpenDirections,
}) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        publicTripViewerRepositoryProvider.overrideWithValue(repo),
        appConfigProvider.overrideWithValue(const AppConfig.dev()),
        currentUserIdProvider.overrideWithValue(() => 'u'),
        publicTripAccessRecheckIntervalProvider.overrideWithValue(
          const Duration(seconds: 30),
        ),
      ],
      child: MaterialApp(
        home: PublicTripScreen(
          publicationId: 'pub-1',
          onOpenDirections: onOpenDirections,
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('shows the title, author, facts and directions', (tester) async {
    final repo = FakePublicTripViewerRepository()..trip = viewerTrip();
    double? lat;
    await _pump(
      tester,
      repo,
      onOpenDirections: (latitude, longitude) => lat = latitude,
    );
    expect(find.text('Naivasha loop'), findsOneWidget);
    expect(find.text('Wanjiru'), findsOneWidget);
    expect(find.text('Nairobi and Nakuru'), findsOneWidget);
    expect(find.text('DISTANCE'), findsOneWidget);
    expect(find.text('COUNTIES'), findsOneWidget);
    await tester.tap(find.text('Directions to the start'));
    expect(lat, -1.30);
  });

  testWidgets('plays an illustrative replay and pauses it', (tester) async {
    final repo = FakePublicTripViewerRepository()..trip = viewerTrip();
    await _pump(tester, repo);
    await tester.tap(find.byTooltip('Play replay'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byTooltip('Pause replay'), findsOneWidget);
    expect(find.text('Whole route'), findsOneWidget);
    await tester.tap(find.byTooltip('Pause replay'));
    await tester.pump();
    expect(find.byTooltip('Play replay'), findsOneWidget);
    // Speed is one pill that cycles.
    await tester.tap(find.text('1×'));
    await tester.pump();
    expect(find.text('2×'), findsOneWidget);
  });

  testWidgets('shows a neutral state for an unavailable trip', (tester) async {
    await _pump(tester, FakePublicTripViewerRepository());
    expect(find.text('This trip is not available'), findsOneWidget);
    expect(find.text('Naivasha loop'), findsNothing);
  });

  testWidgets('fails closed when access cannot be checked', (tester) async {
    final repo = FakePublicTripViewerRepository()
      ..trip = viewerTrip()
      ..failure = const PublicTripFailure('offline');
    await _pump(tester, repo);
    expect(find.text("Can't check this trip"), findsOneWidget);
    expect(find.text('Naivasha loop'), findsNothing);
  });

  testWidgets('re-checks access and drops a trip that was withdrawn', (
    tester,
  ) async {
    final repo = FakePublicTripViewerRepository()..trip = viewerTrip();
    await _pump(tester, repo);
    expect(find.text('Naivasha loop'), findsOneWidget);
    repo.trip = null;
    await tester.pump(const Duration(seconds: 31));
    await tester.pump();
    expect(find.text('This trip is not available'), findsOneWidget);
  });

  testWidgets('report sends the chosen reason', (tester) async {
    final repo = FakePublicTripViewerRepository()..trip = viewerTrip();
    await _pump(tester, repo);
    await tester.tap(find.byTooltip('More'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Report this trip'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Shows a private place'));
    await tester.pump();
    await tester.tap(find.text('Send report'));
    await tester.pumpAndSettle();
    expect(repo.reports, hasLength(1));
    expect(repo.reports.single.id, 'pub-1');
  });
}
