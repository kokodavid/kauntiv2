import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/auth/application/auth_providers.dart';
import 'package:kaunti47_v2/src/features/trip_plans/application/plan_places_providers.dart';
import 'package:kaunti47_v2/src/features/trip_plans/application/planned_trips_list.dart';
import 'package:kaunti47_v2/src/features/trip_plans/application/trip_plans_providers.dart';
import 'package:kaunti47_v2/src/features/trip_plans/domain/plan_day.dart';
import 'package:kaunti47_v2/src/features/trip_plans/domain/plan_limits.dart';
import 'package:kaunti47_v2/src/features/trip_plans/domain/plan_member.dart';
import 'package:kaunti47_v2/src/features/trip_plans/domain/plan_place.dart';
import 'package:kaunti47_v2/src/features/trip_plans/domain/plan_ref.dart';
import 'package:kaunti47_v2/src/features/trip_plans/domain/planned_trips.dart';
import 'package:kaunti47_v2/src/features/trip_plans/domain/trip_plan.dart';
import 'package:kaunti47_v2/src/features/trip_plans/domain/trip_plan_summary.dart';
import 'package:kaunti47_v2/src/features/trip_plans/presentation/add_places_page.dart';
import 'package:kaunti47_v2/src/features/trip_plans/presentation/add_to_trip_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fake_plan_places_repository.dart';
import '../fake_trip_plans_repository.dart';

const _hells = PlanPlace(
  id: 'hells',
  name: "Hell's Gate",
  type: 'park',
  countyCode: 32,
  lat: -0.9,
  lng: 36.3,
);
const _menengai = PlanPlace(
  id: 'menengai',
  name: 'Menengai Crater',
  type: 'hike',
  countyCode: 32,
  lat: -0.2,
  lng: 36.1,
);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PlannedTripsList.resetSessionForTest();
  });

  testWidgets('Add places: search, add, and it shows as added', (tester) async {
    final added = <String>[];
    final places = FakePlanPlacesRepository([_hells, _menengai]);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [planPlacesRepositoryProvider.overrideWithValue(places)],
        child: MaterialApp(
          home: AddPlacesPage(
            title: 'Add to Day 1',
            onAdd: (place) async {
              added.add(place.id);
              return true;
            },
          ),
        ),
      ),
    );
    expect(
      find.text('Search by name, or pick a county or a type.'),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextField), 'hell');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text("Hell's Gate"), findsOneWidget);
    expect(find.text('Menengai Crater'), findsNothing);
    await tester.tap(find.text("Hell's Gate"));
    await tester.pumpAndSettle();
    expect(added, ['hells']);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets('Add places: a type alone starts a search', (tester) async {
    final places = FakePlanPlacesRepository([_hells, _menengai]);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [planPlacesRepositoryProvider.overrideWithValue(places)],
        child: MaterialApp(
          home: AddPlacesPage(title: 'Add', onAdd: (_) async => true),
        ),
      ),
    );
    await tester.tap(find.text('Hikes'));
    await tester.pumpAndSettle();
    expect(find.text('Menengai Crater'), findsOneWidget);
    expect(find.text("Hell's Gate"), findsNothing);
  });

  testWidgets('Add to trip: plan, then day, then Undo-able toast', (
    tester,
  ) async {
    final repository = FakeTripPlansRepository(
      plans: [
        const TripPlanSummary(
          id: 'plan-1',
          title: 'Naivasha weekend',
          ownerId: 'me',
          role: PlanRole.owner,
        ),
      ],
    )..holding['hells'] = const [PlanRef(id: 'other', title: 'Other')];
    repository.detail['plan-1'] = const TripPlan(
      id: 'plan-1',
      title: 'Naivasha weekend',
      ownerId: 'me',
      role: PlanRole.owner,
      start: PlanStart.currentLocation,
      limits: PlanLimits.free,
      days: [PlanDay(id: 'd1', number: 1)],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tripPlansRepositoryProvider.overrideWithValue(repository),
          currentUserIdProvider.overrideWithValue(() => 'me'),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) => TextButton(
                onPressed: () => showAddToTrip(
                  context,
                  ref,
                  placeId: 'hells',
                  placeName: "Hell's Gate",
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text("Add Hell's Gate to a trip"), findsOneWidget);
    await tester.tap(find.text('Naivasha weekend'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Day 1'));
    await tester.pumpAndSettle();
    expect(repository.added, ['d1|hells']);
    expect(find.text('Added to Naivasha weekend'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(repository.removed, ['stop-1|false']);
  });

  test('Home shows the soonest plan ahead, including shared ones', () {
    final plans = PlannedTrips.split([
      TripPlanSummary(
        id: 'later',
        title: 'Later',
        ownerId: 'me',
        role: PlanRole.owner,
        startDate: DateTime(2026, 12, 20),
      ),
      TripPlanSummary(
        id: 'sooner',
        title: 'Sooner',
        ownerId: 'them',
        role: PlanRole.editor,
        startDate: DateTime(2026, 11, 14),
      ),
    ]);
    expect(plans.next?.id, 'sooner');
    expect(const PlannedTrips().next, isNull);
  });
}
