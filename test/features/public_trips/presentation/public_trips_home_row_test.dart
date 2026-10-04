import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/auth/application/auth_providers.dart';
import 'package:kaunti47_v2/src/features/public_trips/application/public_trip_viewer_providers.dart';
import 'package:kaunti47_v2/src/features/public_trips/presentation/public_trips_home_row.dart';

import '../fake_public_trip_viewer_repository.dart';

Future<void> _pump(
  WidgetTester tester,
  FakePublicTripViewerRepository repo, {
  int? countyCode = 47,
  void Function(String id)? onOpen,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        publicTripViewerRepositoryProvider.overrideWithValue(repo),
        currentUserIdProvider.overrideWithValue(() => 'u'),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: PublicTripsHomeRow(
            countyCode: countyCode,
            onOpenTrip: onOpen ?? (_) {},
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('shows nothing when there are no trips', (tester) async {
    await _pump(tester, FakePublicTripViewerRepository());
    expect(find.text('Trips near you'), findsNothing);
  });

  testWidgets('shows nothing without a home county', (tester) async {
    final repo = FakePublicTripViewerRepository()
      ..forYouTrips = [viewerTrip()];
    await _pump(tester, repo, countyCode: null);
    expect(find.text('Trips near you'), findsNothing);
  });

  testWidgets('shows a card with counties and what is new, and opens it', (
    tester,
  ) async {
    final repo = FakePublicTripViewerRepository()
      ..forYouTrips = [viewerTrip(unclaimed: 2)];
    String? opened;
    await _pump(tester, repo, onOpen: (id) => opened = id);
    expect(find.text('Trips near you'), findsOneWidget);
    expect(find.text('2 counties'), findsOneWidget);
    expect(find.text('2 new for you'), findsOneWidget);
    await tester.tap(find.text('2 counties'));
    expect(opened, 'pub-1');
  });
}
