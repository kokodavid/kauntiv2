import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/detection/data/detection_repository.dart';
import 'package:kaunti47_v2/src/features/detection/data/local/detection_database.dart';
import 'package:kaunti47_v2/src/features/detection/domain/visit_models.dart';

DetectionDatabase _memoryDb() =>
    DetectionDatabase.forTesting(NativeDatabase.memory());

CountyCrossingEvent _event(int county, CrossingKind kind, DateTime at) =>
    CountyCrossingEvent(countyCode: county, kind: kind, occurredAt: at);

void main() {
  final t0 = DateTime.utc(2026, 9, 24, 8);

  group('crossings', () {
    late DetectionDatabase db;
    late DetectionRepository repo;

    setUp(() {
      db = _memoryDb();
      repo = DetectionRepository(db, userId: 'alice');
    });
    tearDown(() => db.close());

    test('enter then exit after the dwell resolves once as explored', () async {
      expect(await repo.handleEvent(_event(1, CrossingKind.enter, t0)), isNull);
      expect(await repo.currentCountyCode(), 1);
      expect(await repo.activeCandidateCountyCodes(), {1});

      final exit = _event(
        1,
        CrossingKind.exit,
        t0.add(const Duration(hours: 3)),
      );
      final visit = await repo.handleEvent(exit);
      expect(visit?.outcome, VisitOutcome.explored);
      expect(await repo.handleEvent(exit), isNull);

      final queued = await db.select(db.pendingSyncOps).getSingle();
      expect(queued.userId, 'alice');
      expect(queued.outcome, 'explored');
      expect(await repo.activeCandidateCountyCodes(), isEmpty);
    });

    test('a short stay is passed through; a flap is ignored', () async {
      await repo.handleEvent(_event(1, CrossingKind.enter, t0));
      final flap = await repo.handleEvent(
        _event(1, CrossingKind.exit, t0.add(const Duration(seconds: 30))),
      );
      expect(flap, isNull);
      final visit = await repo.handleEvent(
        _event(1, CrossingKind.exit, t0.add(const Duration(minutes: 40))),
      );
      expect(visit?.outcome, VisitOutcome.passedThrough);
    });

    test('a long-running candidate resolves as explored on a check', () async {
      await repo.handleEvent(_event(1, CrossingKind.enter, t0));
      expect(
        await repo.checkStillActiveCandidates(
          now: t0.add(const Duration(minutes: 30)),
        ),
        isEmpty,
      );
      final resolved = await repo.checkStillActiveCandidates(
        now: t0.add(const Duration(hours: 2, minutes: 5)),
      );
      expect(resolved.single.outcome, VisitOutcome.explored);
      expect(await repo.pendingCountyCodes(), {1});
    });

    test('speed sanity rejects an impossible jump', () async {
      // Mombasa (1) then Nairobi (47) a minute later: ~440 km.
      await repo.handleEvent(_event(1, CrossingKind.enter, t0));
      await repo.handleEvent(
        _event(47, CrossingKind.enter, t0.add(const Duration(minutes: 1))),
      );
      expect(await repo.activeCandidateCountyCodes(), {1});
      expect(await repo.currentCountyCode(), 1);
    });

    test('crossing into a neighbouring county is not held back', () async {
      // Machakos (16) then Kajiado (34) share a border: a minute apart is
      // fine, even though their centres are far apart.
      await repo.handleEvent(_event(16, CrossingKind.enter, t0));
      await repo.handleEvent(
        _event(34, CrossingKind.enter, t0.add(const Duration(minutes: 1))),
      );
      expect(await repo.activeCandidateCountyCodes(), {16, 34});
      expect(await repo.currentCountyCode(), 34);
    });

    test('a location fix crosses from Kiambu into Nairobi', () async {
      await repo.seedCurrentCounty(22);
      final entered = await repo.reconcileCurrentLocation(
        latitude: -1.292629,
        longitude: 36.864399,
        now: t0,
      );
      expect(entered, 47);
      expect(await repo.currentCountyCode(), 47);
      expect(
        await repo.reconcileCurrentLocation(
          latitude: -1.292629,
          longitude: 36.864399,
          now: t0.add(const Duration(minutes: 5)),
        ),
        isNull,
      );
    });

    test('a fix inside another county closes the left-behind timer', () async {
      // Machakos (16) starts a timer, then Kajiado (34) is entered through
      // a plain geofence event, which leaves Machakos' timer running.
      await repo.handleEvent(_event(16, CrossingKind.enter, t0));
      await repo.handleEvent(
        _event(34, CrossingKind.enter, t0.add(const Duration(minutes: 30))),
      );
      expect(await repo.activeCandidateCountyCodes(), {16, 34});

      // A fix well inside Kajiado 90 minutes in: Machakos stops there.
      final at = t0.add(const Duration(minutes: 90));
      await repo.reconcileCurrentLocation(
        latitude: -1.8524,
        longitude: 36.7768,
        now: at,
      );

      expect(await repo.activeCandidateCountyCodes(), {34});
      final queued = await db.select(db.pendingSyncOps).get();
      expect(queued, hasLength(1));
      expect(queued.single.countyCode, 16);
      expect(queued.single.outcome, 'passed_through');
      expect(queued.single.resolvedAt, at);
    });

    test('a fix older than a timer does not cancel it', () async {
      await repo.handleEvent(_event(16, CrossingKind.enter, t0));
      await repo.reconcileCurrentLocation(
        latitude: -1.8524,
        longitude: 36.7768,
        now: t0.subtract(const Duration(minutes: 10)),
      );
      expect(await repo.activeCandidateCountyCodes(), contains(16));
    });

    test('a timer under the flap guard is dropped, not left running', () async {
      await repo.handleEvent(_event(16, CrossingKind.enter, t0));
      await repo.reconcileCurrentLocation(
        latitude: -1.8524,
        longitude: 36.7768,
        now: t0.add(const Duration(seconds: 30)),
      );
      expect(await repo.activeCandidateCountyCodes(), {34});
      expect(await db.select(db.pendingSyncOps).get(), isEmpty);
    });

    test('sign-out clears this owner\'s state', () async {
      await repo.handleEvent(_event(1, CrossingKind.enter, t0));
      await repo.handleEvent(
        _event(1, CrossingKind.exit, t0.add(const Duration(hours: 3))),
      );
      await repo.clearAllLocalState();
      expect(await db.select(db.pendingSyncOps).get(), isEmpty);
      expect(await db.select(db.candidates).get(), isEmpty);
      expect(await db.select(db.detectionOwner).get(), isEmpty);
    });
  });

  test('a running stay survives the database being closed and reopened', () async {
    // An app update or the OS killing the app mid-drive: the stay must
    // still be there afterwards.
    final dir = Directory.systemTemp.createTempSync('detection_db_');
    final file = File('${dir.path}/detection.sqlite');
    addTearDown(() => dir.deleteSync(recursive: true));

    final first = DetectionDatabase.forTesting(NativeDatabase(file));
    final repo = DetectionRepository(first, userId: 'alice');
    await repo.handleEvent(_event(34, CrossingKind.enter, t0));
    await first.close();

    final second = DetectionDatabase.forTesting(NativeDatabase(file));
    addTearDown(second.close);
    final reopened = DetectionRepository(second, userId: 'alice');
    expect(await reopened.activeCandidateCountyCodes(), {34});
    expect(await reopened.currentCountyCode(), 34);
  });

  test(
    'switching accounts clears dwell state but keeps owned queued visits',
    () async {
      final db = _memoryDb();
      final alice = DetectionRepository(db, userId: 'alice');
      await alice.seedCurrentCounty(1);
      await db
          .into(db.candidates)
          .insert(
            CandidatesCompanion.insert(
              countyCode: const Value(1),
              enteredAt: t0,
            ),
          );
      await db
          .into(db.pendingSyncOps)
          .insert(
            PendingSyncOpsCompanion.insert(
              userId: const Value('alice'),
              countyCode: 1,
              outcome: 'explored',
              enteredAt: t0,
              resolvedAt: t0,
            ),
          );

      final bob = DetectionRepository(db, userId: 'bob');
      expect(await bob.currentCountyCode(), isNull);
      expect(await bob.activeCandidateCountyCodes(), isEmpty);
      expect(await bob.pendingCountyCodes(), isEmpty);
      expect(await db.select(db.pendingSyncOps).get(), hasLength(1));

      final returning = DetectionRepository(db, userId: 'alice');
      expect(await returning.pendingCountyCodes(), {1});
      await db.close();
    },
  );

  test('a v1 schema-1 database upgrades and keeps unowned visits', () async {
    final db = DetectionDatabase.forTesting(
      NativeDatabase.memory(
        setup: (sqlite) {
          sqlite
            ..execute(
              'CREATE TABLE candidates (county_code INTEGER NOT NULL PRIMARY '
              'KEY, entered_at INTEGER NOT NULL)',
            )
            ..execute(
              'CREATE TABLE current_county (id INTEGER NOT NULL PRIMARY KEY, '
              'county_code INTEGER NOT NULL, updated_at INTEGER NOT NULL)',
            )
            ..execute(
              'CREATE TABLE pending_sync_ops (id INTEGER NOT NULL PRIMARY KEY '
              'AUTOINCREMENT, county_code INTEGER NOT NULL, outcome TEXT NOT '
              'NULL, entered_at INTEGER NOT NULL, resolved_at INTEGER NOT '
              'NULL, queued_at INTEGER NOT NULL DEFAULT (unixepoch()), '
              'attempts INTEGER NOT NULL DEFAULT 0)',
            )
            ..execute(
              'INSERT INTO pending_sync_ops (county_code, outcome, entered_at, '
              "resolved_at) VALUES (1, 'explored', 100, 200)",
            )
            ..execute('PRAGMA user_version = 1');
        },
      ),
    );
    final repo = DetectionRepository(db, userId: 'alice');
    expect(await repo.pendingCountyCodes(), isEmpty);
    final legacy = await db.select(db.pendingSyncOps).getSingle();
    expect(legacy.userId, isNull);
    expect(legacy.countyCode, 1);
    await repo.clearAllLocalState();
    expect(await db.select(db.pendingSyncOps).get(), hasLength(1));
    await db.close();
  });
}
