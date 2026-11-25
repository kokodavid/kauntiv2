import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/auth/application/auth_providers.dart';
import 'package:kaunti47_v2/src/features/detection/application/county_tracking.dart';
import 'package:kaunti47_v2/src/features/detection/application/detection_providers.dart';
import 'package:kaunti47_v2/src/features/detection/data/county_tracking_location_source.dart';
import 'package:kaunti47_v2/src/features/detection/data/detection_repository.dart';
import 'package:kaunti47_v2/src/features/detection/data/local/detection_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Source implements CountyTrackingSource {
  _Source({this.allowed = true});

  final bool allowed;
  // Closed by the ProviderContainer test teardown.
  // ignore: close_sinks
  final fixes = StreamController<CountyTrackingFix>.broadcast();
  var starts = 0;
  var stops = 0;

  @override
  Future<bool> canRun() async => allowed;

  @override
  Future<void> applySettings() async {}

  @override
  Future<Stream<CountyTrackingFix>?> start() async {
    starts++;
    return fixes.stream;
  }

  @override
  Future<void> stop() async => stops++;
}

void main() {
  late DetectionDatabase db;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = DetectionDatabase.forTesting(NativeDatabase.memory());
  });
  tearDown(() => db.close());

  Future<ProviderContainer> container(_Source source) async {
    final repository = DetectionRepository(db, userId: 'alice');
    await repository.ready;
    final c = ProviderContainer(
      overrides: [
        countyTrackingSourceProvider.overrideWithValue(source),
        currentUserIdProvider.overrideWithValue(() => 'alice'),
        detectionRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  test('off by default: nothing starts', () async {
    final source = _Source();
    final c = await container(source);
    expect(await c.read(countyTrackingProvider.future), isFalse);
    await c.read(countyTrackingProvider.notifier).sync(tripRecording: false);
    expect(source.starts, 0);
  });

  test('turning it on starts updates; off stops them', () async {
    final source = _Source();
    final c = await container(source);
    final tracking = c.read(countyTrackingProvider.notifier);
    expect(await tracking.setEnabled(true), isTrue);
    expect(source.starts, 1);
    expect(c.read(countyTrackingProvider).value, isTrue);

    await tracking.setEnabled(false);
    expect(source.stops, 1);
  });

  test('stays off when location is not allowed all the time', () async {
    final source = _Source(allowed: false);
    final c = await container(source);
    expect(
      await c.read(countyTrackingProvider.notifier).setEnabled(true),
      isFalse,
    );
    expect(source.starts, 0);
    expect(await c.read(countyTrackingProvider.future), isFalse);
  });

  test(
    'steps aside for a recording Trip without stopping its location',
    () async {
      final source = _Source();
      final c = await container(source);
      final tracking = c.read(countyTrackingProvider.notifier);
      await tracking.setEnabled(true);

      await tracking.sync(tripRecording: true);
      expect(source.stops, 0, reason: 'the Trip owns background location');

      await tracking.sync(tripRecording: false);
      expect(source.starts, 2);
    },
  );

  test('a fix inside a county reaches detection', () async {
    final source = _Source();
    final c = await container(source);
    await c.read(countyTrackingProvider.notifier).setEnabled(true);

    source.fixes.add((
      latitude: -1.8524,
      longitude: 36.7768,
      accuracyMeters: 800,
      at: DateTime.now().toUtc(),
    ));
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(await c.read(detectionRepositoryProvider).currentCountyCode(), 34);
  });
}
