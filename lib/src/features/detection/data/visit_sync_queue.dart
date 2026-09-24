import 'dart:async';
import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/app_logger.dart';
import 'local/detection_database.dart';

/// Uploads one queued visit; resolves to the server's confirmation.
typedef UploadVisit = Future<Object?> Function(String owner, PendingSyncOp op);

/// Drains the on-device visit queue to `sync_county_visit` (ported from
/// v1). Only the county, outcome and entry time are sent, never a
/// location (doc 05). The RPC is idempotent, so a retry after a lost
/// response can't double-count a visit.
///
/// Oldest first. A transient failure (offline, timeout) backs off
/// exponentially (15 s doubling, capped at 15 min) and stops the drain; a
/// permanent rejection (permission, bad county or outcome) waits a day and
/// the drain moves on. The drain stops if the signed-in user changes.
class VisitSyncQueue {
  VisitSyncQueue(
    this._db, {
    required String? Function() currentUserId,
    required UploadVisit upload,
  }) : _currentUserId = currentUserId,
       _upload = upload;

  /// Uploads through [client] as its signed-in user.
  factory VisitSyncQueue.supabase(
    DetectionDatabase db,
    SupabaseClient client,
  ) => VisitSyncQueue(
    db,
    currentUserId: () => client.auth.currentUser?.id,
    upload: (owner, op) => client.rpc<Object?>(
      'sync_county_visit',
      params: {
        'p_user_id': owner,
        'p_county_id': op.countyCode,
        'p_outcome': op.outcome,
        'p_entered_at': op.enteredAt.toUtc().toIso8601String(),
      },
    ),
  );

  final DetectionDatabase _db;
  final String? Function() _currentUserId;
  final UploadVisit _upload;

  static const _logger = AppLogger.detection();
  static const _timeout = Duration(seconds: 8);

  /// Postgres codes that won't succeed on retry.
  static const _permanentCodes = {'42501', '23503', '23514', '22023'};

  Future<int>? _running;

  /// Uploads what's due; returns how many visits synced. Concurrent calls
  /// share one drain.
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
    final ops =
        await (_db.select(_db.pendingSyncOps)
              ..where(
                (o) =>
                    o.userId.equals(userId) &
                    (o.nextAttemptAt.isNull() |
                        o.nextAttemptAt.isSmallerOrEqualValue(now)),
              )
              ..orderBy([(o) => OrderingTerm.asc(o.queuedAt)]))
            .get();

    var synced = 0;
    for (final op in ops) {
      if (_currentUserId() != userId) break;
      try {
        final confirmed = await _upload(userId, op).timeout(_timeout);
        if (confirmed is! List) {
          throw const FormatException('Invalid visit confirmation');
        }
        await (_db.delete(
          _db.pendingSyncOps,
        )..where((o) => o.id.equals(op.id))).go();
        synced++;
      } on Object catch (error, stackTrace) {
        _logger.warning(
          'Visit sync deferred for county ${op.countyCode}.',
          error: error,
          stackTrace: stackTrace,
        );
        final permanent =
            error is PostgrestException && _permanentCodes.contains(error.code);
        await (_db.update(
          _db.pendingSyncOps,
        )..where((o) => o.id.equals(op.id))).write(
          PendingSyncOpsCompanion(
            attempts: Value(op.attempts + 1),
            nextAttemptAt: Value(now.add(retryDelay(op.attempts, permanent))),
          ),
        );
        if (!permanent) break;
      }
    }
    return synced;
  }

  /// 15 s, 30 s, 1 min … capped at 15 min; a day for a permanent rejection.
  static Duration retryDelay(int attempts, bool permanent) => permanent
      ? const Duration(days: 1)
      : Duration(seconds: math.min(900, 15 * (1 << math.min(attempts, 6))));
}
