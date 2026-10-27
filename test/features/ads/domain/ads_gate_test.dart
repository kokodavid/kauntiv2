import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/ads/domain/ads_gate.dart';
import 'package:kaunti47_v2/src/features/journeys/domain/pro_status.dart';

void main() {
  final now = DateTime.utc(2026, 10, 27);
  ProStatus status({required bool active, DateTime? until}) =>
      ProStatus(active: active, checkedAt: now, activeUntil: until);

  group('audienceFor', () {
    test('not checked yet is unknown', () {
      expect(AdsGate.audienceFor(null, now), AdsAudience.unknown);
    });

    test('active Pro is pro, open-ended or inside its period', () {
      expect(AdsGate.audienceFor(status(active: true), now), AdsAudience.pro);
      expect(
        AdsGate.audienceFor(
          status(active: true, until: now.add(const Duration(days: 3))),
          now,
        ),
        AdsAudience.pro,
      );
    });

    test('inactive or lapsed Pro is free', () {
      expect(AdsGate.audienceFor(status(active: false), now), AdsAudience.free);
      expect(
        AdsGate.audienceFor(
          status(active: true, until: now.subtract(const Duration(days: 1))),
          now,
        ),
        AdsAudience.free,
      );
    });
  });

  group('shouldShow', () {
    bool show(AdsAudience a, {bool consent = true, bool enabled = true}) =>
        AdsGate.shouldShow(audience: a, consentDone: consent, enabled: enabled);

    test('only a free audience with consent, when enabled', () {
      expect(show(AdsAudience.free), isTrue);
      expect(show(AdsAudience.pro), isFalse);
      expect(show(AdsAudience.unknown), isFalse);
      expect(show(AdsAudience.free, consent: false), isFalse);
      expect(show(AdsAudience.free, enabled: false), isFalse);
    });
  });
}
