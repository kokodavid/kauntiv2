import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import '../../../services/app_logger.dart';
import 'local_journey_media_repository.dart';
import 'journey_database.dart';
import 'supabase_journey_repository.dart';

/// Uploads one captured Trip photo; resolves once it's stored in the
/// private `journey-media` bucket and recorded in `journey_media`.
typedef UploadJourneyMedia =
    Future<void> Function({
      required String userId,
      required String journeyId,
      required String id,
      required String localPath,
      required DateTime capturedAt,
      double? latitude,
      double? longitude,
    });

/// Uploads Trip photos captured on this phone, oldest first, then
/// deletes the local copy (database row and file) once the server has
/// it - the same shape as `JourneyUploadQueue` for a Trip's points, with
/// one extra rule: a photo waits for its own Trip's points to finish
/// uploading first (`journey_media.journey_id` references `journeys`, so
/// the server would just reject it otherwise), checked by whether a
/// local `journey_sessions` row for that Trip still exists.
///
/// No permanent-vs-transient split like the points queue: there's no
/// quota or validation rule a photo can permanently fail, so any error
/// just backs off and is retried later.
class JourneyMediaUploadQueue {
  JourneyMediaUploadQueue(
    this._db, {
    required String? Function() currentUserId,
    required UploadJourneyMedia upload,
  }) : _currentUserId = currentUserId,
       _upload = upload,
       _local = LocalJourneyMediaRepository(_db);

  factory JourneyMediaUploadQueue.supabase(
    JourneyDatabase db,
    SupabaseJourneyRepository cloud,
  ) => JourneyMediaUploadQueue(
    db,
    currentUserId: () => cloud.currentUserId,
    upload:
        ({
          required userId,
          required journeyId,
          required id,
          required localPath,
          required capturedAt,
          latitude,
          longitude,
        }) => cloud.uploadMedia(
          userId: userId,
          journeyId: journeyId,
          id: id,
          localPath: localPath,
          capturedAt: capturedAt,
          latitude: latitude,
          longitude: longitude,
        ),
  );

  final JourneyDatabase _db;
  final LocalJourneyMediaRepository _local;
  final String? Function() _currentUserId;
  final UploadJourneyMedia _upload;

  static const _logger = AppLogger.journeys();

  Future<int>? _running;

  /// Uploads what's due; returns how many photos uploaded. Concurrent
  /// calls share one drain.
  Future<int> drain({DateTime? now}) {
    final running = _running;
    if (running != null) return running;
    final future = _drain(now ?? DateTime.now());
    _running = future;
    return future.whenComplete(() => _running = null);
  }

  Future<int> _drain(DateTime now) async {
    final userId = _currentUserId();
    if (userId == null) return 0;
    final due = await _local.due(userId, now);

    var uploaded = 0;
    for (final pending in due) {
      if (_currentUserId() != userId) break;
      final capture = pending.capture;
      // The parent Trip hasn't synced yet: wait for it, don't burn a
      // retry attempt on a foreign-key failure that will happen anyway.
      if (await _local.journeyStillLocal(capture.journeyId)) continue;
      try {
        await _upload(
          userId: userId,
          journeyId: capture.journeyId,
          id: capture.id,
          localPath: capture.localPath,
          capturedAt: capture.capturedAt,
          latitude: capture.latitude,
          longitude: capture.longitude,
        );
        if (_currentUserId() != userId) break;
        await _local.remove(capture.id);
        unawaited(_deleteFileQuietly(capture.localPath));
        uploaded++;
      } on Object catch (error, stackTrace) {
        if (_currentUserId() != userId) break;
        _logger.warning(
          'Trip media upload deferred.',
          error: error,
          stackTrace: stackTrace,
        );
        await _local.recordAttempt(
          capture.id,
          attempts: pending.uploadAttempts + 1,
          nextUploadAt: now.add(retryDelay(pending.uploadAttempts)),
        );
      }
    }
    return uploaded;
  }

  Future<void> _deleteFileQuietly(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } on Object catch (error, stackTrace) {
      _logger.warning(
        'Could not remove an uploaded Trip photo from local storage.',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// 15 s, 30 s, 1 min … capped at 15 min, like the points queue's
  /// transient backoff.
  static Duration retryDelay(int attempts) =>
      Duration(seconds: math.min(900, 15 * (1 << math.min(attempts, 6))));
}
