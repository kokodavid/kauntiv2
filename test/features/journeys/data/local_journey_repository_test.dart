import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/journeys/data/journey_database.dart';
import 'package:kaunti47_v2/src/features/journeys/data/local_journey_repository.dart';
import 'package:kaunti47_v2/src/features/journeys/domain/journey_destination.dart';
import 'package:kaunti47_v2/src/features/journeys/domain/journey_point.dart';
import 'package:kaunti47_v2/src/features/journeys/domain/journey_recording.dart';
import 'package:kaunti47_v2/src/features/journeys/domain/journey_transport_mode.dart';

void main() {
  final started = DateTime.utc(2026, 9, 25, 10);

  JourneyPoint point(int minute, int segment) => JourneyPoint(
    recordedAt: started.add(Duration(minutes: minute)),
    latitude: -1.286389,
    longitude: 36.817223,
    accuracyMeters: 8,
    segmentNumber: segment,
  );

  group('local Journey recording', () {
    late JourneyDatabase db;
    late LocalJourneyRepository repo;

    setUp(() {
      db = JourneyDatabase.forTesting(NativeDatabase.memory());
      repo = LocalJourneyRepository(db);
    });
    tearDown(() => db.close());

    test('keeps a place destination across repository recreation', () async {
      const destination = JourneyDestination(
        placeId: 'place-1',
        name: 'Nairobi National Museum',
        latitude: -1.273,
        longitude: 36.814,
      );
      await repo.start(
        id: 'journey-1',
        userId: 'alice',
        at: started,
        destination: destination,
      );
      final reopened = LocalJourneyRepository(db);
      final stored = await reopened.destination('journey-1', 'alice');
      expect(stored?.placeId, destination.placeId);
      expect(stored?.name, destination.name);
      expect(stored?.latitude, destination.latitude);
      expect(stored?.longitude, destination.longitude);
      expect(await reopened.destination('journey-1', 'bob'), isNull);
    });

    test('rejects a destination that cannot be uploaded', () async {
      expect(
        repo.start(
          id: 'journey-1',
          userId: 'alice',
          at: started,
          destination: const JourneyDestination(
            placeId: 'place-1',
            name: 'Museum',
            latitude: 120,
            longitude: 36.8,
          ),
        ),
        throwsArgumentError,
      );
      expect(await repo.activeSession('alice'), isNull);
    });

    test('keeps paused time across a restart', () async {
      await repo.start(id: 'journey-p', userId: 'alice', at: started);
      await repo.pause(
        id: 'journey-p',
        userId: 'alice',
        at: started.add(const Duration(minutes: 5)),
      );
      await repo.resume(
        id: 'journey-p',
        userId: 'alice',
        at: started.add(const Duration(minutes: 9)),
      );
      // A fresh repository reads it back from the database.
      final saved = await LocalJourneyRepository(db).activeSession('alice');
      expect(saved!.recording.pausedTotal, const Duration(minutes: 4));
    });

    test('persists points and starts a new segment after pause', () async {
      await repo.start(id: 'journey-1', userId: 'alice', at: started);
      expect(
        await repo.appendPoint(
          id: 'journey-1',
          userId: 'alice',
          point: point(1, 0),
        ),
        0,
      );
      await repo.pause(
        id: 'journey-1',
        userId: 'alice',
        at: started.add(const Duration(minutes: 2)),
      );
      expect(
        repo.appendPoint(id: 'journey-1', userId: 'alice', point: point(3, 0)),
        throwsA(isA<JourneyPointRejected>()),
      );
      await repo.resume(
        id: 'journey-1',
        userId: 'alice',
        at: started.add(const Duration(minutes: 4)),
      );
      expect(
        repo.appendPoint(id: 'journey-1', userId: 'alice', point: point(5, 0)),
        throwsA(isA<JourneyPointRejected>()),
      );
      expect(
        await repo.appendPoint(
          id: 'journey-1',
          userId: 'alice',
          point: point(5, 1),
        ),
        1,
      );
      final recovered = await LocalJourneyRepository(db).activeSession('alice');
      expect(recovered?.recording.phase, JourneyRecordingPhase.recording);
      expect(recovered?.recording.segmentNumber, 1);
      expect((await repo.points('journey-1', 'alice')).length, 2);
    });

    test('keeps a recording private on account change', () async {
      await repo.start(id: 'journey-1', userId: 'alice', at: started);
      expect(await repo.activeSession('bob'), isNull);
      expect(repo.points('journey-1', 'bob'), throwsStateError);
      expect(
        repo.start(id: 'journey-2', userId: 'bob', at: started),
        throwsStateError,
      );
    });

    test('rejects out-of-order points and completes once', () async {
      await repo.start(id: 'journey-1', userId: 'alice', at: started);
      await repo.appendPoint(
        id: 'journey-1',
        userId: 'alice',
        point: point(2, 0),
      );
      expect(
        repo.appendPoint(id: 'journey-1', userId: 'alice', point: point(1, 0)),
        throwsA(isA<JourneyPointRejected>()),
      );
      await repo.finish(
        id: 'journey-1',
        userId: 'alice',
        at: started.add(const Duration(minutes: 3)),
      );
      expect(await repo.activeSession('alice'), isNull);
      expect(
        repo.appendPoint(id: 'journey-1', userId: 'alice', point: point(4, 0)),
        throwsA(isA<JourneyPointRejected>()),
      );
    });

    test(
      'preserves fixes within the same second after reopening state',
      () async {
        final firstFix = started.add(const Duration(milliseconds: 100));
        final secondFix = started.add(const Duration(milliseconds: 450));
        await repo.start(id: 'journey-1', userId: 'alice', at: started);
        for (final at in [firstFix, secondFix]) {
          await repo.appendPoint(
            id: 'journey-1',
            userId: 'alice',
            point: JourneyPoint(
              recordedAt: at,
              latitude: -1.286389,
              longitude: 36.817223,
              accuracyMeters: 8,
              segmentNumber: 0,
            ),
          );
        }
        final recovered = await LocalJourneyRepository(
          db,
        ).points('journey-1', 'alice');
        expect(recovered.map((point) => point.recordedAt), [
          firstFix,
          secondFix,
        ]);
      },
    );

    test('keeps the chosen transport mode across restarts', () async {
      await repo.start(
        id: 'journey-1',
        userId: 'alice',
        at: started,
        mode: JourneyTransportMode.cycle,
      );
      expect(
        await LocalJourneyRepository(db).transportMode('journey-1', 'alice'),
        JourneyTransportMode.cycle,
      );
      expect(
        await repo.transportMode('journey-1', 'bob'),
        isNull,
      );
    });

    test('a Trip with no mode on record skips the speed check', () async {
      await repo.start(id: 'journey-1', userId: 'alice', at: started);
      // ~833 km in one minute - absurd for any mode, but there is none on
      // record, so the existing (older) behaviour is left untouched.
      await repo.appendPoint(
        id: 'journey-1',
        userId: 'alice',
        point: point(0, 0),
      );
      await repo.appendPoint(
        id: 'journey-1',
        userId: 'alice',
        point: JourneyPoint(
          recordedAt: started.add(const Duration(minutes: 1)),
          latitude: -1.286389,
          longitude: 44,
          accuracyMeters: 8,
          segmentNumber: 0,
        ),
      );
      expect((await repo.points('journey-1', 'alice')).length, 2);
    });

    test(
      'rejects a point implying a speed no Walk could actually reach',
      () async {
        await repo.start(
          id: 'journey-1',
          userId: 'alice',
          at: started,
          mode: JourneyTransportMode.walk,
        );
        await repo.appendPoint(
          id: 'journey-1',
          userId: 'alice',
          point: point(0, 0),
        );
        // About 1.1 km in one minute (~18.5 m/s): far beyond a walking
        // pace, so the jump is dropped rather than accepted as a very
        // fast walk.
        expect(
          repo.appendPoint(
            id: 'journey-1',
            userId: 'alice',
            point: JourneyPoint(
              recordedAt: started.add(const Duration(minutes: 1)),
              latitude: -1.286389,
              longitude: 36.827223,
              accuracyMeters: 8,
              segmentNumber: 0,
            ),
          ),
          throwsA(isA<JourneyPointRejected>()),
        );
        expect((await repo.points('journey-1', 'alice')).length, 1);
      },
    );

    test('accepts a plausible Drive point a Walk would have rejected', () async {
      await repo.start(
        id: 'journey-1',
        userId: 'alice',
        at: started,
        mode: JourneyTransportMode.drive,
      );
      await repo.appendPoint(
        id: 'journey-1',
        userId: 'alice',
        point: point(0, 0),
      );
      // The same ~1.1 km-in-a-minute jump as above, but now a plausible
      // driving speed (well under the Drive ceiling), so it is kept.
      expect(
        await repo.appendPoint(
          id: 'journey-1',
          userId: 'alice',
          point: JourneyPoint(
            recordedAt: started.add(const Duration(minutes: 1)),
            latitude: -1.286389,
            longitude: 36.827223,
            accuracyMeters: 8,
            segmentNumber: 0,
          ),
        ),
        1,
      );
    });
  });

  test(
    'an active Journey survives closing and reopening its database',
    () async {
      final directory = await Directory.systemTemp.createTemp('journey-test-');
      final path = '${directory.path}/recordings.sqlite';
      try {
        final first = JourneyDatabase.forTesting(NativeDatabase(File(path)));
        await LocalJourneyRepository(
          first,
        ).start(id: 'journey-1', userId: 'alice', at: started);
        await first.close();

        final reopened = JourneyDatabase.forTesting(NativeDatabase(File(path)));
        try {
          final session = await LocalJourneyRepository(
            reopened,
          ).activeSession('alice');
          expect(session?.id, 'journey-1');
          expect(session?.recording.phase, JourneyRecordingPhase.recording);
        } finally {
          await reopened.close();
        }
      } finally {
        await directory.delete(recursive: true);
      }
    },
  );
}
