import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/config/app_config.dart';
import 'package:kaunti47_v2/src/core/services/app_config_provider.dart';
import 'package:kaunti47_v2/src/features/auth/application/auth_providers.dart';
import 'package:kaunti47_v2/src/features/trip_plans/application/plan_live.dart';
import 'package:kaunti47_v2/src/features/trip_plans/application/plan_offline_copy.dart';
import 'package:kaunti47_v2/src/features/trip_plans/application/plan_routing_providers.dart';
import 'package:kaunti47_v2/src/features/trip_plans/application/trip_plans_providers.dart';
import 'package:kaunti47_v2/src/features/trip_plans/domain/plan_day.dart';
import 'package:kaunti47_v2/src/features/trip_plans/domain/plan_limits.dart';
import 'package:kaunti47_v2/src/features/trip_plans/domain/plan_member.dart';
import 'package:kaunti47_v2/src/features/trip_plans/domain/plan_offline.dart';
import 'package:kaunti47_v2/src/features/trip_plans/domain/plan_place.dart';
import 'package:kaunti47_v2/src/features/trip_plans/domain/trip_plan.dart';
import 'package:kaunti47_v2/src/features/trip_plans/presentation/plan_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fake_plan_offline_map.dart';
import '../fake_plan_routing_client.dart';
import '../fake_trip_plans_repository.dart';

PlanStop _stop(String id, double lat, double lng) => PlanStop(
  id: id,
  place: PlanPlace(
    id: 'place-$id',
    name: 'Place $id',
    type: 'waterfall',
    countyCode: 32,
    lat: lat,
    lng: lng,
    thumbnailUrl: 'https://example.invalid/$id.jpg',
  ),
);

TripPlan _plan(PlanLimits limits) => TripPlan(
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
      stops: [_stop('a', -0.9, 36.3), _stop('b', -0.2, 36.1)],
    ),
  ],
);

void main() {
  late FakeTripPlansRepository repository;
  late FakePlanOfflineMap map;
  late FakePlanOfflineImages images;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repository = FakeTripPlansRepository();
    map = FakePlanOfflineMap();
    images = FakePlanOfflineImages();
  });

  List<Override> overrides() => [
    appConfigProvider.overrideWithValue(const AppConfig.dev()),
    tripPlansRepositoryProvider.overrideWithValue(repository),
    planOfflineMapProvider.overrideWithValue(map),
    planOfflineImagesProvider.overrideWithValue(images),
    planLivePollIntervalProvider.overrideWithValue(null),
    currentUserIdProvider.overrideWithValue(() => 'me'),
    planRoutingClientProvider.overrideWithValue(FakePlanRoutingClient()),
    planClaimedCountyCodesProvider.overrideWith((ref) async => {}),
  ];

  Future<void> open(WidgetTester tester, PlanLimits limits) async {
    repository.detail['plan-1'] = _plan(limits);
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

  Future<void> menu(WidgetTester tester, String item) async {
    await tester.tap(find.byTooltip('Plan options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(item));
    await tester.pumpAndSettle();
  }

  testWidgets('Pro: Keep offline saves the map and pictures', (tester) async {
    await open(tester, PlanLimits.proTier);
    await menu(tester, 'Offline copy');
    expect(map.downloads, ['plan-me-plan-1']);
    expect(images.fetched.length, 2);
    expect(find.text('Saved offline'), findsOneWidget);

    await tester.tap(find.byTooltip('Plan options'));
    await tester.pumpAndSettle();
    expect(find.text('Remove offline copy'), findsOneWidget);
  });

  testWidgets('Remove offline copy puts it back', (tester) async {
    await open(tester, PlanLimits.proTier);
    await menu(tester, 'Offline copy');
    await menu(tester, 'Remove offline copy');
    expect(map.removed, ['plan-me-plan-1']);
    await tester.tap(find.byTooltip('Plan options'));
    await tester.pumpAndSettle();
    expect(find.text('Offline copy'), findsOneWidget);
  });

  testWidgets('Free: opens the Pro sheet and saves nothing', (tester) async {
    await open(tester, PlanLimits.free);
    await menu(tester, 'Offline copy');
    expect(find.text('Keep this plan offline'), findsOneWidget);
    expect(map.downloads, isEmpty);
  });

  testWidgets('a failed download says so and keeps nothing', (tester) async {
    map.fail = true;
    await open(tester, PlanLimits.proTier);
    await menu(tester, 'Offline copy');
    expect(
      find.text("You're offline. Try again when connected."),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('Plan options'));
    await tester.pumpAndSettle();
    expect(find.text('Offline copy'), findsOneWidget);
  });

  test('PlanBounds covers the stops with room around them', () {
    final bounds = PlanBounds.of(_plan(PlanLimits.proTier))!;
    expect(bounds.south, lessThan(-1.3));
    expect(bounds.north, greaterThan(-0.2));
    expect(bounds.west, lessThan(36.1));
    expect(bounds.east, greaterThan(36.8));
    expect(bounds.maxZoom, 10);
  });
}
