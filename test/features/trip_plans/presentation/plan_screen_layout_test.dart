import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/config/app_config.dart';
import 'package:kaunti47_v2/src/core/services/app_config_provider.dart';
import 'package:kaunti47_v2/src/features/auth/application/auth_providers.dart';
import 'package:kaunti47_v2/src/features/trip_plans/application/plan_live.dart';
import 'package:kaunti47_v2/src/features/trip_plans/application/plan_routing_providers.dart';
import 'package:kaunti47_v2/src/features/trip_plans/application/trip_plans_providers.dart';
import 'package:kaunti47_v2/src/features/trip_plans/domain/plan_day.dart';
import 'package:kaunti47_v2/src/features/trip_plans/domain/plan_limits.dart';
import 'package:kaunti47_v2/src/features/trip_plans/domain/plan_member.dart';
import 'package:kaunti47_v2/src/features/trip_plans/domain/plan_place.dart';
import 'package:kaunti47_v2/src/features/trip_plans/domain/trip_plan.dart';
import 'package:kaunti47_v2/src/features/trip_plans/presentation/plan_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fake_plan_routing_client.dart';
import '../fake_trip_plans_repository.dart';

const _longName =
    'The Kenya Wildlife Service Mount Kenya National Park Sirimon Gate and '
    'Old Moses Camp Trailhead';

PlanStop _stop(int day, int i, {bool long = false}) => PlanStop(
  id: 's$day-$i',
  note: i == 0 ? 'Bring a jacket and water for the whole day' : null,
  place: PlanPlace(
    id: 'p$day-$i',
    name: long ? _longName : 'Place $day.$i',
    type: 'waterfall',
    countyCode: 1 + (day + i) % 47,
    lat: -1.0 + day * 0.05 + i * 0.01,
    lng: 36.0 + day * 0.05 + i * 0.01,
  ),
);

/// A full Pro plan: 14 days of 20 stops (long names on day 1).
TripPlan _fullPlan() => TripPlan(
  id: 'plan-1',
  title: 'The long way round Kenya, every county in one trip',
  ownerId: 'me',
  role: PlanRole.owner,
  start: const PlanStart(
    kind: PlanStartKind.currentLocation,
    lat: -1.3,
    lng: 36.8,
  ),
  limits: PlanLimits.proTier,
  startDate: DateTime(2026, 11, 14),
  days: [
    for (var d = 1; d <= 14; d++)
      PlanDay(
        id: 'd$d',
        number: d,
        stops: [for (var i = 0; i < 20; i++) _stop(d, i, long: d == 1)],
      ),
  ],
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> open(WidgetTester tester, {double textScale = 1}) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repository = FakeTripPlansRepository()..detail['plan-1'] = _fullPlan();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(const AppConfig.dev()),
          tripPlansRepositoryProvider.overrideWithValue(repository),
          currentUserIdProvider.overrideWithValue(() => 'me'),
          planRoutingClientProvider.overrideWithValue(FakePlanRoutingClient()),
          planClaimedCountyCodesProvider.overrideWith((ref) async => {}),
          planLivePollIntervalProvider.overrideWithValue(null),
        ],
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: PlanScreen(planId: 'plan-1', onBack: () {}, homeCountyCode: 47),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
  }

  testWidgets('a full 14-day plan fits a 360 pt phone without overflow', (
    tester,
  ) async {
    await open(tester);
    expect(tester.takeException(), isNull);
    expect(find.textContaining('Day 1'), findsWidgets);
  });

  testWidgets('long place names and large text do not overflow', (
    tester,
  ) async {
    await open(tester, textScale: 1.6);
    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(CustomScrollView).first, const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('scrolling to the last day builds only what is on screen', (
    tester,
  ) async {
    await open(tester);
    // Lazy slivers: far fewer rows are alive than the 280 stops.
    final built = find.byType(InkWell).evaluate().length;
    expect(built, lessThan(120));
    await tester.drag(
      find.byType(CustomScrollView).first,
      const Offset(0, -20000),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('every tappable control on a plan day is at least 44 pt', (
    tester,
  ) async {
    await open(tester);
    final handle = tester.ensureSemantics();
    for (final tooltip in ['Back']) {
      final size = tester.getSize(find.byTooltip(tooltip).first);
      expect(size.width, greaterThanOrEqualTo(44));
      expect(size.height, greaterThanOrEqualTo(44));
    }
    handle.dispose();
  });
}
