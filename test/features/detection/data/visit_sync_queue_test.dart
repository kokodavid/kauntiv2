import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/detection/data/local/detection_database.dart';
import 'package:kaunti47_v2/src/features/detection/data/visit_sync_queue.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  final t0 = DateTime.utc(2026, 9, 24, 8);
  late DetectionDatabase db;

  setUp(() => db = DetectionDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> queue(int county, {String owner = 'alice', DateTime? at}) => db
      .into(db.pendingSyncOps)
      .insert(
        PendingSyncOpsCompanion.insert(
          userId: Value(owner),
          countyCode: county,
          outcome: 'explored',
          enteredAt: t0,
          resolvedAt: t0,
          queuedAt: Value(at ?? t0),
        ),
      );

  VisitSyncQueue queueFor(UploadVisit upload, {String? Function()? user}) =>
      VisitSyncQueue(db, currentUserId: user ?? () => 'alice', upload: upload);

  test('uploads oldest first and removes synced visits', () async {
    await queue(2, at: t0.add(const Duration(minutes: 1)));
    await queue(1);
    final sent = <int>[];
    final synced = await queueFor((owner, op) async {
      sent.add(op.countyCode);
      return const [];
    }).drain(now: t0.add(const Duration(minutes: 5)));
    expect(synced, 2);
    expect(sent, [1, 2]);
    expect(await db.select(db.pendingSyncOps).get(), isEmpty);
  });

  test('only the signed-in owner\'s visits are sent', () async {
    await queue(1);
    await queue(2, owner: 'bob');
    final sent = <String>[];
    await queueFor((owner, op) async {
      sent.add('$owner:${op.countyCode}');
      return const [];
    }).drain(now: t0);
    expect(sent, ['alice:1']);
  });

  test('a transient failure backs off and stops the drain', () async {
    await queue(1);
    await queue(2, at: t0.add(const Duration(minutes: 1)));
    var calls = 0;
    final synced = await queueFor((owner, op) async {
      calls++;
      throw Exception('offline');
    }).drain(now: t0);
    expect(synced, 0);
    expect(calls, 1);
    final first = await (db.select(
      db.pendingSyncOps,
    )..where((o) => o.countyCode.equals(1))).getSingle();
    expect(first.attempts, 1);
    expect(
      first.nextAttemptAt!.isAtSameMomentAs(
        t0.add(const Duration(seconds: 15)),
      ),
      isTrue,
    );

    // Not due yet: nothing is retried.
    calls = 0;
    await queueFor((owner, op) async {
      calls++;
      return const [];
    }).drain(now: t0.add(const Duration(seconds: 5)));
    expect(calls, 1); // only county 2, which was never attempted
  });

  test('a permanent rejection waits a day and the drain continues', () async {
    await queue(1);
    await queue(2, at: t0.add(const Duration(minutes: 1)));
    final synced = await queueFor((owner, op) async {
      if (op.countyCode == 1) {
        throw const PostgrestException(message: 'no', code: '42501');
      }
      return const [];
    }).drain(now: t0);
    expect(synced, 1);
    final rejected = await db.select(db.pendingSyncOps).getSingle();
    expect(rejected.countyCode, 1);
    expect(
      rejected.nextAttemptAt!.isAtSameMomentAs(t0.add(const Duration(days: 1))),
      isTrue,
    );
  });

  test('a malformed confirmation is treated as a failure', () async {
    await queue(1);
    final synced = await queueFor(
      (owner, op) async => {'ok': true},
    ).drain(now: t0);
    expect(synced, 0);
    expect(await db.select(db.pendingSyncOps).get(), hasLength(1));
  });

  test('signed out: nothing is sent', () async {
    await queue(1);
    var calls = 0;
    await queueFor((owner, op) async {
      calls++;
      return const [];
    }, user: () => null).drain(now: t0);
    expect(calls, 0);
  });

  test('backoff caps at 15 minutes', () {
    expect(VisitSyncQueue.retryDelay(0, false), const Duration(seconds: 15));
    expect(VisitSyncQueue.retryDelay(3, false), const Duration(minutes: 2));
    expect(VisitSyncQueue.retryDelay(20, false), const Duration(minutes: 15));
    expect(VisitSyncQueue.retryDelay(0, true), const Duration(days: 1));
  });
}
