import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'journey_database.g.dart';

class JourneySessions extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get phase => text()();
  IntColumn get startedAtMillis => integer()();
  IntColumn get lastChangedAtMillis => integer()();
  IntColumn get pausedAtMillis => integer().nullable()();
  IntColumn get endedAtMillis => integer().nullable()();
  IntColumn get segmentNumber => integer()();

  /// Upload bookkeeping for completed sessions (schema 2).
  IntColumn get uploadAttempts => integer().withDefault(const Constant(0))();
  IntColumn get nextUploadAtMillis => integer().nullable()();

  /// Time spent paused so far, for the recorded-time clock (schema 3).
  IntColumn get pausedTotalMillis => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class JourneySamples extends Table {
  TextColumn get journeyId => text()();
  IntColumn get sequenceNumber => integer()();
  IntColumn get segmentNumber => integer()();
  IntColumn get recordedAtMillis => integer()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  RealColumn get accuracyMeters => real()();

  @override
  Set<Column> get primaryKey => {journeyId, sequenceNumber};
}

@DriftDatabase(tables: [JourneySessions, JourneySamples])
class JourneyDatabase extends _$JourneyDatabase {
  JourneyDatabase() : super(driftDatabase(name: 'journey_recordings'));

  JourneyDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _addDestinationColumns();
      await _addTitleColumn();
      await _addSpeedElevationColumns();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(journeySessions, journeySessions.uploadAttempts);
        await m.addColumn(journeySessions, journeySessions.nextUploadAtMillis);
      }
      if (from < 3) {
        await m.addColumn(journeySessions, journeySessions.pausedTotalMillis);
      }
      if (from < 4) await _addDestinationColumns();
      if (from < 5) await _addTitleColumn();
      if (from < 6) await _addSpeedElevationColumns();
    },
  );

  // Keep this optional metadata out of Drift's generated row mapping until
  // code generation is next run; older recordings have NULL in all columns.
  Future<void> _addDestinationColumns() async {
    await customStatement(
      'ALTER TABLE journey_sessions ADD COLUMN destination_place_id TEXT',
    );
    await customStatement(
      'ALTER TABLE journey_sessions ADD COLUMN destination_name TEXT',
    );
    await customStatement(
      'ALTER TABLE journey_sessions ADD COLUMN destination_latitude REAL',
    );
    await customStatement(
      'ALTER TABLE journey_sessions ADD COLUMN destination_longitude REAL',
    );
  }

  /// A user-set name overriding the default "Trip on ..."/"Trip to ..."
  /// title (schema 5); NULL until the user renames it.
  Future<void> _addTitleColumn() async {
    await customStatement('ALTER TABLE journey_sessions ADD COLUMN title TEXT');
  }

  /// A fix's height above sea level and instantaneous speed, when the
  /// device reported them (schema 6); NULL for older recordings.
  Future<void> _addSpeedElevationColumns() async {
    await customStatement(
      'ALTER TABLE journey_samples ADD COLUMN altitude_meters REAL',
    );
    await customStatement(
      'ALTER TABLE journey_samples ADD COLUMN speed_mps REAL',
    );
  }
}
