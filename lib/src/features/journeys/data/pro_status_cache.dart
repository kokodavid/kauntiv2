import 'package:drift/drift.dart';

import '../domain/pro_status.dart';
import 'journey_database.dart';

/// The last server-confirmed Pro status per account, for offline starts.
class ProStatusCache {
  const ProStatusCache(this._db);

  final JourneyDatabase _db;

  Future<ProStatus?> read(String userId) async {
    final row = await (_db.select(
      _db.proStatusCaches,
    )..where((t) => t.userId.equals(userId))).getSingleOrNull();
    if (row == null) return null;
    return ProStatus(
      active: row.active,
      activeUntil: row.activeUntilMillis == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
              row.activeUntilMillis!,
              isUtc: true,
            ),
      checkedAt: DateTime.fromMillisecondsSinceEpoch(
        row.checkedAtMillis,
        isUtc: true,
      ),
    );
  }

  Future<void> write(String userId, ProStatus status) => _db
      .into(_db.proStatusCaches)
      .insertOnConflictUpdate(
        ProStatusCachesCompanion.insert(
          userId: userId,
          active: status.active,
          activeUntilMillis: Value(status.activeUntil?.millisecondsSinceEpoch),
          checkedAtMillis: status.checkedAt.millisecondsSinceEpoch,
        ),
      );
}
