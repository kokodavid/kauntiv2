import 'package:drift/drift.dart';

import '../domain/journey_destination.dart';
import '../domain/journey_point.dart';
import '../domain/journey_recording.dart';
import 'journey_database.dart';

part 'local_journey_repository_mappers.dart';

class LocalJourneySession {
  const LocalJourneySession({required this.id, required this.recording});

  final String id;
  final JourneyRecording recording;
}

class JourneyPointRejected implements Exception {
  const JourneyPointRejected();
}

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
    JourneyDestination? destination,
  }) => _db.transaction(() async {
    if (id.isEmpty || userId.isEmpty) {
      throw ArgumentError('A Journey needs an id and an owner.');
    }
    if (destination != null && !destination.isValid) {
      throw ArgumentError('Journey destination is not valid.');
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
            startedAtMillis: at.millisecondsSinceEpoch,
            lastChangedAtMillis: at.millisecondsSinceEpoch,
            segmentNumber: recording.segmentNumber,
          ),
        );
    if (destination != null) {
      await _db.customUpdate(
        'UPDATE journey_sessions SET destination_place_id = ?, '
        'destination_name = ?, destination_latitude = ?, '
        'destination_longitude = ? WHERE id = ? AND user_id = ?',
        variables: [
          Variable.withString(destination.placeId),
          Variable.withString(destination.name),
          Variable<double>(destination.latitude),
          Variable<double>(destination.longitude),
          Variable.withString(id),
          Variable.withString(userId),
        ],
        updates: {_db.journeySessions},
      );
    }
    return LocalJourneySession(id: id, recording: recording);
  });

  Future<JourneyDestination?> destination(String id, String userId) async {
    final rows = await _db
        .customSelect(
          'SELECT destination_place_id, destination_name, '
          'destination_latitude, destination_longitude FROM journey_sessions '
          'WHERE id = ? AND user_id = ?',
          variables: [Variable.withString(id), Variable.withString(userId)],
          readsFrom: {_db.journeySessions},
        )
        .get();
    if (rows.isEmpty) return null;
    final row = rows.single.data;
    final placeId = row['destination_place_id'] as String?;
    final name = row['destination_name'] as String?;
    if (placeId == null || name == null) return null;
    return JourneyDestination(
      placeId: placeId,
      name: name,
      latitude: (row['destination_latitude'] as num?)?.toDouble(),
      longitude: (row['destination_longitude'] as num?)?.toDouble(),
    );
  }

  /// The name the user gave this Trip, overriding the default "Trip on
  /// ..."/"Trip to ..." title; null until it's renamed.
  Future<String?> customTitle(String id, String userId) async {
    final rows = await _db
        .customSelect(
          'SELECT title FROM journey_sessions WHERE id = ? AND user_id = ?',
          variables: [Variable.withString(id), Variable.withString(userId)],
          readsFrom: {_db.journeySessions},
        )
        .get();
    if (rows.isEmpty) return null;
    return rows.single.data['title'] as String?;
  }

  /// Sets this Trip's name, overriding its default title.
  Future<void> rename({
    required String id,
    required String userId,
    required String title,
  }) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty || trimmed.length > 120) {
      throw ArgumentError('A Trip name needs 1-120 characters.');
    }
    await _owned(id, userId);
    await _db.customUpdate(
      'UPDATE journey_sessions SET title = ? WHERE id = ? AND user_id = ?',
      variables: [
        Variable.withString(trimmed),
        Variable.withString(id),
        Variable.withString(userId),
      ],
      updates: {_db.journeySessions},
    );
  }

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

  Future<LocalJourneySession> splitSegment({
    required String id,
    required String userId,
    required DateTime at,
  }) => _transition(id, userId, (state) => state.splitAt(at));

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
        lastChangedAtMillis: Value(next.lastChangedAt!.millisecondsSinceEpoch),
        pausedAtMillis: Value(next.pausedAt?.millisecondsSinceEpoch),
        endedAtMillis: Value(next.endedAt?.millisecondsSinceEpoch),
        segmentNumber: Value(next.segmentNumber),
        pausedTotalMillis: Value(next.pausedTotal.inMilliseconds),
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
      throw const JourneyPointRejected();
    }
    final previous =
        await (_db.select(_db.journeySamples)
              ..where((t) => t.journeyId.equals(id))
              ..orderBy([(t) => OrderingTerm.desc(t.sequenceNumber)])
              ..limit(1))
            .getSingleOrNull();
    if (previous != null &&
        point.recordedAt.millisecondsSinceEpoch <= previous.recordedAtMillis) {
      throw const JourneyPointRejected();
    }
    final sequence = (previous?.sequenceNumber ?? -1) + 1;
    await _db
        .into(_db.journeySamples)
        .insert(
          JourneySamplesCompanion.insert(
            journeyId: id,
            sequenceNumber: sequence,
            segmentNumber: point.segmentNumber,
            recordedAtMillis: point.recordedAt.millisecondsSinceEpoch,
            latitude: point.latitude,
            longitude: point.longitude,
            accuracyMeters: point.accuracyMeters,
          ),
        );
    if (point.altitudeMeters != null || point.speedMetersPerSecond != null) {
      await _db.customUpdate(
        'UPDATE journey_samples SET altitude_meters = ?, speed_mps = ? '
        'WHERE journey_id = ? AND sequence_number = ?',
        variables: [
          Variable<double>(point.altitudeMeters),
          Variable<double>(point.speedMetersPerSecond),
          Variable.withString(id),
          Variable.withInt(sequence),
        ],
        updates: {_db.journeySamples},
      );
    }
    return sequence;
  });

  Future<List<JourneyPoint>> points(String id, String userId) async {
    await _owned(id, userId);
    final rows = await _db
        .customSelect(
          'SELECT segment_number, recorded_at_millis, latitude, longitude, '
          'accuracy_meters, altitude_meters, speed_mps FROM journey_samples '
          'WHERE journey_id = ? ORDER BY sequence_number ASC',
          variables: [Variable.withString(id)],
          readsFrom: {_db.journeySamples},
        )
        .get();
    return [for (final row in rows) _pointFromRow(row.data)];
  }

  Future<DateTime?> lastPointAt(String id, String userId) async {
    await _owned(id, userId);
    final row =
        await (_db.select(_db.journeySamples)
              ..where((t) => t.journeyId.equals(id))
              ..orderBy([(t) => OrderingTerm.desc(t.sequenceNumber)])
              ..limit(1))
            .getSingleOrNull();
    return row == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(
            row.recordedAtMillis,
            isUtc: true,
          );
  }

  Future<void> discard(String id, String userId) => _db.transaction(() async {
    await _owned(id, userId);
    await (_db.delete(
      _db.journeySamples,
    )..where((t) => t.journeyId.equals(id))).go();
    await (_db.delete(_db.journeySessions)..where((t) => t.id.equals(id))).go();
  });

  Stream<List<JourneyPoint>> watchPoints(String id) {
    final query = _db.customSelect(
      'SELECT segment_number, recorded_at_millis, latitude, longitude, '
      'accuracy_meters, altitude_meters, speed_mps FROM journey_samples '
      'WHERE journey_id = ? ORDER BY sequence_number ASC',
      variables: [Variable.withString(id)],
      readsFrom: {_db.journeySamples},
    );
    return query.watch().map(
      (rows) => [for (final row in rows) _pointFromRow(row.data)],
    );
  }
}
