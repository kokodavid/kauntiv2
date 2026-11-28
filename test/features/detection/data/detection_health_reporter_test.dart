import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/detection/data/detection_health_reporter.dart';
import 'package:kaunti47_v2/src/features/detection/data/detection_outcome_counts.dart';
import 'package:kaunti47_v2/src/features/detection/data/device_profile.dart';
import 'package:kaunti47_v2/src/features/detection/domain/detection_health_report.dart';
import 'package:kaunti47_v2/src/features/detection/domain/detection_status.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final now = DateTime.utc(2026, 11, 27, 10);
  late List<Map<String, Object?>> sent;
  late DetectionHealthReporter reporter;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    sent = [];
    reporter = DetectionHealthReporter(
      send: (params) async {
        sent.add(params);
        return null;
      },
      loadDevice: () async => const DeviceProfile(
        platform: 'android',
        manufacturer: 'TECNO',
        model: 'CK8n',
      ),
    );
  });

  test('sends once, then waits for a tier change', () async {
    const live = DetectionStatus(tier: DetectionTier.live);
    await reporter.maybeReport(live, now: now);
    await reporter.maybeReport(live, now: now.add(const Duration(hours: 1)));
    expect(sent, hasLength(1));
    await reporter.maybeReport(
      const DetectionStatus(
        tier: DetectionTier.off,
        reason: DetectionReason.noPermission,
      ),
      now: now.add(const Duration(hours: 2)),
    );
    expect(sent, hasLength(2));
    expect(sent.last['p_tier'], 'off');
    expect(sent.last['p_manufacturer'], 'TECNO');
  });

  test('counts are sent then cleared', () async {
    const counts = DetectionOutcomeCounts();
    await counts.add(DetectionOutcome.transit, 2);
    await reporter.maybeReport(
      const DetectionStatus(tier: DetectionTier.live),
      now: now,
    );
    expect(sent.single['p_counts'], {'transit': 2});
    expect(await counts.snapshot(), isEmpty);
  });

  test('a failed send keeps the counts and tries again', () async {
    const counts = DetectionOutcomeCounts();
    await counts.add(DetectionOutcome.claimed);
    final failing = DetectionHealthReporter(
      send: (_) async => throw Exception('offline'),
      loadDevice: () async => const DeviceProfile(platform: 'ios'),
    );
    await failing.maybeReport(
      const DetectionStatus(tier: DetectionTier.live),
      now: now,
    );
    expect(await counts.snapshot(), {'claimed': 1});
    await reporter.maybeReport(
      const DetectionStatus(tier: DetectionTier.live),
      now: now,
    );
    expect(sent, hasLength(1));
  });
}
