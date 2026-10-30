import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/auth/application/auth_providers.dart';
import 'package:kaunti47_v2/src/features/trip_plans/application/create_plan_controller.dart';
import 'package:kaunti47_v2/src/features/trip_plans/application/planned_trips_list.dart';
import 'package:kaunti47_v2/src/features/trip_plans/application/trip_plans_providers.dart';
import 'package:kaunti47_v2/src/features/trip_plans/domain/plan_failure.dart';
import 'package:kaunti47_v2/src/features/trip_plans/domain/plan_limits.dart';
import 'package:kaunti47_v2/src/features/trip_plans/domain/trip_plan.dart';
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
    ChoosePlanStart? onChoosePlace,
    ChoosePlanStart? onPickOnMap,
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
                    onChoosePlace: onChoosePlace,
                    onPickOnMap: onPickOnMap,
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

  testWidgets('the start chips share one row on a 360 pt phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await open(
      tester,
      onChoosePlace: (_) async => null,
      onPickOnMap: (_) async => null,
    );
    final tops = [
      for (final label in ['Current location', 'Choose a place', 'Pick on map'])
        tester.getTopLeft(find.text(label)).dy,
    ];
    expect(tops.every((y) => (y - tops.first).abs() < 2), isTrue);
    expect(tester.takeException(), isNull);
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

  const westlands = PlanStart(
    kind: PlanStartKind.point,
    label: 'Total Energies Westlands, Nairobi, Kenya',
    lat: -1.2635,
    lng: 36.8047,
  );

  testWidgets('a searched spot is shown and saved as an exact point', (
    tester,
  ) async {
    await open(tester, onChoosePlace: (_) async => westlands);
    await tester.tap(find.text('Choose a place'));
    await tester.pumpAndSettle();
    expect(
      find.text('Total Energies Westlands, Nairobi, Kenya'),
      findsOneWidget,
    );
    await tester.tap(find.text('Create plan'));
    await tester.pumpAndSettle();
    final request = repository.created.single;
    expect(request.startKind, PlanStartKind.point);
    expect(request.startLat, -1.2635);
    expect(request.startLng, 36.8047);
  });

  testWidgets('removing the spot greys Create until a start is chosen', (
    tester,
  ) async {
    await open(tester, onChoosePlace: (_) async => westlands);
    await tester.tap(find.text('Choose a place'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Remove start'));
    await tester.pumpAndSettle();
    expect(find.text('Choose where this trip starts.'), findsOneWidget);
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);

    await tester.tap(find.text('Current location'));
    await tester.pumpAndSettle();
    expect(find.text('Choose where this trip starts.'), findsNothing);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
  });

  testWidgets('an empty title greys Create and says why', (tester) async {
    await open(tester);
    await tester.enterText(find.byType(TextField).first, '   ');
    await tester.pumpAndSettle();
    expect(find.text('Give the plan a name.'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
  });
}
