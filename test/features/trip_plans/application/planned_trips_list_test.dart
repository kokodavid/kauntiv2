import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/auth/application/auth_providers.dart';
import 'package:kaunti47_v2/src/features/trip_plans/application/planned_trips_list.dart';
import 'package:kaunti47_v2/src/features/trip_plans/application/trip_plans_providers.dart';
import 'package:kaunti47_v2/src/features/trip_plans/application/trips_segment.dart';
import 'package:kaunti47_v2/src/features/trip_plans/data/trip_plans_snapshot_store.dart';
import 'package:kaunti47_v2/src/features/trip_plans/domain/plan_failure.dart';
import 'package:kaunti47_v2/src/features/trip_plans/domain/plan_member.dart';
import 'package:kaunti47_v2/src/features/trip_plans/domain/planned_trips.dart';
import 'package:kaunti47_v2/src/features/trip_plans/domain/trip_plan_summary.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fake_trip_plans_repository.dart';

TripPlanSummary _plan(String id) => TripPlanSummary(
  id: id,
  title: id,
  ownerId: 'me',
  role: PlanRole.owner,
  startDate: DateTime(2026, 11, 14),
);

void main() {
  late FakeTripPlansRepository repository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PlannedTripsList.resetSessionForTest();
    repository = FakeTripPlansRepository(plans: [_plan('weekend')]);
  });

  ProviderContainer container() {
    final c = ProviderContainer(
      overrides: [
        tripPlansRepositoryProvider.overrideWithValue(repository),
        currentUserIdProvider.overrideWithValue(() => 'me'),
      ],
    );
    addTearDown(c.dispose);
    // Keep the auto-disposed providers alive between awaits.
    c.listen(plannedTripsListProvider, (_, _) {});
    c.listen(tripsSegmentChoiceProvider, (_, _) {});
    return c;
  }

  test('loads the server list and converts saved trips once', () async {
    final c = container();
    final view = await c.read(plannedTripsListProvider.future);
    expect(view.plans.upcoming.single.id, 'weekend');
    expect(view.offline, isFalse);

    await c.read(plannedTripsListProvider.notifier).refresh();
    expect(repository.conversions, 1);
    expect(repository.listCalls, 2);
  });

  test('offline, the copy on this phone shows and is marked offline', () async {
    await const TripPlansSnapshotStore().writeList('me', [
      _plan('kept'),
    ], DateTime(2026, 10, 29));
    repository.failWith = PlanFailureKind.offline;

    final c = container();
    final first = await c.read(plannedTripsListProvider.future);
    expect(first.plans.upcoming.single.id, 'kept');

    // The background refresh fails and marks the copy offline.
    await Future<void>.delayed(Duration.zero);
    await c.read(plannedTripsListProvider.notifier).refresh();
    expect(c.read(plannedTripsListProvider).value!.offline, isTrue);
  });

  test('offline with no copy is an error the screen can show', () async {
    repository.failWith = PlanFailureKind.offline;
    final c = container();
    await expectLater(
      c.read(plannedTripsListProvider.future),
      throwsA(isA<PlanFailure>()),
    );
  });

  test('a fresh server list replaces the copy', () async {
    await const TripPlansSnapshotStore().writeList('me', [
      _plan('old'),
    ], DateTime(2026, 10, 1));
    final c = container();
    expect(
      (await c.read(plannedTripsListProvider.future)).plans.upcoming.single.id,
      'old',
    );
    await c.read(plannedTripsListProvider.notifier).refresh();
    expect(
      c.read(plannedTripsListProvider).value!.plans.upcoming.single.id,
      'weekend',
    );
  });

  test('the Trips segment opens on Recorded and then stays put', () {
    final c = container();
    expect(c.read(tripsSegmentChoiceProvider), TripsSegment.recorded);
    final choice = c.read(tripsSegmentChoiceProvider.notifier);
    choice.select(TripsSegment.planned);
    expect(c.read(tripsSegmentChoiceProvider), TripsSegment.planned);
    choice.select(TripsSegment.recorded);
    expect(c.read(tripsSegmentChoiceProvider), TripsSegment.recorded);
  });
}
