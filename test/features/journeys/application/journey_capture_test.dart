import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/journeys/application/journey_capture.dart';
import 'package:kaunti47_v2/src/features/journeys/data/journey_database.dart';
import 'package:kaunti47_v2/src/features/journeys/data/local_journey_repository.dart';
import 'package:kaunti47_v2/src/features/journeys/domain/journey_fix.dart';
import 'package:kaunti47_v2/src/features/journeys/domain/journey_recording.dart';

class FakeJourneyLocationSource implements JourneyLocationSource {
  final controller = StreamController<JourneyFix>.broadcast(sync: true);
  Stream<JourneyFix>? overrideFixes;
  bool started = false;
  bool failStart = false;
  bool hangOnStop = false;

  @override
  Stream<JourneyFix> get fixes => overrideFixes ?? controller.stream;

  @override
  Future<void> start() async {
    if (failStart) throw StateError('Location unavailable');
    started = true;
  }

  @override
  Future<void> stop() {
    if (hangOnStop) return Completer<void>().future;
    started = false;
    return Future.value();
  }

  Future<void> dispose() => controller.close();
}

void main() {
  final t0 = DateTime.utc(2026, 9, 25, 12);
  late JourneyDatabase db;
  late LocalJourneyRepository repository;
  late FakeJourneyLocationSource source;
  late DateTime now;
  late JourneyCapture capture;

  setUp(() {
    db = JourneyDatabase.forTesting(NativeDatabase.memory());
    repository = LocalJourneyRepository(db);
    source = FakeJourneyLocationSource();
    now = t0;
    capture = JourneyCapture(
      repository: repository,
      locationSource: source,
      clock: () => now,
    );
  });
  tearDown(() async {
    await source.dispose();
    await db.close();
  });

  test('captures ordered fixes and stops source on pause', () async {
    final session = await repository.start(id: 'one', userId: 'alice', at: t0);
    await capture.attachStarted(session: session, userId: 'alice');
    expect(source.started, isTrue);
    source.controller.add(
      JourneyFix(
        recordedAt: t0.add(const Duration(milliseconds: 150)),
        latitude: -1.28,
        longitude: 36.82,
        accuracyMeters: 7,
      ),
    );
    now = t0.add(const Duration(seconds: 1));
    final paused = await capture.pause();
    expect(paused.recording.phase, JourneyRecordingPhase.paused);
    expect(source.started, isFalse);
    expect((await repository.points('one', 'alice')).length, 1);
  });

  test('a long gap in valid fixes starts a new route segment', () async {
    final session = await repository.start(id: 'one', userId: 'alice', at: t0);
    await capture.attachStarted(session: session, userId: 'alice');
    for (final seconds in [5, 190]) {
      source.controller.add(
        JourneyFix(
          recordedAt: t0.add(Duration(seconds: seconds)),
          latitude: -1.28 + seconds / 10000,
          longitude: 36.82,
          accuracyMeters: 7,
        ),
      );
    }
    now = t0.add(const Duration(minutes: 4));
    await capture.pause();
    final points = await repository.points('one', 'alice');
    expect(points.map((point) => point.segmentNumber), [0, 1]);
  });

  test('restart pauses old session and Resume creates a route gap', () async {
    await repository.start(id: 'one', userId: 'alice', at: t0);
    now = t0.add(const Duration(minutes: 3));
    final recovered = await capture.recover('alice');
    expect(recovered?.recording.phase, JourneyRecordingPhase.paused);
    expect(source.started, isFalse);

    now = t0.add(const Duration(minutes: 5));
    final resumed = await capture.resume();
    expect(resumed.recording.segmentNumber, 1);
    source.controller.add(
      JourneyFix(
        recordedAt: now.add(const Duration(milliseconds: 100)),
        latitude: -1.28,
        longitude: 36.82,
        accuracyMeters: 7,
      ),
    );
    now = t0.add(const Duration(minutes: 6));
    final finished = await capture.finish();
    expect(source.started, isFalse);
    expect((await repository.points('one', 'alice')).single.segmentNumber, 1);
    expect(finished.recording.recordedTime(now), const Duration(minutes: 1));
  });

  test('restart counts only time through the last saved fix', () async {
    final session = await repository.start(id: 'one', userId: 'alice', at: t0);
    await capture.attachStarted(session: session, userId: 'alice');
    source.controller.add(
      JourneyFix(
        recordedAt: t0.add(const Duration(minutes: 1)),
        latitude: -1.28,
        longitude: 36.82,
        accuracyMeters: 7,
      ),
    );
    await pumpEventQueue();
    expect(await repository.points('one', 'alice'), hasLength(1));
    now = t0.add(const Duration(hours: 2));
    final restarted = JourneyCapture(
      repository: repository,
      locationSource: source,
      clock: () => now,
    );
    final recovered = await restarted.recover('alice');
    expect(recovered?.recording.recordedTime(now), const Duration(minutes: 1));
  });

  test('failed native start leaves the saved Journey paused', () async {
    final session = await repository.start(id: 'one', userId: 'alice', at: t0);
    source.failStart = true;
    expect(
      capture.attachStarted(session: session, userId: 'alice'),
      throwsStateError,
    );
    await Future<void>.delayed(Duration.zero);
    expect(
      (await repository.activeSession('alice'))?.recording.phase,
      JourneyRecordingPhase.paused,
    );
  });

  test('a location stream failure pauses capture', () async {
    final session = await repository.start(id: 'one', userId: 'alice', at: t0);
    await capture.attachStarted(session: session, userId: 'alice');
    now = t0.add(const Duration(seconds: 2));
    source.controller.addError(StateError('GPS stopped'));
    for (
      var attempt = 0;
      attempt < 100 &&
          capture.session?.recording.phase != JourneyRecordingPhase.paused;
      attempt++
    ) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(capture.lastError, isA<StateError>());
    expect(capture.session?.recording.phase, JourneyRecordingPhase.paused);
    expect(source.started, isFalse);
  });

  test('Stop waits for confirmed native shutdown and can be retried', () async {
    final hanging = JourneyCapture(
      repository: repository,
      locationSource: source,
      clock: () => now,
      teardownTimeout: const Duration(milliseconds: 50),
    );
    final session = await repository.start(id: 'one', userId: 'alice', at: t0);
    await hanging.attachStarted(session: session, userId: 'alice');
    source.hangOnStop = true;
    now = t0.add(const Duration(minutes: 1));

    await expectLater(
      hanging.finish(),
      throwsA(isA<JourneyTeardownException>()),
    );
    expect(hanging.session?.recording.phase, JourneyRecordingPhase.paused);
    source.hangOnStop = false;
    final finished = await hanging.finish();
    expect(finished.recording.phase, JourneyRecordingPhase.completed);
    expect(source.started, isFalse);
    expect(hanging.session, isNull);
  });

  test('waits for stream cancellation before native stop', () async {
    final cancelGate = Completer<void>();
    var cancelCalls = 0;
    final slowStream = StreamController<JourneyFix>(onCancel: () {
      cancelCalls++;
      return cancelGate.future;
    });
    source.overrideFixes = slowStream.stream;
    addTearDown(slowStream.close);
    final slow = JourneyCapture(
      repository: repository,
      locationSource: source,
      clock: () => now,
      teardownTimeout: const Duration(milliseconds: 50),
    );
    final session = await repository.start(id: 'one', userId: 'alice', at: t0);
    await slow.attachStarted(session: session, userId: 'alice');
    now = t0.add(const Duration(minutes: 1));

    await expectLater(slow.finish(), throwsA(isA<JourneyTeardownException>()));
    expect(source.started, isTrue);
    expect(cancelCalls, 1);
    cancelGate.complete();

    final finished = await slow.finish();
    expect(finished.recording.phase, JourneyRecordingPhase.completed);
    expect(source.started, isFalse);
    expect(cancelCalls, 1);
  });
}
