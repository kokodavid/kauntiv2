import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/detection/domain/always_ask_rules.dart';
import 'package:kaunti47_v2/src/features/detection/domain/detection_status.dart';

void main() {
  bool ask({
    DetectionTier tier = DetectionTier.catchUp,
    int claimed = 1,
    bool asked = false,
  }) => AlwaysAskRules.shouldAsk(
    tier: tier,
    claimedThisCycle: claimed,
    alreadyAsked: asked,
  );

  test('asks after the first claim for a While-using user', () {
    expect(ask(), isTrue);
  });

  test('never twice, never without a claim, never for Live or Off', () {
    expect(ask(asked: true), isFalse);
    expect(ask(claimed: 0), isFalse);
    expect(ask(tier: DetectionTier.live), isFalse);
    expect(ask(tier: DetectionTier.off), isFalse);
  });
}
