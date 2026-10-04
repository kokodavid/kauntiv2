import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/auth/application/auth_providers.dart';
import 'package:kaunti47_v2/src/features/journeys/application/journey_key_moments.dart';
import 'package:kaunti47_v2/src/features/journeys/application/journey_views.dart';
import 'package:kaunti47_v2/src/features/journeys/domain/journey_media_capture.dart';
import 'package:kaunti47_v2/src/features/journeys/domain/journey_moments.dart';
import 'package:kaunti47_v2/src/features/journeys/domain/journey_route.dart';
import 'package:kaunti47_v2/src/features/journeys/domain/journey_summary.dart';
import 'package:kaunti47_v2/src/features/public_trips/application/public_trip_providers.dart';
import 'package:kaunti47_v2/src/features/public_trips/application/public_trip_review_controller.dart';
import 'package:kaunti47_v2/src/features/public_trips/application/public_trip_review_state.dart';
import 'package:kaunti47_v2/src/features/public_trips/domain/public_trip_failure.dart';

import '../fake_public_trip_repository.dart';

final _detail = JourneyDetail(
  summary: JourneySummary(
    id: 'j',
    title: 'Morning drive',
    startedAt: DateTime.utc(2026, 9, 25, 10),
    endedAt: DateTime.utc(2026, 9, 25, 11),
    isUploaded: true,
  ),
  route: JourneyRoute(const []),
);

const _moments = [
  JourneyMoment(
    kind: JourneyMomentKind.countyCrossing,
    index: 5,
    name: 'Kiambu',
  ),
  JourneyMoment(
    kind: JourneyMomentKind.topSpeed,
    index: 9,
    speedMetersPerSecond: 25,
  ),
];

final _media = [
  for (var i = 0; i < 12; i++)
    JourneyMediaItem(
      id: 'm$i',
      url: 'https://example.invalid/m$i',
      capturedAt: DateTime.utc(2026, 9, 25, 10, i),
      latitude: -1,
      longitude: 36,
    ),
];

final _provider = publicTripReviewControllerProvider('j');

Future<ProviderContainer> _start(FakePublicTripRepository repo) async {
  final container = ProviderContainer(
    overrides: [
      publicTripRepositoryProvider.overrideWithValue(repo),
      publicTripPhotoPollIntervalProvider.overrideWithValue(Duration.zero),
      currentUserIdProvider.overrideWithValue(() => 'u'),
      journeyDetailProvider('j').overrideWith((ref) async => _detail),
      journeyMomentsProvider('j').overrideWith((ref) async => _moments),
      journeyMediaProvider('j').overrideWith((ref) async => _media),
    ],
  );
  addTearDown(container.dispose);
  container.listen(_provider, (_, _) {});
  await container.read(_provider.future);
  return container;
}

PublicTripReviewState _state(ProviderContainer c) => c.read(_provider).value!;

