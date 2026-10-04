import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/auth/application/auth_providers.dart';
import 'package:kaunti47_v2/src/features/public_trips/application/public_trip_providers.dart';
import 'package:kaunti47_v2/src/features/public_trips/domain/public_trip_owner_view.dart';
import 'package:kaunti47_v2/src/features/public_trips/presentation/public_trip_entry_tile.dart';

import '../fake_public_trip_repository.dart';

Future<void> _pump(
  WidgetTester tester,
  FakePublicTripRepository repo, {
  bool canPublish = true,
  void Function(String id)? onView,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        publicTripRepositoryProvider.overrideWithValue(repo),
        currentUserIdProvider.overrideWithValue(() => 'u'),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: PublicTripEntryTile(
            journeyId: 'j',
            canPublish: canPublish,
            onOpen: () {},
            onView: onView,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('offers Make public when nothing has been submitted', (
    tester,
  ) async {
    await _pump(tester, FakePublicTripRepository());
    expect(find.text('Make public'), findsOneWidget);
    expect(find.text('Awaiting review'), findsNothing);
  });

  testWidgets('is hidden when publishing is off and no copy exists', (
    tester,
  ) async {
    await _pump(tester, FakePublicTripRepository()..enabled = false);
    expect(find.text('Public trip'), findsNothing);
  });

  testWidgets('is hidden for a trip that cannot be published', (tester) async {
    await _pump(tester, FakePublicTripRepository(), canPublish: false);
    expect(find.text('Public trip'), findsNothing);
  });

  testWidgets('shows Awaiting review with a way to cancel', (tester) async {
    final repo = FakePublicTripRepository()
      ..mineView = ownerView(status: PublicTripStatus.submitted);
    await _pump(tester, repo);
    expect(find.text('Awaiting review'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Make public'), findsNothing);
  });

  testWidgets('shows Public with edit and withdraw', (tester) async {
    final repo = FakePublicTripRepository()
      ..mineView = ownerView(
        status: PublicTripStatus.approved,
        activeRevision: 1,
      );
    await _pump(tester, repo);
    expect(find.text('Public'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Withdraw'), findsOneWidget);
  });

  testWidgets('lets the owner view their live public page', (tester) async {
    final repo = FakePublicTripRepository()
      ..mineView = ownerView(
        status: PublicTripStatus.approved,
        activeRevision: 1,
      );
    String? viewed;
    await _pump(tester, repo, onView: (id) => viewed = id);
    await tester.tap(find.text('View'));
    expect(viewed, 'pub-1');
  });

  testWidgets('shows the moderator reason when changes are needed', (
    tester,
  ) async {
    final repo = FakePublicTripRepository()
      ..mineView = ownerView(
        status: PublicTripStatus.rejected,
        reviewReason: 'Photo shows a house number',
      );
    await _pump(tester, repo);
    expect(find.text('Needs changes'), findsOneWidget);
    expect(find.textContaining('Photo shows a house number'), findsOneWidget);
    expect(find.text('Edit and resubmit'), findsOneWidget);
  });

  testWidgets('a hidden trip has no actions', (tester) async {
    final repo = FakePublicTripRepository()
      ..mineView = ownerView(
        status: PublicTripStatus.approved,
        activeRevision: 1,
        hidden: true,
      );
    await _pump(tester, repo);
    expect(find.text('Hidden'), findsOneWidget);
    expect(find.text('Edit'), findsNothing);
    expect(find.text('Withdraw'), findsNothing);
  });

  testWidgets('Make public calls onOpen', (tester) async {
    var opened = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          publicTripRepositoryProvider.overrideWithValue(
            FakePublicTripRepository(),
          ),
          currentUserIdProvider.overrideWithValue(() => 'u'),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: PublicTripEntryTile(journeyId: 'j', onOpen: () => opened++),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.tap(find.text('Make public'));
    expect(opened, 1);
  });
}
