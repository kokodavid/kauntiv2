part of 'local_journey_repository.dart';

extension _LocalJourneyRepositoryLookup on LocalJourneyRepository {
  Future<LocalJourneySession> _owned(String id, String userId) async {
    final row =
        await (_db.select(_db.journeySessions)
              ..where((t) => t.id.equals(id) & t.userId.equals(userId)))
            .getSingleOrNull();
    if (row == null) throw StateError('Journey not found for this account.');
    return _session(row);
  }
}

JourneyPoint _pointFromRow(Map<String, Object?> row) => JourneyPoint(
  recordedAt: DateTime.fromMillisecondsSinceEpoch(
    row['recorded_at_millis'] as int,
    isUtc: true,
  ),
  latitude: row['latitude'] as double,
  longitude: row['longitude'] as double,
  accuracyMeters: row['accuracy_meters'] as double,
  segmentNumber: row['segment_number'] as int,
  altitudeMeters: (row['altitude_meters'] as num?)?.toDouble(),
  speedMetersPerSecond: (row['speed_mps'] as num?)?.toDouble(),
);

LocalJourneySession _session(JourneySession row) => LocalJourneySession(
  id: row.id,
  recording: JourneyRecording.restore(
    phase: JourneyRecordingPhase.values.byName(row.phase),
    startedAt: DateTime.fromMillisecondsSinceEpoch(
      row.startedAtMillis,
      isUtc: true,
    ),
    lastChangedAt: DateTime.fromMillisecondsSinceEpoch(
      row.lastChangedAtMillis,
      isUtc: true,
    ),
    pausedAt: row.pausedAtMillis == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(row.pausedAtMillis!, isUtc: true),
    endedAt: row.endedAtMillis == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(row.endedAtMillis!, isUtc: true),
    segmentNumber: row.segmentNumber,
    pausedTotal: Duration(milliseconds: row.pausedTotalMillis),
  ),
);
