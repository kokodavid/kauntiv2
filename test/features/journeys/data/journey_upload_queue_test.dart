import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/journeys/data/journey_database.dart';
import 'package:kaunti47_v2/src/features/journeys/data/journey_upload_queue.dart';
import 'package:kaunti47_v2/src/features/journeys/data/local_journey_repository.dart';
import 'package:kaunti47_v2/src/features/journeys/domain/journey_destination.dart';
import 'package:kaunti47_v2/src/features/journeys/domain/journey_point.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  final t0 = DateTime.utc(2026, 9, 25, 10);
  late JourneyDatabase db;
  late LocalJourneyRepository local;
  late List<String> uploaded;
  late Exception? Function(String id) failWith;
  late void Function(String id) onUpload;
  late JourneyDestination? uploadedDestination;
  String? user = 'alice';

  JourneyUploadQueue queue() => JourneyUploadQueue(
    db,
    currentUserId: () => user,
    upload:
        ({
          required userId,
          required id,
          required title,
          required startedAt,
          required endedAt,
          required pausedDuration,
          required points,
          destination,
        }) async {
          expect(userId, 'alice');
          onUpload(id);
          final error = failWith(id);
          if (error != null) throw error;
          expect(points, hasLength(1));
          expect(
            title,
            destination == null
                ? startsWith('Trip on ')
                : 'Trip to ${destination.name}',
          );
          uploadedDestination = destination;
          uploaded.add(id);
        },
  );

  Future<void> completed(
    String id, {
    int offsetMinutes = 0,
    JourneyDestination? destination,
  }) async {
    final start = t0.add(Duration(minutes: offsetMinutes));
    await local.start(
      id: id,
      userId: 'alice',
      at: start,
      destination: destination,
    );
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
    onUpload = (_) {};
    uploadedDestination = null;
    user = 'alice';
  });
  tearDown(() => db.close());

  test('uploads the chosen place and labels pending history', () async {
    const destination = JourneyDestination(
      placeId: 'place-1',
      name: 'Nairobi National Museum',
      latitude: -1.273,
      longitude: 36.814,
    );
    await completed('a', destination: destination);
    final q = queue();
    final pending = await q.pending('alice');
    expect(pending.single.destination?.placeId, destination.placeId);
    expect(pending.single.title, 'Trip to Nairobi National Museum');
    expect(await q.drain(now: t0.add(const Duration(hours: 1))), 1);
    expect(uploadedDestination?.placeId, destination.placeId);
  });

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

  test(
    'a free Trip limit rejection marks the Trip, then clears once lifted',
    () async {
      await completed('a');
      failWith = (_) =>
          const PostgrestException(message: 'limit reached', code: '75001');
      final q = queue();
      final now = t0.add(const Duration(hours: 1));

      expect(await q.drain(now: now), 0);
      expect((await q.pending('alice')).single.blockedByTrialLimit, isTrue);

      failWith = (_) => null;
      expect(await q.drain(now: now.add(const Duration(hours: 25))), 1);
      expect(await q.pending('alice'), isEmpty);
    },
  );

  test(
    'nothing uploads when signed out, and local deletes are owned',
    () async {
      await completed('a');
      user = null;
      expect(await queue().drain(now: t0.add(const Duration(hours: 1))), 0);

      await expectLater(
        queue().deleteLocal('a', 'bob'),
        throwsA(isA<StateError>()),
      );
      expect(await queue().pending('alice'), hasLength(1));
      expect(await queue().deleteLocal('a', 'alice'), isFalse);
      expect(await queue().pending('alice'), isEmpty);
    },
  );

  test(
    'an account switch mid-upload stops the drain, blaming nothing',
    () async {
      await completed('a');
      await completed('b', offsetMinutes: 10);
      // The account changes while "a" is uploading; the server refuses it.
      onUpload = (_) => user = 'bob';
      failWith = (_) =>
          const PostgrestException(message: 'owner', code: '42501');
      final q = queue();
      final now = t0.add(const Duration(hours: 1));

      expect(await q.drain(now: now), 0);
      // Nothing was marked as failed: both are due again for alice.
      user = 'alice';
      onUpload = (_) {};
      failWith = (_) => null;
      expect(await q.drain(now: now), 2);
    },
  );

  test('an account switch after an upload stops before the next', () async {
    await completed('a');
    await completed('b', offsetMinutes: 10);
    onUpload = (_) => user = 'bob';
    expect(await queue().drain(now: t0.add(const Duration(hours: 1))), 1);
    expect(uploaded, ['a']);
  });

  test('deleting during upload requires removal of the cloud copy', () async {
    await completed('a');
    final uploadStarted = Completer<void>();
    final releaseUpload = Completer<void>();
    final q = JourneyUploadQueue(
      db,
      currentUserId: () => user,
      upload:
          ({
            required userId,
            required id,
            required title,
            required startedAt,
            required endedAt,
            required pausedDuration,
            required points,
            destination,
          }) async {
            uploadStarted.complete();
            await releaseUpload.future;
          },
    );
    final draining = q.drain(now: t0.add(const Duration(hours: 1)));
    await uploadStarted.future;
    final deleting = q.deleteLocal('a', 'alice');
    releaseUpload.complete();
    expect(await deleting, isTrue);
    expect(await draining, 1);
    expect(await q.pending('alice'), isEmpty);
  });
}
