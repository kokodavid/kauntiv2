import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/journeys/data/journey_database.dart';
import 'package:kaunti47_v2/src/features/journeys/data/local_journey_repository.dart';
import 'package:kaunti47_v2/src/features/journeys/domain/journey_point.dart';
import 'package:kaunti47_v2/src/features/journeys/domain/journey_recording.dart';

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
        throwsStateError,
      );
      await repo.resume(
        id: 'journey-1',
        userId: 'alice',
        at: started.add(const Duration(minutes: 4)),
      );
      expect(
        repo.appendPoint(id: 'journey-1', userId: 'alice', point: point(5, 0)),
        throwsStateError,
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
        throwsStateError,
      );
      await repo.finish(
        id: 'journey-1',
        userId: 'alice',
        at: started.add(const Duration(minutes: 3)),
      );
      expect(await repo.activeSession('alice'), isNull);
      expect(
        repo.appendPoint(id: 'journey-1', userId: 'alice', point: point(4, 0)),
        throwsStateError,
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
