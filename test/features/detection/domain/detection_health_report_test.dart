import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/detection/domain/detection_health_report.dart';
import 'package:kaunti47_v2/src/features/detection/domain/detection_status.dart';

void main() {
  final now = DateTime.utc(2026, 11, 27, 10);

  test('first report is always due', () {
    expect(
      DetectionHealthPolicy.due(tier: DetectionTier.live, now: now),
      isTrue,
    );
  });

  test('same tier waits a day, a tier change reports at once', () {
    final last = now.subtract(const Duration(hours: 3));
    expect(
      DetectionHealthPolicy.due(
        tier: DetectionTier.live,
        now: now,
        lastAt: last,
        lastTier: DetectionTier.live,
      ),
      isFalse,
    );
    expect(
      DetectionHealthPolicy.due(
        tier: DetectionTier.off,
        now: now,
        lastAt: last,
        lastTier: DetectionTier.live,
      ),
      isTrue,
    );
    expect(
      DetectionHealthPolicy.due(
        tier: DetectionTier.live,
        now: now,
        lastAt: now.subtract(const Duration(hours: 25)),
        lastTier: DetectionTier.live,
      ),
      isTrue,
    );
  });

  test('RPC params carry state and device, nothing about places', () {
    final params = const DetectionHealthReport(
      platform: 'android',
      manufacturer: 'TECNO',
      model: 'CK8n',
      tier: DetectionTier.catchUp,
      reason: DetectionReason.backgroundMissing,
      lastCycleGapSeconds: 12,
      counts: {'claimed': 2},
    ).toRpcParams();
    expect(params['p_tier'], 'catch_up');
    expect(params['p_reason'], 'background_missing');
    expect(params['p_counts'], {'claimed': 2});
    expect(
      params.keys.where(
        (k) =>
            k.contains('lat') && !k.contains('last') ||
            k.contains('lng') ||
            k.contains('county'),
      ),
      isEmpty,
    );
  });

  test('gapSeconds is null when unknown and never negative', () {
    expect(DetectionHealthReport.gapSeconds(null, now), isNull);
    expect(
      DetectionHealthReport.gapSeconds(
        now.add(const Duration(seconds: 5)),
        now,
      ),
      0,
    );
  });
}
