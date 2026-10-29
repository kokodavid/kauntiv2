import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/config/app_config.dart';
import 'package:kaunti47_v2/src/core/services/app_config_provider.dart';
import 'package:kaunti47_v2/src/features/auth/application/auth_providers.dart';
import 'package:kaunti47_v2/src/features/trip_plans/application/plan_best_order.dart';
import 'package:kaunti47_v2/src/features/trip_plans/application/plan_live.dart';
import 'package:kaunti47_v2/src/features/trip_plans/application/plan_routing_providers.dart';
import 'package:kaunti47_v2/src/features/trip_plans/application/trip_plans_providers.dart';
import 'package:kaunti47_v2/src/features/trip_plans/domain/plan_day.dart';
import 'package:kaunti47_v2/src/features/trip_plans/domain/plan_failure.dart';
import 'package:kaunti47_v2/src/features/trip_plans/domain/plan_limits.dart';
import 'package:kaunti47_v2/src/features/trip_plans/domain/plan_member.dart';
import 'package:kaunti47_v2/src/features/trip_plans/domain/plan_place.dart';
import 'package:kaunti47_v2/src/features/trip_plans/domain/trip_plan.dart';
import 'package:kaunti47_v2/src/features/trip_plans/presentation/plan_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fake_plan_best_order_client.dart';
import '../fake_plan_routing_client.dart';
import '../fake_trip_plans_repository.dart';

PlanStop _stop(String id, String name, double lat, double lng) => PlanStop(
  id: id,
  place: PlanPlace(
    id: 'place-$id',
    name: name,
    type: 'waterfall',
    countyCode: 32,
    lat: lat,
    lng: lng,
  ),
);

TripPlan _plan(PlanLimits limits, {int stops = 3}) => TripPlan(
  id: 'plan-1',
  title: 'Naivasha weekend',
  ownerId: 'me',
  role: PlanRole.owner,
  start: const PlanStart(
    kind: PlanStartKind.currentLocation,
    lat: -1.3,
    lng: 36.8,
  ),
  limits: limits,
  days: [
    PlanDay(
      id: 'd1',
      number: 1,
      stops: [
        for (var i = 1; i <= stops; i++) _stop('s$i', 'Place $i', -0.9 + i / 10, 36.3),
      ],
    ),
  ],
);

void main() {
  late FakeTripPlansRepository repository;
  late FakePlanBestOrderClient bestOrder;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repository = FakeTripPlansRepository();
    bestOrder = FakePlanBestOrderClient()..answer = ['s3', 's1', 's2'];
  });

  List<Override> overrides() => [
    appConfigProvider.overrideWithValue(const AppConfig.dev()),
    tripPlansRepositoryProvider.overrideWithValue(repository),
    planBestOrderClientProvider.overrideWithValue(bestOrder),
    planLivePollIntervalProvider.overrideWithValue(null),
    currentUserIdProvider.overrideWithValue(() => 'me'),
    planRoutingClientProvider.overrideWithValue(FakePlanRoutingClient()),
    planClaimedCountyCodesProvider.overrideWith((ref) async => {}),
  ];

  Future<void> open(WidgetTester tester, TripPlan plan) async {
    repository.detail['plan-1'] = plan;
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides(),
        child: MaterialApp(
          home: PlanScreen(planId: 'plan-1', onBack: () {}),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
  }

  testWidgets('Pro: Best order saves the new order and offers Undo', (
    tester,
  ) async {
    await open(tester, _plan(PlanLimits.proTier));
    await tester.tap(find.text('Best order'));
    await tester.pumpAndSettle();
    expect(bestOrder.calls.length, 1);
    expect(repository.orders, ['d1|s3,s1,s2']);
    expect(find.text('Day 1 reordered'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(repository.orders.last, 'd1|s1,s2,s3');
  });

  testWidgets('already in order: nothing is saved', (tester) async {
    bestOrder.answer = ['s1', 's2', 's3'];
    await open(tester, _plan(PlanLimits.proTier));
    await tester.tap(find.text('Best order'));
    await tester.pumpAndSettle();
    expect(repository.orders, isEmpty);
    expect(find.textContaining('already in a good order'), findsOneWidget);
  });

  testWidgets('Free: the button carries PRO and opens the Pro sheet', (
    tester,
  ) async {
    await open(tester, _plan(PlanLimits.free));
    expect(find.text('PRO'), findsOneWidget);
    await tester.tap(find.text('Best order'));
    await tester.pumpAndSettle();
    expect(find.text('Let Pro order the day'), findsOneWidget);
    expect(bestOrder.calls, isEmpty);
  });

  testWidgets('a refusal from the server is explained', (tester) async {
    bestOrder.failWith = PlanFailureKind.rateLimited;
    await open(tester, _plan(PlanLimits.proTier));
    await tester.tap(find.text('Best order'));
    await tester.pumpAndSettle();
    expect(find.text('Too many tries. Wait a little.'), findsOneWidget);
    expect(repository.orders, isEmpty);
  });

  testWidgets('a day with two stops has no Best order button', (tester) async {
    await open(tester, _plan(PlanLimits.proTier, stops: 2));
    expect(find.text('Best order'), findsNothing);
  });
}
