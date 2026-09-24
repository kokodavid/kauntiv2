import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/core/services/app_current_location.dart';
import 'package:kaunti47_v2/src/features/detection/application/detection_controller.dart';
import 'package:kaunti47_v2/src/features/detection/application/detection_providers.dart';
import 'package:kaunti47_v2/src/features/detection/application/visit_sync.dart';
import 'package:kaunti47_v2/src/features/detection/data/detection_permission.dart';
import 'package:kaunti47_v2/src/features/detection/data/detection_repository.dart';
import 'package:kaunti47_v2/src/features/detection/data/geofence_service.dart';
import 'package:kaunti47_v2/src/features/detection/data/local/detection_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  var removed = 0;

  @override
  Future<void> removeAll() async => removed++;
}

class _FakePermission implements DetectionPermission {
  var granted = true;
  var settingsOpened = 0;

  @override
  Future<bool> backgroundGranted() async => granted;

  @override
  Future<void> openSettings() async => settingsOpened++;
}

const AppLocationFix _nairobi = (latitude: -1.292629, longitude: 36.864399);

void main() {
  late DetectionDatabase db;
  late DetectionRepository repo;
  late _FakeGeofences geofences;
  late _FakePermission permission;

  ProviderContainer container(AppLocationFix? fix) {
    final c = ProviderContainer(
      overrides: [
        detectionRepositoryProvider.overrideWithValue(repo),
        geofenceServiceProvider.overrideWithValue(geofences),
        detectionPermissionProvider.overrideWithValue(permission),
        visitSyncQueueProvider.overrideWithValue(null),
        detectionLocationReaderProvider.overrideWithValue(() async => fix),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = DetectionDatabase.forTesting(NativeDatabase.memory());
    repo = DetectionRepository(db, userId: 'alice');
    geofences = _FakeGeofences();
    permission = _FakePermission();
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

  test('losing background location pauses detection once', () async {
    await repo.seedCurrentCounty(22);
    permission.granted = false;
    final c = container(_nairobi);
    final controller = c.read(detectionControllerProvider.notifier);

    await controller.runCycle();
    await controller.runCycle();

    expect(geofences.removed, 1);
    expect(geofences.registered, isEmpty);
    // No reconcile while paused: still in Kiambu, no candidate.
    expect(await repo.currentCountyCode(), 22);
    expect(await repo.activeCandidateCountyCodes(), isEmpty);
    expect(c.read(detectionControllerProvider).backgroundLocationOff, isTrue);

    await controller.openLocationSettings();
    expect(permission.settingsOpened, 1);
  });

  test('getting it back resumes detection', () async {
    await repo.seedCurrentCounty(22);
    permission.granted = false;
    final c = container(_nairobi);
    final controller = c.read(detectionControllerProvider.notifier);
    await controller.runCycle();

    permission.granted = true;
    await controller.runCycle();

    expect(c.read(detectionControllerProvider).backgroundLocationOff, isFalse);
    expect(await repo.currentCountyCode(), 47);
    expect(geofences.registered, [(47, false)]);
  });
}
