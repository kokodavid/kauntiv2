import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path_provider/path_provider.dart';

import '../domain/journey_ids.dart';
import '../domain/journey_media_capture.dart';
import 'journey_database.dart';

/// A pending Trip-media upload, with the retry bookkeeping the queue
/// needs alongside the capture itself.
class PendingJourneyMedia {
  const PendingJourneyMedia({
    required this.capture,
    required this.userId,
    required this.uploadAttempts,
  });

  final JourneyMediaCapture capture;
  final String userId;
  final int uploadAttempts;
}

/// Local storage for Trip-media captures: `journey_media_captures` is raw
/// SQL (see `JourneyDatabase._createMediaCapturesTable`), not a typed
/// Drift table, so every query here goes through `customSelect`/
/// `customInsert`/`customUpdate`/`customDelete` rather than the generated
/// table accessors `LocalJourneyRepository` uses for Drift-managed
/// tables.
class LocalJourneyMediaRepository {
  const LocalJourneyMediaRepository(this._db);

  final JourneyDatabase _db;

  Future<String> persistPickedFile(String journeyId, String pickedPath) async {
    final directory = await getApplicationSupportDirectory();
    final mediaDir = Directory('${directory.path}/journey_media/$journeyId');
    if (!mediaDir.existsSync()) await mediaDir.create(recursive: true);
    final extension = pickedPath.contains('.')
        ? pickedPath.substring(pickedPath.lastIndexOf('.'))
        : '.jpg';
    final destination = '${mediaDir.path}/${JourneyIds.newId()}$extension';
    await File(pickedPath).copy(destination);
    return destination;
  }

  /// Like [persistPickedFile], for a photo that only exists as bytes
  /// (a resized camera-roll photo).
  Future<String> persistPhotoBytes(String journeyId, List<int> bytes) async {
    final directory = await getApplicationSupportDirectory();
    final mediaDir = Directory('${directory.path}/journey_media/$journeyId');
    if (!mediaDir.existsSync()) await mediaDir.create(recursive: true);
    final destination = '${mediaDir.path}/${JourneyIds.newId()}.jpg';
    await File(destination).writeAsBytes(bytes, flush: true);
    return destination;
  }

  Future<void> deleteLocalFiles(Iterable<String> paths) async {
    for (final path in paths) {
      try {
        final file = File(path);
        if (file.existsSync()) await file.delete();
      } on Object {
        // Local cleanup is best effort after its database row is removed.
      }
    }
  }

  static const _columns =
      'id, journey_id, user_id, local_path, captured_at_millis, '
      'latitude, longitude, upload_attempts, next_upload_at_millis';

  Future<JourneyMediaCapture> add({
    required String journeyId,
    required String userId,
    required String localPath,
    required DateTime capturedAt,
    double? latitude,
    double? longitude,
  }) async {
    final id = JourneyIds.newId();
    await _db.customInsert(
      'INSERT INTO journey_media_captures (id, journey_id, user_id, '
      'local_path, captured_at_millis, latitude, longitude) '
      'VALUES (?, ?, ?, ?, ?, ?, ?)',
      variables: [
        Variable.withString(id),
        Variable.withString(journeyId),
        Variable.withString(userId),
        Variable.withString(localPath),
        Variable.withInt(capturedAt.millisecondsSinceEpoch),
        Variable<double>(latitude),
        Variable<double>(longitude),
      ],
    );
    return JourneyMediaCapture(
      id: id,
      journeyId: journeyId,
      localPath: localPath,
      capturedAt: capturedAt,
      latitude: latitude,
      longitude: longitude,
    );
  }

  /// Captures for one Trip, oldest first - for showing a thumbnail strip
  /// while still recording or waiting to upload.
  Future<List<JourneyMediaCapture>> forJourney(String journeyId) async {
    final rows = await _db
        .customSelect(
          'SELECT $_columns FROM journey_media_captures '
          'WHERE journey_id = ? ORDER BY captured_at_millis ASC',
          variables: [Variable.withString(journeyId)],
        )
        .get();
    return [for (final row in rows) _capture(row.data)];
  }

  /// Captures for [userId] due for upload at [now]: never attempted, or
  /// their backoff has elapsed. Oldest first, like the points queue.
  Future<List<PendingJourneyMedia>> due(String userId, DateTime now) async {
    final rows = await _db
        .customSelect(
          'SELECT $_columns FROM journey_media_captures WHERE user_id = ? '
          'AND (next_upload_at_millis IS NULL OR next_upload_at_millis <= ?) '
          'ORDER BY captured_at_millis ASC',
          variables: [
            Variable.withString(userId),
            Variable.withInt(now.millisecondsSinceEpoch),
          ],
        )
        .get();
    return [
      for (final row in rows)
        PendingJourneyMedia(
          capture: _capture(row.data),
          userId: row.data['user_id'] as String,
          uploadAttempts: row.data['upload_attempts'] as int,
        ),
    ];
  }

  /// Whether a Trip's points are still only on this phone (a
  /// `journey_sessions` row for it exists). Media for a Trip waits for
  /// this to turn false - the server's `journey_media.journey_id`
  /// references `journeys`, so uploading a photo before the Trip itself
  /// would just fail on the foreign key.
  Future<bool> journeyStillLocal(String journeyId) async {
    final rows = await _db
        .customSelect(
          'SELECT 1 FROM journey_sessions WHERE id = ? LIMIT 1',
          variables: [Variable.withString(journeyId)],
          readsFrom: {_db.journeySessions},
        )
        .get();
    return rows.isNotEmpty;
  }

  Future<void> recordAttempt(
    String id, {
    required int attempts,
    required DateTime nextUploadAt,
  }) => _db.customUpdate(
    'UPDATE journey_media_captures SET upload_attempts = ?, '
    'next_upload_at_millis = ? WHERE id = ?',
    variables: [
      Variable.withInt(attempts),
      Variable.withInt(nextUploadAt.millisecondsSinceEpoch),
      Variable.withString(id),
    ],
  );

  /// Drops the local row once it's safely uploaded (the caller deletes
  /// the local file itself).
  Future<void> remove(String id) => _db.customStatement(
    'DELETE FROM journey_media_captures WHERE id = ?',
    [id],
  );

  /// Drops every capture for a Trip, e.g. when it's discarded unsaved.
  Future<List<String>> removeForJourney(String journeyId) async {
    final paths = await forJourney(journeyId);
    await _db.customStatement(
      'DELETE FROM journey_media_captures WHERE journey_id = ?',
      [journeyId],
    );
    return [for (final p in paths) p.localPath];
  }

  JourneyMediaCapture _capture(Map<String, Object?> row) => JourneyMediaCapture(
    id: row['id'] as String,
    journeyId: row['journey_id'] as String,
    localPath: row['local_path'] as String,
    capturedAt: DateTime.fromMillisecondsSinceEpoch(
      row['captured_at_millis'] as int,
      isUtc: true,
    ),
    latitude: (row['latitude'] as num?)?.toDouble(),
    longitude: (row['longitude'] as num?)?.toDouble(),
  );
}
