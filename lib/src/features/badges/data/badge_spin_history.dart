import 'package:shared_preferences/shared_preferences.dart';

/// Which earned badges this account has already opened (their coin spun),
/// so the spin is a first-open moment rather than every time. On this
/// phone only; losing it just means a badge spins once more.
class BadgeSpinHistory {
  const BadgeSpinHistory();

  static String _key(String userId) => 'badges.spun_counties.$userId';

  /// True the first time [countyCode] is asked about for [userId], and
  /// records it so later calls are false.
  Future<bool> claimFirstSpin(String userId, int countyCode) async {
    final prefs = await SharedPreferences.getInstance();
    final spun = prefs.getStringList(_key(userId)) ?? const [];
    final code = '$countyCode';
    if (spun.contains(code)) return false;
    await prefs.setStringList(_key(userId), [...spun, code]);
    return true;
  }
}
