import 'package:drift/drift.dart';

import '../domain/journey_point.dart';
import '../domain/journey_recording.dart';
import 'journey_database.dart';

class LocalJourneySession {
  const LocalJourneySession({required this.id, required this.recording});

  final String id;
  final JourneyRecording recording;
}

/// Durable, account-scoped recording state. No network or badge state lives here.
class LocalJourneyRepository {
  const LocalJourneyRepository(this._db);

  final JourneyDatabase _db;

  Future<LocalJourneySession?> activeSession(String userId) async {
    final row =
        await (_db.select(_db.journeySessions)
              ..where(
                (t) =>
                    t.userId.equals(userId) &
                    t.phase.isIn(['recording', 'paused']),
              )
              ..limit(1))
            .getSingleOrNull();
    return row == null ? null : _session(row);
  }

  Future<LocalJourneySession> start({
    required String id,
    required String userId,
    required DateTime at,
  }) => _db.transaction(() async {
    if (id.isEmpty || userId.isEmpty) {
      throw ArgumentError('A Journey needs an id and an owner.');
    }
    final active =
        await (_db.select(_db.journeySessions)
              ..where((t) => t.phase.isIn(['recording', 'paused']))
              ..limit(1))
            .getSingleOrNull();
    if (active != null) {
      throw StateError('Finish or recover the active Journey first.');
    }
    final recording = const JourneyRecording.idle().start(at);
    await _db
        .into(_db.journeySessions)
        .insert(
          JourneySessionsCompanion.insert(
            id: id,
            userId: userId,
            phase: recording.phase.name,
            startedAt: at,
            lastChangedAt: at,
            segmentNumber: recording.segmentNumber,
          ),
        );
    return LocalJourneySession(id: id, recording: recording);
  });

  Future<LocalJourneySession> pause({
    required String id,
    required String userId,
    required DateTime at,
  }) => _transition(id, userId, (state) => state.pause(at));

  Future<LocalJourneySession> resume({
    required String id,
    required String userId,
    required DateTime at,
  }) => _transition(id, userId, (state) => state.resume(at));

  Future<LocalJourneySession> finish({
    required String id,
    required String userId,
    required DateTime at,
  }) => _transition(id, userId, (state) => state.finish(at));

  Future<LocalJourneySession> _transition(
    String id,
    String userId,
    JourneyRecording Function(JourneyRecording) apply,
  ) => _db.transaction(() async {
    final current = await _owned(id, userId);
    final next = apply(current.recording);
    await (_db.update(
      _db.journeySessions,
    )..where((t) => t.id.equals(id))).write(
      JourneySessionsCompanion(
        phase: Value(next.phase.name),
        lastChangedAt: Value(next.lastChangedAt!),
        pausedAt: Value(next.pausedAt),
        endedAt: Value(next.endedAt),
        segmentNumber: Value(next.segmentNumber),
      ),
    );
    return LocalJourneySession(id: id, recording: next);
  });

  Future<int> appendPoint({
    required String id,
    required String userId,
    required JourneyPoint point,
  }) => _db.transaction(() async {
    final session = (await _owned(id, userId)).recording;
    if (session.phase != JourneyRecordingPhase.recording ||
        point.segmentNumber != session.segmentNumber ||
        point.recordedAt.isBefore(session.lastChangedAt!)) {
      throw StateError('Point does not belong to the active segment.');
    }
    final previous =
        await (_db.select(_db.journeySamples)
              ..where((t) => t.journeyId.equals(id))
              ..orderBy([(t) => OrderingTerm.desc(t.sequenceNumber)])
              ..limit(1))
            .getSingleOrNull();
    if (previous != null && !point.recordedAt.isAfter(previous.recordedAt)) {
      throw StateError('Journey points must arrive in time order.');
    }
    final sequence = (previous?.sequenceNumber ?? -1) + 1;
    await _db
        .into(_db.journeySamples)
        .insert(
          JourneySamplesCompanion.insert(
            journeyId: id,
            sequenceNumber: sequence,
            segmentNumber: point.segmentNumber,
            recordedAt: point.recordedAt,
            latitude: point.latitude,
            longitude: point.longitude,
            accuracyMeters: point.accuracyMeters,
          ),
        );
    return sequence;
  });

  Future<List<JourneyPoint>> points(String id, String userId) async {
    await _owned(id, userId);
    final rows =
        await (_db.select(_db.journeySamples)
              ..where((t) => t.journeyId.equals(id))
              ..orderBy([(t) => OrderingTerm.asc(t.sequenceNumber)]))
            .get();
    return [
      for (final row in rows)
        JourneyPoint(
          recordedAt: row.recordedAt,
          latitude: row.latitude,
          longitude: row.longitude,
          accuracyMeters: row.accuracyMeters,
          segmentNumber: row.segmentNumber,
        ),
    ];
  }

  Future<LocalJourneySession> _owned(String id, String userId) async {
    final row =
        await (_db.select(_db.journeySessions)
              ..where((t) => t.id.equals(id) & t.userId.equals(userId)))
            .getSingleOrNull();
    if (row == null) throw StateError('Journey not found for this account.');
    return _session(row);
  }

  LocalJourneySession _session(JourneySession row) => LocalJourneySession(
    id: row.id,
    recording: JourneyRecording.restore(
      phase: JourneyRecordingPhase.values.byName(row.phase),
      startedAt: row.startedAt,
      lastChangedAt: row.lastChangedAt,
      pausedAt: row.pausedAt,
      endedAt: row.endedAt,
      segmentNumber: row.segmentNumber,
    ),
  );
}
