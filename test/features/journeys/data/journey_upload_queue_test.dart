import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/journeys/data/journey_database.dart';
import 'package:kaunti47_v2/src/features/journeys/data/journey_upload_queue.dart';
import 'package:kaunti47_v2/src/features/journeys/data/local_journey_repository.dart';
import 'package:kaunti47_v2/src/features/journeys/domain/journey_point.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  final t0 = DateTime.utc(2026, 9, 25, 10);
  late JourneyDatabase db;
  late LocalJourneyRepository local;
  late List<String> uploaded;
  late Object? Function(String id) failWith;
  String? user = 'alice';

  JourneyUploadQueue queue() => JourneyUploadQueue(
    db,
    currentUserId: () => user,
    upload:
        ({
          required id,
          required title,
          required startedAt,
          required endedAt,
          required points,
        }) async {
          final error = failWith(id);
          if (error != null) throw error;
          expect(points, hasLength(1));
          expect(title, startsWith('Journey on '));
          uploaded.add(id);
        },
  );

  Future<void> completed(String id, {int offsetMinutes = 0}) async {
    final start = t0.add(Duration(minutes: offsetMinutes));
    await local.start(id: id, userId: 'alice', at: start);
    await local.appendPoint(
      id: id,
      userId: 'alice',
      point: JourneyPoint(
        recordedAt: start.add(const Duration(minutes: 1)),
        latitude: -1.29,
        longitude: 36.82,
        accuracyMeters: 8,
        segmentNumber: 0,
      ),
    );
    await local.finish(
      id: id,
      userId: 'alice',
      at: start.add(const Duration(minutes: 5)),
    );
  }

  setUp(() {
    db = JourneyDatabase.forTesting(NativeDatabase.memory());
    local = LocalJourneyRepository(db);
    uploaded = [];
    failWith = (_) => null;
    user = 'alice';
  });
  tearDown(() => db.close());

  test('uploads completed Journeys oldest first and deletes them', () async {
    await completed('b', offsetMinutes: 10);
    await completed('a');
    final q = queue();
    expect(await q.pending('alice'), hasLength(2));

    expect(await q.drain(now: t0.add(const Duration(hours: 1))), 2);
    expect(uploaded, ['a', 'b']);
    expect(await q.pending('alice'), isEmpty);
    expect(await db.select(db.journeySamples).get(), isEmpty);
  });

  test('an active Journey is not uploaded', () async {
    await local.start(id: 'live', userId: 'alice', at: t0);
    expect(await queue().drain(now: t0), 0);
    expect(uploaded, isEmpty);
  });

  test('offline stops the drain and backs off; the copy stays', () async {
    await completed('a');
    await completed('b', offsetMinutes: 10);
    failWith = (_) => Exception('offline');
    final q = queue();
    final now = t0.add(const Duration(hours: 1));

    expect(await q.drain(now: now), 0);
    expect(await q.pending('alice'), hasLength(2));
    // Backed off: nothing is due a second later.
    failWith = (_) => null;
    expect(await q.drain(now: now.add(const Duration(seconds: 1))), 1);
    expect(uploaded, ['b']);
    expect(await q.drain(now: now.add(const Duration(minutes: 1))), 1);
  });

  test('a permanent rejection waits a day and the drain moves on', () async {
    await completed('a');
    await completed('b', offsetMinutes: 10);
    failWith = (id) => id == 'a'
        ? const PostgrestException(message: 'no pro', code: '42501')
        : null;
    final q = queue();
    final now = t0.add(const Duration(hours: 1));

    expect(await q.drain(now: now), 1);
    expect(uploaded, ['b']);
    failWith = (_) => null;
    expect(await q.drain(now: now.add(const Duration(hours: 23))), 0);
    expect(await q.drain(now: now.add(const Duration(hours: 25))), 1);
  });

  test('nothing uploads when signed out, and local deletes are owned', () async {
    await completed('a');
    user = null;
    expect(await queue().drain(now: t0.add(const Duration(hours: 1))), 0);

    await queue().deleteLocal('a', 'bob');
    expect(await queue().pending('alice'), hasLength(1));
    await queue().deleteLocal('a', 'alice');
    expect(await queue().pending('alice'), isEmpty);
  });
}
