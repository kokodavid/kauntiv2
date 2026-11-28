import 'package:shared_preferences/shared_preferences.dart';

import '../domain/always_ask_rules.dart';
import '../domain/detection_status.dart';

/// Whether the one-time "all the time" ask after the first claimed county
/// has been shown on this phone.
class AlwaysAskState {
  const AlwaysAskState();

  static const _key = 'detection.always_ask.shown';

  Future<bool> shown() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_key) ?? false;
    } on Object {
      // Can't tell: don't ask, rather than ask on every claim.
      return true;
    }
  }

  Future<void> markShown() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, true);
    } on Object {
      // Worst case the ask shows once more.
    }
  }

  /// True once, when the second ask is due; marks it shown so it never
  /// repeats.
  Future<bool> take({required DetectionTier tier, required int claimed}) async {
    if (!AlwaysAskRules.shouldAsk(
      tier: tier,
      claimedThisCycle: claimed,
      alreadyAsked: await shown(),
    )) {
      return false;
    }
    await markShown();
    return true;
  }
}
