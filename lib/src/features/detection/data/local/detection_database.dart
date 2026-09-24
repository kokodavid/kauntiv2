import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'detection_database.g.dart';

/// A county currently being "watched" for dwell-threshold resolution --
/// doc 01's transient CANDIDATE state, made durable. A 2-hour dwell
/// timer (`VisitTimings.dwellThreshold`) has to survive the OS
/// killing the app's process while the user is still inside the county,
/// which an in-memory-only candidate could not.
class Candidates extends Table {
  /// One active candidate per county at a time.
  IntColumn get countyCode => integer()();
  DateTimeColumn get enteredAt => dateTime()();

  @override
  Set<Column> get primaryKey => {countyCode};
}

/// A resolved visit (EXPLORED or PASSED_THROUGH) waiting to reach
/// Supabase's `county_visits` table. Doc 01: "A detected entry is written
/// to a local queue and the badge is shown immediately as PENDING. On
/// reconnect the queue syncs and the badge confirms." -- a row here is
/// exactly that queued entry; `data/visit_sync_queue.dart` drains it.
class PendingSyncOps extends Table {
  /// `autoIncrement()` already makes this column drift's primary key --
  /// don't also override `primaryKey` below (drift_dev warns: "Tables
  /// can't override primaryKey and use autoIncrement()").
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userId => text().nullable()();
  DateTimeColumn get nextAttemptAt => dateTime().nullable()();
  IntColumn get countyCode => integer()();

  /// 'explored' or 'passed_through' -- stored as text (not an enum column)
  /// so it lines up directly with Supabase's own `county_visits.state`
  /// check constraint values.
  TextColumn get outcome => text()();
  DateTimeColumn get enteredAt => dateTime()();
  DateTimeColumn get resolvedAt => dateTime()();
  DateTimeColumn get queuedAt => dateTime().withDefault(currentDateAndTime)();

  /// How many sync attempts have failed so far -- lets the sync loop back
  /// off or surface a persistently-failing op rather than retrying a
  /// broken write forever with no visibility.
  IntColumn get attempts => integer().withDefault(const Constant(0))();
}

/// A single-row table holding the county code [GeofenceService]'s rolling
/// window should currently be centered on -- i.e. the last county
/// [DetectionRepository] saw the user actually enter, whether or not that
/// visit has resolved yet.
///
/// This exists so app startup/resume knows what geofence window to
/// (re-)register without depending on Supabase (offline-safe, matches
/// this whole feature's local-first design) or on [PendingSyncOps] (which
/// is emptied by a successful sync, so it can't be used as "last known
/// county" once a visit has synced and its queue row is gone). Written
/// from the same local-only code path `geofence_service.dart`'s
/// background callback already uses, so recording it there costs nothing
/// extra in isolate-safety terms.
class CurrentCounty extends Table {
  /// Always 0 -- this table only ever holds one row.
  IntColumn get id => integer()();
  IntColumn get countyCode => integer()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Account currently owning active candidates and the geofence window. The
/// background isolate reads this identity without initializing authentication.
class DetectionOwner extends Table {
  IntColumn get id => integer()();
  TextColumn get userId => text()();
  @override
  Set<Column> get primaryKey => {id};
}

// Ported unchanged from v1 (same file name `detection_queue`, same tables,
// schema 2) so a phone upgrading from a v1 build keeps its active dwell
// timers and any visits it hasn't synced yet. Change it only with a
// migration step.
@DriftDatabase(
  tables: [Candidates, PendingSyncOps, CurrentCounty, DetectionOwner],
)
class DetectionDatabase extends _$DetectionDatabase {
  DetectionDatabase() : super(driftDatabase(name: 'detection_queue'));

  DetectionDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(pendingSyncOps, pendingSyncOps.userId);
        await m.addColumn(pendingSyncOps, pendingSyncOps.nextAttemptAt);
        await m.createTable(detectionOwner);
      }
    },
  );
}
