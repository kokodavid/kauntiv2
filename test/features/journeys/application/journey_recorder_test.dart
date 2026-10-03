import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/auth/application/auth_providers.dart';
import 'package:kaunti47_v2/src/features/journeys/application/journey_cloud_providers.dart';
import 'package:kaunti47_v2/src/features/journeys/application/journey_entitlement.dart';
import 'package:kaunti47_v2/src/features/journeys/application/journey_history.dart';
import 'package:kaunti47_v2/src/features/journeys/application/journey_providers.dart';
import 'package:kaunti47_v2/src/features/journeys/application/journey_recorder.dart';
import 'package:kaunti47_v2/src/features/journeys/data/journey_database.dart';
import 'package:kaunti47_v2/src/features/journeys/data/journey_upload_queue.dart';
import 'package:kaunti47_v2/src/features/journeys/data/local_journey_repository.dart';
import 'package:kaunti47_v2/src/features/journeys/data/supabase_journey_repository.dart';
import 'package:kaunti47_v2/src/features/journeys/domain/journey_fix.dart';
import 'package:kaunti47_v2/src/features/journeys/domain/journey_recording.dart';
import 'package:kaunti47_v2/src/features/journeys/domain/journey_summary.dart';
import 'package:kaunti47_v2/src/features/journeys/domain/pro_status.dart';

class _FakeSource implements JourneyLocationSource {
  // Closed by the test group's tearDown.
  // ignore: close_sinks
  final controller = StreamController<JourneyFix>.broadcast(sync: true);
  var started = false;
  JourneyLocationException? failStart;

  /// Fails the up-front guard Start checks before anything else -
  /// distinct from [failStart], which simulates losing location access
  /// in the gap between that guard and actually attaching.
  JourneyLocationException? failEnsureAvailable;
  Completer<void>? startGate;
  var autoEmitFix = true;

  @override
  Future<void> ensureAvailable() async {
    if (failEnsureAvailable case final error?) throw error;
  }

  @override
  Stream<JourneyFix> get fixes => controller.stream;

  @override
  Future<void> start({JourneyTransportMode? mode}) async {
    if (failStart case final error?) throw error;
    if (startGate case final gate?) await gate.future;
    started = true;
    // JourneyCapture.attachStarted now waits for an actual fix before
    // Start completes (see journey_capture.dart/noFixReceived) - simulate
    // a phone that gets a GPS lock right away, so the many tests below
    // that just `await recorder.start(...)` keep working unchanged. Tests
    // for a phone that never gets a fix belong in journey_capture_test.dart,
    // which owns that behavior directly.
    if (autoEmitFix) {
      Timer(Duration.zero, () {
        if (!controller.hasListener) return;
        controller.add(
          JourneyFix(
            recordedAt: DateTime.now(),
            latitude: -1.28,
            longitude: 36.82,
            accuracyMeters: 7,
          ),
        );
      });
    }
  }

  @override
  Future<void> stop() async => started = false;
}

class _FakeCloud implements SupabaseJourneyRepository {
  ProStatus? status;
  Completer<ProStatus>? statusGate;

  /// Defaults to plenty of free Trips left, so every existing Pro-path
  /// test (which never looks at this) keeps working unchanged.
  JourneyTrialStatus? trial = JourneyTrialStatus(
    tripsUsed: 0,
    tripLimit: 3,
    resetsAt: DateTime.utc(2026, 10, 1),
  );
  var offline = false;
  final cloudJourneys = <JourneySummary>[];
  var proStatusCalls = 0;

  @override
  String? get currentUserId => 'alice';

  @override
  Future<ProStatus> proStatus() async {
    proStatusCalls++;
    if (offline) throw Exception('offline');
    if (statusGate case final gate?) return gate.future;
    return status!;
  }

  @override
  Future<JourneyTrialStatus> trialStatus() async {
    if (offline) throw Exception('offline');
    return trial!;
  }

