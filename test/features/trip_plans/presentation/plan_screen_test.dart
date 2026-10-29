import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/config/app_config.dart';
import 'package:kaunti47_v2/src/core/services/app_config_provider.dart';
import 'package:kaunti47_v2/src/features/auth/application/auth_providers.dart';
import 'package:kaunti47_v2/src/features/trip_plans/application/plan_routing_providers.dart';
import 'package:kaunti47_v2/src/features/trip_plans/application/trip_plans_providers.dart';
import 'package:kaunti47_v2/src/features/trip_plans/data/trip_plans_snapshot_store.dart';
import 'package:kaunti47_v2/src/features/trip_plans/domain/plan_day.dart';
import 'package:kaunti47_v2/src/features/trip_plans/domain/plan_failure.dart';
import 'package:kaunti47_v2/src/features/trip_plans/domain/plan_limits.dart';
import 'package:kaunti47_v2/src/features/trip_plans/domain/plan_member.dart';
import 'package:kaunti47_v2/src/features/trip_plans/domain/plan_place.dart';
import 'package:kaunti47_v2/src/features/trip_plans/domain/trip_plan.dart';
import 'package:kaunti47_v2/src/features/trip_plans/presentation/plan_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fake_plan_routing_client.dart';
import '../fake_trip_plans_repository.dart';

PlanStop _stop(String id, String name, double lat, double lng) => PlanStop(
  id: id,
  note: id == 's1' ? 'Bring a jacket' : null,
  place: PlanPlace(
    id: 'place-$id',
    name: name,
    type: 'waterfall',
    countyCode: 32,
    lat: lat,
    lng: lng,
  ),
);

final _plan = TripPlan(
  id: 'plan-1',
  title: 'Naivasha weekend',
  ownerId: 'me',
  role: PlanRole.owner,
  start: const PlanStart(
    kind: PlanStartKind.currentLocation,
    lat: -1.3,
    lng: 36.8,
  ),
  limits: PlanLimits.free,
  startDate: DateTime(2026, 11, 14),
  days: [
    PlanDay(
      id: 'd1',
      number: 1,
      stops: [
        _stop('s1', 'Hell\'s Gate', -0.9, 36.3),
        _stop('s2', 'Lake Naivasha', -0.77, 36.35),
      ],
    ),
    PlanDay(id: 'd2', number: 2, stops: [_stop('s3', 'Menengai', -0.2, 36.1)]),
  ],
);

void main() {
  late FakeTripPlansRepository repository;
  late FakePlanRoutingClient routing;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repository = FakeTripPlansRepository()..detail['plan-1'] = _plan;
    routing = FakePlanRoutingClient();
  });

  Future<void> open(WidgetTester tester, {String id = 'plan-1'}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(const AppConfig.dev()),
          tripPlansRepositoryProvider.overrideWithValue(repository),
          currentUserIdProvider.overrideWithValue(() => 'me'),
          planRoutingClientProvider.overrideWithValue(routing),
          planClaimedCountyCodesProvider.overrideWith((ref) async => {}),
        ],
        child: MaterialApp(
          home: PlanScreen(planId: id, onBack: () {}, homeCountyCode: 47),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the plan: title, dates, days, stops and roads', (
    tester,
  ) async {
    await open(tester);
    expect(find.text('Naivasha weekend'), findsOneWidget);
    expect(find.textContaining('Sat 14 – Sun 15 Nov'), findsOneWidget);
    expect(find.textContaining('Day 1 · Sat 14 Nov'), findsOneWidget);
    expect(find.text("Hell's Gate"), findsOneWidget);
    expect(find.text('Bring a jacket'), findsOneWidget);
    expect(find.text('Menengai'), findsOneWidget);
    expect(find.textContaining('by road'), findsWidgets);
    expect(find.text('Road and driving time are estimates.'), findsOneWidget);
    expect(routing.calls, 2);
  });

  testWidgets('saves each worked-out road for the plan', (tester) async {
    await open(tester);
    expect(repository.savedRoutes.length, 2);
  });

  testWidgets('folding a day hides its stops', (tester) async {
    await open(tester);
    await tester.tap(find.textContaining('Day 2'));
    await tester.pumpAndSettle();
    expect(find.text('Menengai'), findsNothing);
    expect(find.text("Hell's Gate"), findsOneWidget);
  });

  testWidgets('a failed road keeps the stops and offers Retry', (tester) async {
    routing.fail = true;
    await open(tester);
    expect(find.text("Hell's Gate"), findsOneWidget);
    expect(find.textContaining("Couldn't work out the road"), findsWidgets);
    final before = routing.calls;
    routing.fail = false;
    await tester.tap(find.text('Retry').first);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(routing.calls, before + 1);
  });

  testWidgets('offline: the saved copy, read only', (tester) async {
    await const TripPlansSnapshotStore().writePlan(
      'me',
      _plan,
      DateTime(2026, 11, 1, 9, 12),
    );
    repository.failWith = PlanFailureKind.offline;
    await open(tester);
    expect(find.textContaining('Offline · saved copy from'), findsOneWidget);
    expect(find.text("Hell's Gate"), findsOneWidget);
    expect(repository.savedRoutes, isEmpty);
  });

  testWidgets('a plan that is gone says so', (tester) async {
    await open(tester, id: 'missing');
    expect(find.text('This plan is no longer here'), findsOneWidget);
  });
}
