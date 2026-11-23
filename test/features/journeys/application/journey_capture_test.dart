import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/journeys/application/journey_capture.dart';
import 'package:kaunti47_v2/src/features/journeys/data/journey_database.dart';
import 'package:kaunti47_v2/src/features/journeys/data/local_journey_repository.dart';
import 'package:kaunti47_v2/src/features/journeys/domain/journey_device_settings.dart';
import 'package:kaunti47_v2/src/features/journeys/domain/journey_fix.dart';
import 'package:kaunti47_v2/src/features/journeys/domain/journey_pause_reason.dart';
import 'package:kaunti47_v2/src/features/journeys/domain/journey_recording.dart';
import 'package:kaunti47_v2/src/features/journeys/domain/journey_transport_mode.dart';

class FakeJourneyLocationSource implements JourneyLocationSource {
  final controller = StreamController<JourneyFix>.broadcast(sync: true);
  Stream<JourneyFix>? overrideFixes;
  bool started = false;
  bool failStart = false;
  bool hangOnStop = false;

  // JourneyCapture never calls this itself - only JourneyRecorder's
  // up-front Start guard does, which these tests exercise separately.
  @override
  Future<void> ensureAvailable() async {}

  @override
  Stream<JourneyFix> get fixes => overrideFixes ?? controller.stream;

