part of 'local_journey_repository.dart';

extension LocalJourneyRepositoryReads on LocalJourneyRepository {
  Future<List<JourneyPoint>> points(String id, String userId) async {
    await _owned(_db, id, userId);
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
    await _owned(_db, id, userId);
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

  /// The latest fix for tagging a photo without loading the full route.
  Future<JourneyPoint?> lastPoint(String id, String userId) async {
    await _owned(_db, id, userId);
    final rows = await _db
        .customSelect(
          'SELECT segment_number, recorded_at_millis, latitude, longitude, '
          'accuracy_meters, altitude_meters, speed_mps FROM journey_samples '
          'WHERE journey_id = ? ORDER BY sequence_number DESC LIMIT 1',
          variables: [Variable.withString(id)],
          readsFrom: {_db.journeySamples},
        )
        .get();
    return rows.isEmpty ? null : _pointFromRow(rows.single.data);
  }

  Future<void> discard(String id, String userId) => _db.transaction(() async {
    await _owned(_db, id, userId);
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