void main() {
  test('starts from the share defaults', () async {
    final container = await _start(FakePublicTripRepository());
    final state = _state(container);
    expect(state.title, 'Morning drive');
    expect(state.trimMeters, 500);
    expect(state.selectedMoments, {'county_crossing:5'});
    expect(state.selectedPhotos, isEmpty);
    expect(state.stage, PublicTripReviewStage.choose);
  });

  test('prepare sends the chosen moments and photos', () async {
    final repo = FakePublicTripRepository();
    final container = await _start(repo);
    final controller = container.read(_provider.notifier)
      ..toggleMoment('top_speed:9')
      ..togglePhoto('m1')
      ..setTrim(1000);
    await controller.prepare();

    final call = repo.prepareCalls.single;
    expect(call['title'], 'Morning drive');
    expect(call['photoIds'], ['m1']);
    expect(call['trim'], 1000);
    expect(call['moments'], [
      (kind: 'county_crossing', sequenceNumber: 5),
      (kind: 'top_speed', sequenceNumber: 9),
    ]);
    final state = _state(container);
    expect(state.stage, PublicTripReviewStage.preview);
    expect(state.candidate, isNotNull);
  });

  test('an identical retry reuses the request id; a change does not', () async {
    final repo = FakePublicTripRepository();
    final container = await _start(repo);
    final controller = container.read(_provider.notifier);
    await controller.prepare();
    controller.backToChoices();
    await controller.prepare();
    expect(repo.prepareCalls[1]['requestId'], repo.prepareCalls[0]['requestId']);

    controller
      ..backToChoices()
      ..toggleMoment('top_speed:9');
    await controller.prepare();
    expect(repo.prepareCalls[2]['requestId'], isNot(repo.prepareCalls[0]['requestId']));
  });

  test('a refused preview returns to the choices with the reason', () async {
    final repo = FakePublicTripRepository()
      ..prepareFailure = const PublicTripFailure('Pro is required to publish trips');
    final container = await _start(repo);
    await container.read(_provider.notifier).prepare();
    final state = _state(container);
    expect(state.stage, PublicTripReviewStage.choose);
    expect(state.error, 'Pro is required to publish trips');
  });

  test('waits for photos to be prepared', () async {
    final repo = FakePublicTripRepository()
      ..prepareResult = ownerView(photosPending: 1)
      ..mineView = ownerView();
    final container = await _start(repo);
    await container.read(_provider.notifier).prepare();
    final state = _state(container);
    expect(state.stage, PublicTripReviewStage.preview);
    expect(state.candidate!.photosReady, isTrue);
  });

  test('cannot submit without consent, or with a failed photo', () async {
    final repo = FakePublicTripRepository();
    final container = await _start(repo);
    final controller = container.read(_provider.notifier);
    await controller.prepare();
    expect(_state(container).canSubmit, isFalse);
    controller.setConsent(true);
    expect(_state(container).canSubmit, isTrue);

    final failing = FakePublicTripRepository()
      ..prepareResult = ownerView(photosFailed: 1);
    final other = await _start(failing);
    final otherController = other.read(_provider.notifier);
    await otherController.prepare();
    otherController.setConsent(true);
    expect(_state(other).canSubmit, isFalse);
  });

  test('submit sends the previewed revision and can save defaults', () async {
    final repo = FakePublicTripRepository();
    final container = await _start(repo);
    final controller = container.read(_provider.notifier)
      ..toggleMoment('top_speed:9')
      ..setSaveAsDefault(true);
    await controller.prepare();
    controller.setConsent(true);
    await controller.submit();

    expect(repo.submitCalls, ['hash-1']);
    expect(_state(container).stage, PublicTripReviewStage.submitted);
    expect(repo.savedPreferences.single.topSpeed, isTrue);
  });

  test('a refused submit stays on the preview with the reason', () async {
    final repo = FakePublicTripRepository()
      ..submitFailure = const PublicTripFailure('Review the latest candidate and terms');
    final container = await _start(repo);
    final controller = container.read(_provider.notifier);
    await controller.prepare();
    controller.setConsent(true);
    await controller.submit();
    final state = _state(container);
    expect(state.stage, PublicTripReviewStage.preview);
    expect(state.error, 'Review the latest candidate and terms');
  });

  test('photos are capped at ten', () async {
    final container = await _start(FakePublicTripRepository());
    final controller = container.read(_provider.notifier);
    for (var i = 0; i < 11; i++) {
      controller.togglePhoto('m$i');
    }
    final state = _state(container);
    expect(state.selectedPhotos.length, publicTripMaxPhotos);
    expect(state.error, isNotNull);
  });

  test('a blank title cannot be previewed', () async {
    final container = await _start(FakePublicTripRepository());
    final controller = container.read(_provider.notifier)..setTitle('   ');
    expect(_state(container).canPrepare, isFalse);
    await controller.prepare();
    expect(_state(container).stage, PublicTripReviewStage.choose);
  });
}