  @override
  Future<void> start({JourneyTransportMode? mode}) async {
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

class FakeSettingsSource implements JourneyDeviceSettingsSource {
  FakeSettingsSource(this.result);

  final Future<JourneyDeviceSettings> Function() result;

  @override
  Future<JourneyDeviceSettings> read() => result();
}

void main() {
  final t0 = DateTime.utc(2026, 9, 25, 12);
  late JourneyDatabase db;
  late LocalJourneyRepository repository;
  late FakeJourneyLocationSource source;
  late DateTime now;
  late JourneyCapture capture;
  late List<String> diagnosticEvents;

  setUp(() {
    db = JourneyDatabase.forTesting(NativeDatabase.memory());
    repository = LocalJourneyRepository(db);
    source = FakeJourneyLocationSource();
    now = t0;
    diagnosticEvents = [];
    capture = JourneyCapture(
      repository: repository,
      locationSource: source,
      clock: () => now,
      streamRecoveryDelays: const [Duration.zero],
      onDiagnosticEvent: (event, data) async => diagnosticEvents.add(event),
    );
  });
  tearDown(() async {
    await source.dispose();
    await db.close();
  });

  test('captures ordered fixes and stops source on pause', () async {
    final session = await repository.start(id: 'one', userId: 'alice', at: t0);
    final attaching = capture.attachStarted(session: session, userId: 'alice');
    await pumpEventQueue();
    source.controller.add(
      JourneyFix(
        recordedAt: t0.add(const Duration(milliseconds: 150)),
        latitude: -1.28,
        longitude: 36.82,
        accuracyMeters: 7,
      ),
    );
    await attaching;
    expect(source.started, isTrue);
    now = t0.add(const Duration(seconds: 1));
    final paused = await capture.pause();
    expect(paused.recording.phase, JourneyRecordingPhase.paused);
    expect(source.started, isFalse);
    expect((await repository.points('one', 'alice')).length, 1);
  });

  test('a long gap in valid fixes starts a new route segment', () async {
    final session = await repository.start(id: 'one', userId: 'alice', at: t0);
    final attaching = capture.attachStarted(session: session, userId: 'alice');
    await pumpEventQueue();
    source.controller.add(
      JourneyFix(
        recordedAt: t0.add(const Duration(seconds: 5)),
        latitude: -1.28 + 5 / 10000,
        longitude: 36.82,
        accuracyMeters: 7,
      ),
    );
    await attaching;
    source.controller.add(
      JourneyFix(
        recordedAt: t0.add(const Duration(seconds: 190)),
        latitude: -1.28 + 190 / 10000,
        longitude: 36.82,
        accuracyMeters: 7,
      ),
    );
    now = t0.add(const Duration(minutes: 4));
    await capture.pause();
    final points = await repository.points('one', 'alice');
    expect(points.map((point) => point.segmentNumber), [0, 1]);
    expect(diagnosticEvents, contains('journey_segment_gap'));
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
    final attaching = capture.attachStarted(session: session, userId: 'alice');
    await pumpEventQueue();
    source.controller.add(
      JourneyFix(
        recordedAt: t0.add(const Duration(minutes: 1)),
        latitude: -1.28,
        longitude: 36.82,
        accuracyMeters: 7,
      ),
    );
    await attaching;
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

  test('a location stream failure recovers and starts a new segment', () async {
    var pauseNotifications = 0;
    capture.onUnexpectedPause = (_) => pauseNotifications++;
    final session = await repository.start(id: 'one', userId: 'alice', at: t0);
    final attaching = capture.attachStarted(session: session, userId: 'alice');
    await pumpEventQueue();
    source.controller.add(
      JourneyFix(
        recordedAt: t0.add(const Duration(seconds: 1)),
        latitude: -1.28,
        longitude: 36.82,
        accuracyMeters: 7,
      ),
    );
    await attaching;
    now = t0.add(const Duration(seconds: 2));
    source.controller.addError(StateError('GPS stopped'));
    await pumpEventQueue();
    expect(capture.session?.recording.phase, JourneyRecordingPhase.recording);
    for (
      var attempt = 0;
      attempt < 100 && !diagnosticEvents.contains('journey_location_recovered');
      attempt++
    ) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(capture.lastError, isA<StateError>());
    expect(capture.session?.recording.phase, JourneyRecordingPhase.recording);
    expect(source.started, isTrue);
    source.controller.add(
      JourneyFix(
        recordedAt: t0.add(const Duration(seconds: 10)),
        latitude: -1.27,
        longitude: 36.82,
        accuracyMeters: 7,
      ),
    );
    await pumpEventQueue();
    await capture.pause();
    expect(
      (await repository.points(
        'one',
        'alice',
      )).map((point) => point.segmentNumber),
      [0, 1],
    );
    expect(diagnosticEvents, contains('journey_location_recovered'));
    expect(pauseNotifications, 0);
  });

  test('capture pauses only after all stream recovery attempts fail', () async {
    var pauseNotifications = 0;
    capture.onUnexpectedPause = (_) => pauseNotifications++;
    final session = await repository.start(id: 'one', userId: 'alice', at: t0);
    final attaching = capture.attachStarted(session: session, userId: 'alice');
    await pumpEventQueue();
    source.controller.add(
      JourneyFix(
        recordedAt: t0.add(const Duration(seconds: 1)),
        latitude: -1.28,
        longitude: 36.82,
        accuracyMeters: 7,
      ),
    );
    await attaching;
    source.failStart = true;
    source.controller.addError(StateError('GPS stopped'));
    for (
      var attempt = 0;
      attempt < 100 &&
          capture.session?.recording.phase != JourneyRecordingPhase.paused;
      attempt++
    ) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(capture.session?.recording.phase, JourneyRecordingPhase.paused);
    expect(diagnosticEvents, contains('journey_location_recovery_failed'));
    expect(pauseNotifications, 1);
  });

  test('an unexpectedly closed location stream is restarted', () async {
    final session = await repository.start(id: 'one', userId: 'alice', at: t0);
    final attaching = capture.attachStarted(session: session, userId: 'alice');
    await pumpEventQueue();
    source.controller.add(
      JourneyFix(
        recordedAt: t0.add(const Duration(seconds: 1)),
        latitude: -1.28,
        longitude: 36.82,
        accuracyMeters: 7,
      ),
    );
    await attaching;
    final replacement = StreamController<JourneyFix>.broadcast(sync: true);
    addTearDown(replacement.close);
    source.overrideFixes = replacement.stream;
    final oldController = source.controller;
    await oldController.close();
    for (
      var attempt = 0;
      attempt < 100 && !diagnosticEvents.contains('journey_location_recovered');
      attempt++
    ) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(capture.session?.recording.phase, JourneyRecordingPhase.recording);
    expect(source.started, isTrue);
    replacement.add(
      JourneyFix(
        recordedAt: t0.add(const Duration(seconds: 10)),
        latitude: -1.27,
        longitude: 36.82,
        accuracyMeters: 7,
      ),
    );
    await pumpEventQueue();
    await capture.pause();
    expect(
      (await repository.points(
        'one',
        'alice',
      )).map((point) => point.segmentNumber),
      [0, 1],
    );
  });

  test('Stop waits for confirmed native shutdown and can be retried', () async {
    final hanging = JourneyCapture(
      repository: repository,
      locationSource: source,
      clock: () => now,
      teardownTimeout: const Duration(milliseconds: 50),
    );
    final session = await repository.start(id: 'one', userId: 'alice', at: t0);
    final attaching = hanging.attachStarted(session: session, userId: 'alice');
    await pumpEventQueue();
    source.controller.add(
      JourneyFix(
        recordedAt: t0,
        latitude: -1.28,
        longitude: 36.82,
        accuracyMeters: 7,
      ),
    );
    await attaching;
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

  test('a Start that never gets a GPS fix times out and leaves the Journey '
      'paused, not stuck Recording', () async {
    final noFix = JourneyCapture(
      repository: repository,
      locationSource: source,
      clock: () => now,
      firstFixTimeout: const Duration(milliseconds: 20),
    );
    final session = await repository.start(id: 'one', userId: 'alice', at: t0);
    await expectLater(
      noFix.attachStarted(session: session, userId: 'alice'),
      throwsA(
        isA<JourneyLocationException>().having(
          (error) => error.reason,
          'reason',
          JourneyLocationFailure.noFixReceived,
        ),
      ),
    );
    expect(source.started, isFalse);
    expect(
      (await repository.activeSession('alice'))?.recording.phase,
      JourneyRecordingPhase.paused,
    );
  });

  test('waits for stream cancellation before native stop', () async {
    final cancelGate = Completer<void>();
    var cancelCalls = 0;
    final slowStream = StreamController<JourneyFix>(
      onCancel: () {
        cancelCalls++;
        return cancelGate.future;
      },
    );
    source.overrideFixes = slowStream.stream;
    addTearDown(slowStream.close);
    final slow = JourneyCapture(
      repository: repository,
      locationSource: source,
      clock: () => now,
      teardownTimeout: const Duration(milliseconds: 50),
    );
    final session = await repository.start(id: 'one', userId: 'alice', at: t0);
    final attaching = slow.attachStarted(session: session, userId: 'alice');
    await pumpEventQueue();
    slowStream.add(
      JourneyFix(
        recordedAt: t0,
        latitude: -1.28,
        longitude: 36.82,
        accuracyMeters: 7,
      ),
    );
    await attaching;
    now = t0.add(const Duration(minutes: 1));

    await expectLater(slow.finish(), throwsA(isA<JourneyTeardownException>()));
    expect(source.started, isFalse);
    expect(cancelCalls, 1);
    cancelGate.complete();

    final finished = await slow.finish();
    expect(finished.recording.phase, JourneyRecordingPhase.completed);
    expect(source.started, isFalse);
    expect(cancelCalls, 1);
  });

  test(
    'recovery stops a background service left alive by process death',
    () async {
      final session = await repository.start(
        id: 'one',
        userId: 'alice',
        at: t0,
      );
      source.started = true;

      final recovered = await capture.recover('alice');

      expect(recovered?.id, session.id);
      expect(recovered?.recording.phase, JourneyRecordingPhase.paused);
      expect(source.started, isFalse);
    },
  );

  test('a pause the person makes is recorded as a user pause', () async {
    final session = await repository.start(id: 'one', userId: 'alice', at: t0);
    final attaching = capture.attachStarted(session: session, userId: 'alice');
    await pumpEventQueue();
    source.controller.add(
      JourneyFix(
        recordedAt: t0.add(const Duration(seconds: 1)),
        latitude: -1.28,
        longitude: 36.82,
        accuracyMeters: 7,
      ),
    );
    await attaching;
    now = t0.add(const Duration(seconds: 2));

    final paused = await capture.pause();

    expect(paused.pauseReason, JourneyPauseReason.user);
    expect(
      await repository.pauseReason('one', 'alice'),
      JourneyPauseReason.user,
    );
  });

  test('a recovered session is paused as app restarted', () async {
    await repository.start(id: 'one', userId: 'alice', at: t0);
    now = t0.add(const Duration(minutes: 3));

    final recovered = await capture.recover('alice');

    expect(recovered?.pauseReason, JourneyPauseReason.appRestarted);
    expect(
      await repository.pauseReason('one', 'alice'),
      JourneyPauseReason.appRestarted,
    );
  });

  test('resuming clears the pause reason', () async {
    await repository.start(id: 'one', userId: 'alice', at: t0);
    now = t0.add(const Duration(minutes: 3));
    await capture.recover('alice');
    now = t0.add(const Duration(minutes: 5));

    final resumed = await capture.resume();

    expect(resumed.pauseReason, isNull);
    expect(await repository.pauseReason('one', 'alice'), isNull);
  });

  test('a failed start pauses as start failed', () async {
    final session = await repository.start(id: 'one', userId: 'alice', at: t0);
    source.failStart = true;
    await expectLater(
      capture.attachStarted(session: session, userId: 'alice'),
      throwsStateError,
    );
    expect(
      await repository.pauseReason('one', 'alice'),
      JourneyPauseReason.startFailed,
    );
  });

  test('a lost stream keeps recording through the recovery window', () async {
    var pauseNotifications = 0;
    final patient = JourneyCapture(
      repository: repository,
      locationSource: source,
      clock: () => now,
      streamRecoveryDelays: const [Duration.zero],
      recoveryRepeatDelay: const Duration(milliseconds: 20),
      maxRecoveryTime: const Duration(milliseconds: 300),
      onDiagnosticEvent: (event, data) async => diagnosticEvents.add(event),
    )..onUnexpectedPause = (_) => pauseNotifications++;
    final session = await repository.start(id: 'one', userId: 'alice', at: t0);
    final attaching = patient.attachStarted(session: session, userId: 'alice');
    await pumpEventQueue();
    source.controller.add(
      JourneyFix(
        recordedAt: t0.add(const Duration(seconds: 1)),
        latitude: -1.28,
        longitude: 36.82,
        accuracyMeters: 7,
      ),
    );
    await attaching;
    source.failStart = true;
    source.controller.addError(StateError('GPS stopped'));

    await Future<void>.delayed(const Duration(milliseconds: 120));
    expect(patient.session?.recording.phase, JourneyRecordingPhase.recording);
    expect(pauseNotifications, 0);

    for (
      var attempt = 0;
      attempt < 100 &&
          patient.session?.recording.phase != JourneyRecordingPhase.paused;
      attempt++
    ) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    expect(patient.session?.recording.phase, JourneyRecordingPhase.paused);
    expect(patient.session?.pauseReason, JourneyPauseReason.locationLost);
    expect(pauseNotifications, 1);
  });

  test('a locationLost pause re-reads device settings, since battery saver '
      'or similar can switch on partway through a Trip, after the settings '
      'read at start', () async {
    var reads = 0;
    final patient = JourneyCapture(
      repository: repository,
      locationSource: source,
      clock: () => now,
      streamRecoveryDelays: const [Duration.zero],
      recoveryRepeatDelay: const Duration(milliseconds: 20),
      maxRecoveryTime: const Duration(milliseconds: 300),
      deviceSettings: FakeSettingsSource(() async {
        reads++;
        // Clean at start, battery saver on by the time it is read again
        // right before the pause.
        return reads == 1
            ? const JourneyDeviceSettings(batterySaver: false)
            : const JourneyDeviceSettings(batterySaver: true);
      }),
    );
    final session = await repository.start(id: 'one', userId: 'alice', at: t0);
    final attaching = patient.attachStarted(session: session, userId: 'alice');
    await pumpEventQueue();
    source.controller.add(
      JourneyFix(
        recordedAt: t0.add(const Duration(seconds: 1)),
        latitude: -1.28,
        longitude: 36.82,
        accuracyMeters: 7,
      ),
    );
    await attaching;
    expect(patient.quality.settings?.batterySaver, false);

    source.failStart = true;
    source.controller.addError(StateError('GPS stopped'));

    for (
      var attempt = 0;
      attempt < 100 &&
          patient.session?.recording.phase != JourneyRecordingPhase.paused;
      attempt++
    ) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }

    expect(patient.session?.recording.phase, JourneyRecordingPhase.paused);
    expect(patient.session?.pauseReason, JourneyPauseReason.locationLost);
    // The settings read at start are untouched; the pause-time read is a
    // separate snapshot that caught what actually changed.
    expect(patient.quality.settings?.batterySaver, false);
    expect(patient.quality.settingsAtPause?.batterySaver, true);

    final saved = await repository.quality('one', 'alice');
    expect(saved?.settingsAtPause?.batterySaver, true);
  });

  group('GPS spikes', () {
    JourneyFix northOf(int seconds, double metres) => JourneyFix(
      recordedAt: t0.add(Duration(seconds: seconds)),
      latitude: -1.28 + metres / 111000,
      longitude: 36.82,
      accuracyMeters: 8,
    );

    Future<void> attachWalking() async {
      final session = await repository.start(
        id: 'one',
        userId: 'alice',
        at: t0,
        mode: JourneyTransportMode.walk,
      );
      final attaching = capture.attachStarted(
        session: session,
        userId: 'alice',
      );
      await pumpEventQueue();
      source.controller.add(northOf(1, 0));
      await attaching;
    }

    test('a single spike is left out of the route', () async {
      await attachWalking();
      source.controller
        ..add(northOf(11, 15))
        ..add(northOf(21, 600))
        ..add(northOf(31, 45));
      await pumpEventQueue();
      now = t0.add(const Duration(minutes: 2));
      await capture.pause();

      final points = await repository.points('one', 'alice');
      expect(points, hasLength(3));
      expect(points.map((point) => point.segmentNumber), [0, 0, 0]);
      expect(capture.spikesDropped, 1);
      expect(diagnosticEvents, contains('journey_spike_dropped'));
    });

    test('a jump confirmed by the next fix starts a new segment', () async {
      await attachWalking();
      source.controller
        ..add(northOf(11, 15))
        ..add(northOf(21, 2000))
        ..add(northOf(31, 2020));
      await pumpEventQueue();
      now = t0.add(const Duration(minutes: 2));
      await capture.pause();

      final points = await repository.points('one', 'alice');
      expect(points.map((point) => point.segmentNumber), [0, 0, 1, 1]);
      expect(capture.jumpsAccepted, 1);
      expect(capture.spikesDropped, 0);
      expect(diagnosticEvents, contains('journey_jump_accepted'));
    });
  });

  group('Trip quality', () {
    test('counts accepted fixes and a user pause, and saves them', () async {
      final session = await repository.start(
        id: 'one',
        userId: 'alice',
        at: t0,
      );
      final attaching = capture.attachStarted(
        session: session,
        userId: 'alice',
      );
      await pumpEventQueue();
      source.controller
        ..add(
          JourneyFix(
            recordedAt: t0.add(const Duration(seconds: 1)),
            latitude: -1.28,
            longitude: 36.82,
            accuracyMeters: 7,
          ),
        )
        ..add(
          JourneyFix(
            recordedAt: t0.add(const Duration(seconds: 11)),
            latitude: -1.2799,
            longitude: 36.82,
            accuracyMeters: 7,
          ),
        );
      await attaching;
      await pumpEventQueue();
      now = t0.add(const Duration(minutes: 1));

      await capture.pause();

      final saved = await repository.quality('one', 'alice');
      expect(saved, isNotNull);
      expect(saved!.fixesAccepted, 2);
      expect(saved.userPauses, 1);
      expect(saved.systemPauses, 0);
    });

    test('a recovered session counts an app-restart pause', () async {
      await repository.start(id: 'one', userId: 'alice', at: t0);
      now = t0.add(const Duration(minutes: 3));

      await capture.recover('alice');

      final saved = await repository.quality('one', 'alice');
      expect(saved?.pausesByReason['app_restarted'], 1);
      expect(saved?.systemPauses, 1);
    });

    test('a lost and restarted stream is counted', () async {
      final session = await repository.start(
        id: 'one',
        userId: 'alice',
        at: t0,
      );
      final attaching = capture.attachStarted(
        session: session,
        userId: 'alice',
      );
      await pumpEventQueue();
      source.controller.add(
        JourneyFix(
          recordedAt: t0.add(const Duration(seconds: 1)),
          latitude: -1.28,
          longitude: 36.82,
          accuracyMeters: 7,
        ),
      );
      await attaching;
      source.controller.addError(StateError('GPS stopped'));
      for (
        var attempt = 0;
        attempt < 100 &&
            !diagnosticEvents.contains('journey_location_recovered');
        attempt++
      ) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }

      expect(capture.quality.streamLosses, 1);
      expect(capture.quality.streamRecoveries, 1);
      final saved = await repository.quality('one', 'alice');
      expect(saved?.streamRecoveries, 1);
    });

    test('a Trip recorded before quality existed reads as null', () async {
      await repository.start(id: 'one', userId: 'alice', at: t0);

      expect(await repository.quality('one', 'alice'), isNull);
    });
  });

  group('device settings', () {
    JourneyFix firstFix() => JourneyFix(
      recordedAt: t0.add(const Duration(seconds: 1)),
      latitude: -1.28,
      longitude: 36.82,
      accuracyMeters: 7,
    );

    test('are read at start and saved with the Trip quality', () async {
      final withSettings = JourneyCapture(
        repository: repository,
        locationSource: source,
        clock: () => now,
        deviceSettings: FakeSettingsSource(
          () async => const JourneyDeviceSettings(
            batterySaver: true,
            batteryPercent: 40,
          ),
        ),
      );
      final session = await repository.start(
        id: 'one',
        userId: 'alice',
        at: t0,
      );
      final attaching = withSettings.attachStarted(
        session: session,
        userId: 'alice',
      );
      await pumpEventQueue();
      source.controller.add(firstFix());
      await attaching;
      now = t0.add(const Duration(minutes: 1));

      await withSettings.pause();

      final saved = await repository.quality('one', 'alice');
      expect(saved?.settings?.batterySaver, isTrue);
      expect(saved?.settings?.batteryPercent, 40);
    });

    test('a failing reading does not stop the Trip starting', () async {
      final failing = JourneyCapture(
        repository: repository,
        locationSource: source,
        clock: () => now,
        deviceSettings: FakeSettingsSource(
          () async => throw StateError('no battery info'),
        ),
      );

      expect(await failing.readDeviceSettings(), isNull);

      final session = await repository.start(
        id: 'one',
        userId: 'alice',
        at: t0,
      );
      final attaching = failing.attachStarted(
        session: session,
        userId: 'alice',
      );
      await pumpEventQueue();
      source.controller.add(firstFix());
      await attaching;
      expect(failing.session?.recording.phase, JourneyRecordingPhase.recording);
      expect(failing.quality.settings, isNull);
    });

    test('without a source there are no settings', () async {
      expect(await capture.readDeviceSettings(), isNull);
    });
  });
}
