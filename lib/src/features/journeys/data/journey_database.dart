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
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(journeySessions, journeySessions.uploadAttempts);
        await m.addColumn(journeySessions, journeySessions.nextUploadAtMillis);
      }
      if (from < 3) {
        await m.addColumn(journeySessions, journeySessions.pausedTotalMillis);
      }
    },
  );
}
