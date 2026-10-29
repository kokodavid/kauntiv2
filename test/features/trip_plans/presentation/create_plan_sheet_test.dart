import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/auth/application/auth_providers.dart';
import 'package:kaunti47_v2/src/features/trip_plans/application/create_plan_controller.dart';
import 'package:kaunti47_v2/src/features/trip_plans/application/planned_trips_list.dart';
import 'package:kaunti47_v2/src/features/trip_plans/application/trip_plans_providers.dart';
import 'package:kaunti47_v2/src/features/trip_plans/domain/plan_failure.dart';
import 'package:kaunti47_v2/src/features/trip_plans/domain/plan_limits.dart';
import 'package:kaunti47_v2/src/features/trip_plans/presentation/create_plan_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fake_trip_plans_repository.dart';

void main() {
  late FakeTripPlansRepository repository;
  String? createdId;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PlannedTripsList.resetSessionForTest();
    repository = FakeTripPlansRepository();
    createdId = null;
  });

  Future<void> open(
    WidgetTester tester, {
    PlanLimits limits = PlanLimits.free,
    bool locationAvailable = true,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tripPlansRepositoryProvider.overrideWithValue(repository),
          currentUserIdProvider.overrideWithValue(() => 'me'),
          planCurrentLocationProvider.overrideWith(
            (ref) async =>
                locationAvailable ? (latitude: -1.26, longitude: 36.8) : null,
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  createdId = await showCreatePlanSheet(
                    context,
                    limits: limits,
                    onSeePro: () {},
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('creates a plan with the prefilled title', (tester) async {
    await open(tester);
    expect(find.text('New plan'), findsOneWidget);
    expect(find.text('Weekend trip'), findsOneWidget);
    await tester.tap(find.text('Create plan'));
    await tester.pumpAndSettle();
    expect(createdId, 'plan-1');
    expect(repository.created.single.title, 'Weekend trip');
    expect(repository.created.single.days, 1);
  });

  testWidgets('Free stops at 3 days and explains the grey +', (tester) async {
    await open(tester);
    await tester.tap(find.bySemanticsLabel('One day more'));
    await tester.tap(find.bySemanticsLabel('One day more'));
    await tester.pumpAndSettle();
    expect(find.text('3 of 3 days on Free.'), findsOneWidget);
    expect(find.text('Create 3-day plan'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('One day more'));
    await tester.pumpAndSettle();
    expect(find.text('3'), findsOneWidget);
    expect(
      find.textContaining('Free plans have up to 3 days.', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('Pro can plan up to 14 days', (tester) async {
    await open(tester, limits: PlanLimits.proTier);
    expect(
      find.text('Up to 14 days. You can add or remove days later.'),
      findsOneWidget,
    );
  });

  testWidgets('no location: the amber note, and creating still works', (
    tester,
  ) async {
    await open(tester, locationAvailable: false);
    expect(
      find.textContaining("We can't find your location right now"),
      findsOneWidget,
    );
    await tester.tap(find.text('Create plan'));
    await tester.pumpAndSettle();
    expect(createdId, isNotNull);
  });

  testWidgets('a server refusal stays on the sheet with a reason', (
    tester,
  ) async {
    repository.failWith = PlanFailureKind.offline;
    await open(tester);
    await tester.tap(find.text('Create plan'));
    await tester.pumpAndSettle();
    expect(createdId, isNull);
    expect(find.text('New plan'), findsOneWidget);
    expect(
      find.text("You're offline. Try again when connected."),
      findsOneWidget,
    );
  });
}
