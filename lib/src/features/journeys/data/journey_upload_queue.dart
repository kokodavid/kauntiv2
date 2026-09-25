import 'dart:async';
import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/app_logger.dart';
import '../domain/journey_point.dart';
import '../domain/journey_summary.dart';
import 'journey_database.dart';
import 'local_journey_repository.dart';
import 'supabase_journey_repository.dart';

/// Uploads one completed Journey; resolves once the server has stored it.
typedef UploadJourney =
    Future<void> Function({
      required String id,
      required String title,
      required DateTime startedAt,
      required DateTime endedAt,
      required List<JourneyPoint> points,
    });

/// Uploads completed local Journeys for the signed-in account, oldest
/// first, then deletes the local copy so precise points don't linger on
/// the phone once they're in the private cloud history.
///
/// Like detection's visit queue: a transient failure (offline, timeout)
/// backs off exponentially and stops the drain; a permanent rejection
/// (no Pro when it started, invalid timing or points) waits a day and the
/// drain moves on. The local copy is kept in both cases. The drain stops
/// if the signed-in user changes.
class JourneyUploadQueue {
  JourneyUploadQueue(
    this._db, {
    required String? Function() currentUserId,
    required UploadJourney upload,
  }) : _currentUserId = currentUserId,
       _upload = upload,
       _local = LocalJourneyRepository(_db);

  factory JourneyUploadQueue.supabase(
    JourneyDatabase db,
    SupabaseJourneyRepository cloud,
  ) => JourneyUploadQueue(
    db,
    currentUserId: () => cloud.currentUserId,
    upload:
        ({
          required id,
          required title,
          required startedAt,
          required endedAt,
          required points,
        }) => cloud.upload(
          id: id,
          title: title,
          startedAt: startedAt,
          endedAt: endedAt,
          points: points,
        ),
  );

  final JourneyDatabase _db;
  final LocalJourneyRepository _local;
  final String? Function() _currentUserId;
  final UploadJourney _upload;

  static const _logger = AppLogger.journeys();

  /// Postgres codes that won't succeed on retry: permission (no Pro, wrong
  /// owner), invalid value / check / cast.
  static const _permanentCodes = {'42501', '22023', '23514', '22007', '22P02'};

  Future<int>? _running;

  /// Completed Journeys still on this phone for [userId], newest first.
  Future<List<JourneySummary>> pending(String userId) async {
    final rows =
        await (_db.select(_db.journeySessions)
              ..where(
                (t) => t.userId.equals(userId) & t.phase.equals('completed'),
              )
              ..orderBy([(t) => OrderingTerm.desc(t.startedAtMillis)]))
            .get();
    return [for (final row in rows) _summary(row)];
  }

  /// Uploads what's due; returns how many Journeys uploaded. Concurrent
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
    final due =
        await (_db.select(_db.journeySessions)
              ..where(
                (t) =>
                    t.userId.equals(userId) &
                    t.phase.equals('completed') &
                    (t.nextUploadAtMillis.isNull() |
                        t.nextUploadAtMillis.isSmallerOrEqualValue(
                          now.millisecondsSinceEpoch,
                        )),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.startedAtMillis)]))
            .get();

    var uploaded = 0;
    for (final row in due) {
      if (_currentUserId() != userId) break;
      final summary = _summary(row);
      try {
        await _upload(
          id: row.id,
          title: summary.title,
          startedAt: summary.startedAt,
          endedAt: summary.endedAt,
          points: await _local.points(row.id, userId),
        );
        await _removeLocal(row.id);
        uploaded++;
      } on Object catch (error, stackTrace) {
        _logger.warning(
          'Journey upload deferred.',
          error: error,
          stackTrace: stackTrace,
        );
        final permanent =
            error is PostgrestException && _permanentCodes.contains(error.code);
        await (_db.update(
          _db.journeySessions,
        )..where((t) => t.id.equals(row.id))).write(
          JourneySessionsCompanion(
            uploadAttempts: Value(row.uploadAttempts + 1),
            nextUploadAtMillis: Value(
              now
                  .add(retryDelay(row.uploadAttempts, permanent))
                  .millisecondsSinceEpoch,
            ),
          ),
        );
        if (!permanent) break;
      }
    }
    return uploaded;
  }

  /// Deletes a Journey that never uploaded (the user's choice).
  Future<void> deleteLocal(String id, String userId) async {
    final owned =
        await (_db.select(_db.journeySessions)
              ..where((t) => t.id.equals(id) & t.userId.equals(userId)))
            .getSingleOrNull();
    if (owned == null) return;
    await _removeLocal(id);
  }

  Future<void> _removeLocal(String id) => _db.transaction(() async {
    await (_db.delete(
      _db.journeySamples,
    )..where((t) => t.journeyId.equals(id))).go();
    await (_db.delete(_db.journeySessions)..where((t) => t.id.equals(id))).go();
  });

  JourneySummary _summary(JourneySession row) {
    final startedAt = DateTime.fromMillisecondsSinceEpoch(
      row.startedAtMillis,
      isUtc: true,
    );
    return JourneySummary(
      id: row.id,
      title: JourneyTitles.defaultFor(startedAt),
      startedAt: startedAt,
      endedAt: DateTime.fromMillisecondsSinceEpoch(
        row.endedAtMillis ?? row.lastChangedAtMillis,
        isUtc: true,
      ),
      isUploaded: false,
    );
  }

  /// 15 s, 30 s, 1 min … capped at 15 min; a day for a permanent rejection.
  static Duration retryDelay(int attempts, bool permanent) => permanent
      ? const Duration(days: 1)
      : Duration(seconds: math.min(900, 15 * (1 << math.min(attempts, 6))));
}
