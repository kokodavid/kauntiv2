import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/auth/application/auth_providers.dart';
import 'package:kaunti47_v2/src/features/journeys/application/journey_cloud_providers.dart';
import 'package:kaunti47_v2/src/features/journeys/application/journey_entitlement.dart';
import 'package:kaunti47_v2/src/features/journeys/application/journey_history.dart';
import 'package:kaunti47_v2/src/features/journeys/application/journey_providers.dart';
import 'package:kaunti47_v2/src/features/journeys/application/journey_recorder.dart';
import 'package:kaunti47_v2/src/features/journeys/data/journey_database.dart';
import 'package:kaunti47_v2/src/features/journeys/data/journey_upload_queue.dart';
import 'package:kaunti47_v2/src/features/journeys/data/pro_status_cache.dart';
import 'package:kaunti47_v2/src/features/journeys/data/supabase_journey_repository.dart';
import 'package:kaunti47_v2/src/features/journeys/domain/journey_fix.dart';
import 'package:kaunti47_v2/src/features/journeys/domain/journey_recording.dart';
import 'package:kaunti47_v2/src/features/journeys/domain/journey_summary.dart';
import 'package:kaunti47_v2/src/features/journeys/domain/pro_status.dart';

class _FakeSource implements JourneyLocationSource {
  final controller = StreamController<JourneyFix>.broadcast(sync: true);
  var started = false;

  @override
  Stream<JourneyFix> get fixes => controller.stream;

  @override
  Future<void> start() async => started = true;

  @override
  Future<void> stop() async => started = false;
}

class _FakeCloud implements SupabaseJourneyRepository {
  ProStatus? status;
  var offline = false;
  final cloudJourneys = <JourneySummary>[];

  @override
  String? get currentUserId => 'alice';

  @override
  Future<ProStatus> proStatus() async {
    if (offline) throw Exception('offline');
    return status!;
  }

  @override
  Future<List<JourneySummary>> history() async {
    if (offline) throw Exception('offline');
    return cloudJourneys;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final now = DateTime.utc(2026, 9, 25, 12);
  late JourneyDatabase db;
  late _FakeSource source;
  late _FakeCloud cloud;
  late List<String> uploads;
  var uploadsFail = false;

  ProviderContainer container() {
    final c = ProviderContainer(
      overrides: [
        journeyDatabaseProvider.overrideWithValue(db),
        journeyLocationSourceProvider.overrideWithValue(source),
        currentUserIdProvider.overrideWithValue(() => 'alice'),
        supabaseJourneyRepositoryProvider.overrideWithValue(cloud),
        journeyUploadQueueProvider.overrideWithValue(
          JourneyUploadQueue(
            db,
            currentUserId: () => 'alice',
            upload:
                ({
                  required id,
                  required title,
                  required startedAt,
                  required endedAt,
                  required points,
                }) async {
                  if (uploadsFail) throw Exception('offline');
                  uploads.add(id);
                },
          ),
        ),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  setUp(() {
    db = JourneyDatabase.forTesting(NativeDatabase.memory());
    source = _FakeSource();
    cloud = _FakeCloud();
    uploads = [];
    uploadsFail = false;
  });
  tearDown(() async {
    await source.controller.close();
    await db.close();
  });

  test('without Pro a Journey cannot start', () async {
    cloud.status = ProStatus(active: false, checkedAt: now);
    final c = container();
    await expectLater(
      c.read(journeyRecorderProvider.notifier).start(now: now),
      throwsA(isA<JourneyStartDenied>()),
    );
    expect(c.read(journeyRecorderProvider), isNull);
    expect(source.started, isFalse);
  });

  test('with Pro it records, and finishing uploads it', () async {
    cloud.status = ProStatus(active: true, checkedAt: now);
    final c = container();
    final recorder = c.read(journeyRecorderProvider.notifier);

    await recorder.start(now: now);
    expect(source.started, isTrue);
    expect(
      c.read(journeyRecorderProvider)?.recording.phase,
      JourneyRecordingPhase.recording,
    );

    await recorder.finish();
    expect(c.read(journeyRecorderProvider), isNull);
    await c.read(journeySyncProvider.notifier).drain();
    expect(uploads, hasLength(1));
  });

  test('offline, a recent confirmed Pro status still allows a start', () async {
    cloud.status = ProStatus(active: true, checkedAt: now);
    final c = container();
    final entitlement = c.read(journeyEntitlementProvider.notifier);
    expect(await entitlement.canStart(now: now), isTrue);

    cloud.offline = true;
    expect(
      await entitlement.canStart(now: now.add(const Duration(days: 3))),
      isTrue,
    );
    expect(
      await entitlement.canStart(now: now.add(const Duration(days: 8))),
      isFalse,
    );
    expect(await ProStatusCache(db).read('alice'), isNotNull);
  });

  test('history lists waiting Journeys first, then the cloud', () async {
    cloud.status = ProStatus(active: true, checkedAt: now);
    cloud.cloudJourneys.add(
      JourneySummary(
        id: 'cloud-1',
        title: 'Earlier',
        startedAt: now.subtract(const Duration(days: 1)),
        endedAt: now.subtract(const Duration(hours: 20)),
        distanceMeters: 1200,
        isUploaded: true,
      ),
    );
    uploadsFail = true;
    final c = container();
    // Keep the auto-dispose history alive between reads.
    c.listen(journeyHistoryListProvider, (_, _) {});
    final recorder = c.read(journeyRecorderProvider.notifier);
    await recorder.start(now: now);
    await recorder.finish();

    final history = await c.read(journeyHistoryListProvider.future);
    expect(history.journeys.map((j) => j.isUploaded), [false, true]);

    cloud.offline = true;
    c.invalidate(journeyHistoryListProvider);
    final offline = await c.read(journeyHistoryListProvider.future);
    expect(offline.cloudUnavailable, isTrue);
    expect(offline.journeys, hasLength(1));
  });
}
