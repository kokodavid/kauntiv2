import 'detection_status.dart';

/// The second permission ask (ADR 0001 decision 1): "While using" is asked
/// first, and "All the time" only after the first value moment, a county
/// actually claimed. Asked once; the tiers sheet stays reachable from Home.
class AlwaysAskRules {
  const AlwaysAskRules._();

  static bool shouldAsk({
    required DetectionTier tier,
    required int claimedThisCycle,
    required bool alreadyAsked,
  }) => !alreadyAsked && tier == DetectionTier.catchUp && claimedThisCycle > 0;
}
