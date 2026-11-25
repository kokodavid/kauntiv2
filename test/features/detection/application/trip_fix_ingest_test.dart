import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/detection/application/trip_fix_ingest.dart';
import 'package:kaunti47_v2/src/features/detection/data/detection_repository.dart';
import 'package:kaunti47_v2/src/features/detection/data/local/detection_database.dart';
import 'package:kaunti47_v2/src/features/detection/domain/visit_models.dart';

// Well inside Kajiado and Nairobi.
const _kajiado = (lat: -1.8524, lng: 36.7768);
const _nairobi = (lat: -1.292629, lng: 36.864399);

void main() {
  final t0 = DateTime.utc(2026, 11, 13, 5);
  late DetectionDatabase db;
  late DetectionRepository repo;

  setUp(() {
    db = DetectionDatabase.forTesting(NativeDatabase.memory());
    repo = DetectionRepository(db, userId: 'alice');
  });
  tearDown(() => db.close());

  TripFixIngest ingest({
    DateTime? now,
    bool signedIn = true,
    Duration minGap = const Duration(seconds: 20),
  }) => TripFixIngest(
    () => repo,
    isSignedIn: () => signedIn,
    minGap: minGap,
    clock: () => now ?? t0,
  );

  Future<void> startMachakos() => repo.handleEvent(
    CountyCrossingEvent(
      countyCode: 16,
      kind: CrossingKind.enter,
      occurredAt: t0,
    ),
  );

  test('a Trip fix in another county closes the left-behind timer', () async {
    await startMachakos();
    final at = t0.add(const Duration(minutes: 90));
    await ingest(
      now: at,
    ).offer(latitude: _kajiado.lat, longitude: _kajiado.lng, at: at);
    final queued = await db.select(db.pendingSyncOps).get();
    expect(queued.single.countyCode, 16);
    expect(queued.single.outcome, 'passed_through');
    expect(queued.single.resolvedAt, at);
    expect(await repo.currentCountyCode(), 34);
  });

  test('fixes arriving close together are handled once', () async {
    final at = t0.add(const Duration(minutes: 5));
    final sink = ingest(now: at);
    await sink.offer(latitude: _kajiado.lat, longitude: _kajiado.lng, at: at);
    await sink.offer(
      latitude: _nairobi.lat,
      longitude: _nairobi.lng,
      at: at.add(const Duration(seconds: 5)),
    );
    expect(await repo.currentCountyCode(), 34);
  });

  test('nothing happens when signed out', () async {
    await startMachakos();
    final at = t0.add(const Duration(minutes: 90));
    await ingest(
      now: at,
      signedIn: false,
    ).offer(latitude: _kajiado.lat, longitude: _kajiado.lng, at: at);
    expect(await db.select(db.pendingSyncOps).get(), isEmpty);
  });

  test('a fix older than two minutes is ignored', () async {
    await startMachakos();
    final now = t0.add(const Duration(minutes: 90));
    await ingest(now: now).offer(
      latitude: _kajiado.lat,
      longitude: _kajiado.lng,
      at: now.subtract(const Duration(minutes: 5)),
    );
    expect(await db.select(db.pendingSyncOps).get(), isEmpty);
    expect(await repo.activeCandidateCountyCodes(), {16});
  });
}
