import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/auth/application/auth_providers.dart';
import 'package:kaunti47_v2/src/features/public_trips/application/public_trip_viewer_providers.dart';
import 'package:kaunti47_v2/src/features/public_trips/domain/public_trip_failure.dart';
import 'package:kaunti47_v2/src/features/public_trips/domain/public_trip_report_reason.dart';

import '../fake_public_trip_viewer_repository.dart';

ProviderContainer _container(FakePublicTripViewerRepository repo) {
  final container = ProviderContainer(
    overrides: [
      publicTripViewerRepositoryProvider.overrideWithValue(repo),
      currentUserIdProvider.overrideWithValue(() => 'u'),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('Home row is empty while public trips are off', () async {
    final repo = FakePublicTripViewerRepository()
      ..enabled = false
      ..forYouTrips = [viewerTrip()];
    final trips = await _container(
      repo,
    ).read(publicTripsForYouProvider(47).future);
    expect(trips, isEmpty);
  });

  test('Home row lists trips when public trips are on', () async {
    final repo = FakePublicTripViewerRepository()
      ..forYouTrips = [viewerTrip(unclaimed: 2)];
    final trips = await _container(
      repo,
    ).read(publicTripsForYouProvider(47).future);
    expect(trips.single.unclaimedCounties, 2);
  });

  test('Home row hides quietly when the server refuses', () async {
    final repo = FakePublicTripViewerRepository()
      ..failure = const PublicTripFailure('nope');
    final trips = await _container(
      repo,
    ).read(publicTripsForYouProvider(47).future);
    expect(trips, isEmpty);
  });

  test('an unavailable trip reads as null', () async {
    final repo = FakePublicTripViewerRepository();
    final trip = await _container(repo).read(publicTripProvider('x').future);
    expect(trip, isNull);
  });

  test('reporting sends the reason and trip', () async {
    final repo = FakePublicTripViewerRepository();
    await _container(repo)
        .read(publicTripViewerActionsProvider.notifier)
        .report('pub-1', PublicTripReportReason.privacy);
    expect(repo.reports.single.id, 'pub-1');
    expect(repo.reports.single.reason, PublicTripReportReason.privacy);
  });

  test('a refused report surfaces the failure', () async {
    final repo = FakePublicTripViewerRepository()
      ..failure = const PublicTripFailure('Too many reports');
    final actions = _container(
      repo,
    ).read(publicTripViewerActionsProvider.notifier);
    expect(
      () => actions.report('pub-1', PublicTripReportReason.other),
      throwsA(isA<PublicTripFailure>()),
    );
  });

  test('blocking an author refreshes the trip so it disappears', () async {
    final repo = FakePublicTripViewerRepository()..trip = viewerTrip();
    final container = _container(repo);
    expect(await container.read(publicTripProvider('pub-1').future), isNotNull);
    repo.trip = null;
    await container
        .read(publicTripViewerActionsProvider.notifier)
        .setAuthorBlocked('pub-1', 'author-1', blocked: true);
    expect(await container.read(publicTripProvider('pub-1').future), isNull);
    expect(repo.blocks.single, (authorId: 'author-1', blocked: true));
  });
}