  @override
  Future<List<JourneySummary>> history() async {
    if (offline) throw Exception('offline');
    return cloudJourneys;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final now = DateTime.utc(2026, 9, 25, 12);
  late JourneyDatabase db;
  late _FakeSource source;
  late _FakeCloud cloud;
  late List<String> uploads;
  late StreamController<String?> auth;
  var signedInUser = 'alice';
  var uploadsFail = false;

  ProviderContainer container() {
    final c = ProviderContainer(
      overrides: [
        journeyDatabaseProvider.overrideWithValue(db),
        journeyLocationSourceProvider.overrideWithValue(source),
        currentUserIdProvider.overrideWithValue(() => signedInUser),
        authUserIdProvider.overrideWith((ref) => auth.stream),
        supabaseJourneyRepositoryProvider.overrideWithValue(cloud),
        journeyUploadQueueProvider.overrideWithValue(
          JourneyUploadQueue(
            db,
            currentUserId: () => 'alice',
            upload:
                ({
                  required userId,
                  required id,
                  required title,
                  required startedAt,
                  required endedAt,
                  required pausedDuration,
                  required points,
                  destination,
                }) async {
                  if (uploadsFail) throw Exception('offline');
                  uploads.add(id);
                },
          ),
        ),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  setUp(() {
    db = JourneyDatabase.forTesting(NativeDatabase.memory());
    source = _FakeSource();
    cloud = _FakeCloud();
    uploads = [];
    uploadsFail = false;
    signedInUser = 'alice';
    auth = StreamController<String?>.broadcast();
  });
  tearDown(() async {
    await auth.close();
    await source.controller.close();
    await db.close();
  });

  test('without Pro and the free Trip allowance used up, a Journey cannot '
      'start', () async {
    cloud.status = ProStatus(active: false, checkedAt: now);
    cloud.trial = JourneyTrialStatus(
      tripsUsed: 3,
      tripLimit: 3,
      resetsAt: DateTime.utc(2026, 10, 1),
    );
    final c = container();
    await expectLater(
      c.read(journeyRecorderProvider.notifier).start(now: now),
      throwsA(isA<JourneyTrialExhausted>()),
    );
    expect(c.read(journeyRecorderProvider), isNull);
    expect(source.started, isFalse);
  });

  test(
    'without Pro but with a free Trip left this month, a Journey starts',
    () async {
      cloud.status = ProStatus(active: false, checkedAt: now);
      cloud.trial = JourneyTrialStatus(
        tripsUsed: 2,
        tripLimit: 3,
        resetsAt: DateTime.utc(2026, 10, 1),
      );
      final c = container();
      await c.read(journeyRecorderProvider.notifier).start(now: now);
      expect(source.started, isTrue);
      expect(
        c.read(journeyRecorderProvider)?.recording.phase,
        JourneyRecordingPhase.recording,
      );
    },
  );

  test('with Pro it records, and finishing uploads it', () async {
    cloud.status = ProStatus(active: true, checkedAt: now);
    final c = container();
    final recorder = c.read(journeyRecorderProvider.notifier);

    await recorder.start(now: now);
    expect(source.started, isTrue);
    expect(
      c.read(journeyRecorderProvider)?.recording.phase,
      JourneyRecordingPhase.recording,
    );

    await recorder.finish();
    expect(c.read(journeyRecorderProvider), isNull);
    await c.read(journeySyncProvider.notifier).drain();
    expect(uploads, hasLength(1));
  });

  test('discarding stops recording and keeps nothing', () async {
    cloud.status = ProStatus(active: true, checkedAt: now);
    final c = container();
    final recorder = c.read(journeyRecorderProvider.notifier);

    await recorder.start(now: now);
    final id = c.read(journeyRecorderProvider)!.id;
    await recorder.discard();

    expect(c.read(journeyRecorderProvider), isNull);
    expect(await LocalJourneyRepository(db).activeSession('alice'), isNull);
    await expectLater(
      LocalJourneyRepository(db).points(id, 'alice'),
      throwsStateError,
    );
    await c.read(journeySyncProvider.notifier).drain();
    expect(uploads, isEmpty);
  });

  test('offline, a Journey cannot start, even after a good check', () async {
    cloud.status = ProStatus(active: true, checkedAt: now);
    final c = container();
    expect(
      await c.read(journeyEntitlementProvider.notifier).canStart(now: now),
      isTrue,
    );

    cloud.offline = true;
    await expectLater(
      c.read(journeyRecorderProvider.notifier).start(now: now),
      throwsA(isA<JourneyProCheckUnavailable>()),
    );
    expect(c.read(journeyRecorderProvider), isNull);
    expect(source.started, isFalse);
  });

  test('history lists waiting Journeys first, then the cloud', () async {
    cloud.status = ProStatus(active: true, checkedAt: now);
    cloud.cloudJourneys.add(
      JourneySummary(
        id: 'cloud-1',
        title: 'Earlier',
        startedAt: now.subtract(const Duration(days: 1)),
        endedAt: now.subtract(const Duration(hours: 20)),
        distanceMeters: 1200,
        isUploaded: true,
      ),
    );
    uploadsFail = true;
    final c = container();
    // Keep the auto-dispose history alive between reads.
    c.listen(journeyHistoryListProvider, (_, _) {});
    final recorder = c.read(journeyRecorderProvider.notifier);
    await recorder.start(now: now);
    await recorder.finish();

    final history = await c.read(journeyHistoryListProvider.future);
    expect(history.journeys.map((j) => j.isUploaded), [false, true]);

    cloud.offline = true;
    c.invalidate(journeyHistoryListProvider);
    final offline = await c.read(journeyHistoryListProvider.future);
    expect(offline.cloudUnavailable, isTrue);
    expect(offline.journeys, hasLength(1));
  });

  test('another account signing in lets go of the Journey', () async {
    cloud.status = ProStatus(active: true, checkedAt: now);
    final c = container();
    c.listen(journeyRecorderProvider, (_, _) {});
    await c.read(journeyRecorderProvider.notifier).start(now: now);
    auth.add('alice');
    await pumpEventQueue();
    expect(c.read(journeyRecorderProvider), isNotNull);

    auth.add('bob');
    await pumpEventQueue();
    expect(c.read(journeyRecorderProvider), isNull);
    expect(source.started, isFalse);
    // Saved, paused, for alice to resume later.
    final saved = await c
        .read(localJourneyRepositoryProvider)
        .activeSession('alice');
    expect(saved?.recording.phase, JourneyRecordingPhase.paused);
  });

  test('account switch during Pro check blocks Start', () async {
    cloud.statusGate = Completer<ProStatus>();
    final c = container();
    c.listen(journeyRecorderProvider, (_, _) {});
    final pending = c.read(journeyRecorderProvider.notifier).start(now: now);
    await pumpEventQueue();
    signedInUser = 'bob';
    auth.add('bob');
    cloud.statusGate!.complete(ProStatus(active: true, checkedAt: now));
    await expectLater(pending, throwsStateError);
    expect(c.read(journeyRecorderProvider), isNull);
    expect(source.started, isFalse);
    expect(
      await c.read(localJourneyRepositoryProvider).activeSession('alice'),
      isNull,
    );
  });

  test('account switch during native startup detaches', () async {
    cloud.status = ProStatus(active: true, checkedAt: now);
    source.startGate = Completer<void>();
    final c = container();
    c.listen(journeyRecorderProvider, (_, _) {});
    final pending = c.read(journeyRecorderProvider.notifier).start(now: now);
    await pumpEventQueue();
    signedInUser = 'bob';
    auth.add('bob');
    source.startGate!.complete();
    await expectLater(pending, throwsStateError);
    expect(c.read(journeyRecorderProvider), isNull);
    expect(source.started, isFalse);
    final alice = await c
        .read(localJourneyRepositoryProvider)
        .activeSession('alice');
    expect(alice?.recording.phase, JourneyRecordingPhase.paused);
  });

  test('location stream failure updates recording state', () async {
    cloud.status = ProStatus(active: true, checkedAt: now);
    final c = container();
    c.listen(journeyRecorderProvider, (_, _) {});
    await c.read(journeyRecorderProvider.notifier).start(now: now);
    source.controller.addError(StateError('Location stream stopped'));
    await pumpEventQueue();
    expect(
      c.read(journeyRecorderProvider)?.recording.phase,
      JourneyRecordingPhase.paused,
    );
    expect(source.started, isFalse);
  });

  test("a phone that can't record drops the Journey", () async {
    cloud.status = ProStatus(active: true, checkedAt: now);
    source.failStart = const JourneyLocationException(
      JourneyLocationFailure.backgroundPermissionDenied,
    );
    final c = container();
    await expectLater(
      c.read(journeyRecorderProvider.notifier).start(now: now),
      throwsA(isA<JourneyLocationException>()),
    );
    expect(c.read(journeyRecorderProvider), isNull);
    expect(
      await c.read(localJourneyRepositoryProvider).activeSession('alice'),
      isNull,
    );
  });

  test(
    'a phone with no location access fails before the Pro/trial check or '
    'any local session, not after',
    () async {
      source.failEnsureAvailable = const JourneyLocationException(
        JourneyLocationFailure.servicesDisabled,
      );
      final c = container();
      await expectLater(
        c.read(journeyRecorderProvider.notifier).start(now: now),
        throwsA(isA<JourneyLocationException>()),
      );
      expect(c.read(journeyRecorderProvider), isNull);
      expect(source.started, isFalse);
      // Never reached the live entitlement check or created a session.
      expect(cloud.proStatusCalls, 0);
      expect(
        await c.read(localJourneyRepositoryProvider).activeSession('alice'),
        isNull,
      );
    },
  );
}
