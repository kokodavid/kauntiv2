import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/core/services/app_current_location.dart';
import 'package:kaunti47_v2/src/features/detection/application/detection_controller.dart';
import 'package:kaunti47_v2/src/features/detection/application/detection_providers.dart';
import 'package:kaunti47_v2/src/features/detection/application/visit_sync.dart';
import 'package:kaunti47_v2/src/features/detection/data/detection_repository.dart';
import 'package:kaunti47_v2/src/features/detection/data/geofence_service.dart';
import 'package:kaunti47_v2/src/features/detection/data/local/detection_database.dart';

class _FakeGeofences implements GeofenceService {
  final registered = <(int, bool)>[];
  var initialized = 0;

  @override
  Future<void> initialize() async => initialized++;

  @override
  Future<void> registerWindowFor(
    int countyCode, {
    bool triggerEnterImmediately = false,
  }) async => registered.add((countyCode, triggerEnterImmediately));

  @override
  Future<void> removeAll() async {}
}

const AppLocationFix _nairobi = (latitude: -1.292629, longitude: 36.864399);

void main() {
  late DetectionDatabase db;
  late DetectionRepository repo;
  late _FakeGeofences geofences;

  ProviderContainer container(AppLocationFix? fix) {
    final c = ProviderContainer(
      overrides: [
        detectionRepositoryProvider.overrideWithValue(repo),
        geofenceServiceProvider.overrideWithValue(geofences),
        visitSyncQueueProvider.overrideWithValue(null),
        detectionLocationReaderProvider.overrideWithValue(() async => fix),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  setUp(() {
    db = DetectionDatabase.forTesting(NativeDatabase.memory());
    repo = DetectionRepository(db, userId: 'alice');
    geofences = _FakeGeofences();
  });
  tearDown(() => db.close());

  test('first cycle seeds the county from the fix', () async {
    final c = container(_nairobi);
    await c
        .read(detectionControllerProvider.notifier)
        .runCycle(homeCountyCode: 22);
    expect(await repo.currentCountyCode(), 47);
    // In Nairobi but home is Kiambu: no synthetic ENTER.
    expect(geofences.registered, [(47, false)]);
    expect(c.read(detectionControllerProvider).currentCounty, 47);
  });

  test('without a fix it falls back to the home county', () async {
    final c = container(null);
    await c
        .read(detectionControllerProvider.notifier)
        .runCycle(homeCountyCode: 22);
    expect(await repo.currentCountyCode(), 22);
    expect(geofences.registered, [(22, true)]);
  });

  test('a later fix in another county becomes a crossing', () async {
    await repo.seedCurrentCounty(22);
    final c = container(_nairobi);
    await c.read(detectionControllerProvider.notifier).runCycle();
    expect(await repo.currentCountyCode(), 47);
    expect(await repo.activeCandidateCountyCodes(), {47});
    expect(geofences.registered, [(47, false)]);
    expect(
      c.read(detectionControllerProvider).activeCandidates.single.countyCode,
      47,
    );
  });

  test('no fix and no home county: nothing is registered', () async {
    final c = container(null);
    await c.read(detectionControllerProvider.notifier).runCycle();
    expect(await repo.currentCountyCode(), isNull);
    expect(geofences.registered, isEmpty);
  });
}
