import 'package:shared_preferences/shared_preferences.dart';

import '../../journeys/domain/pro_status.dart';

/// The last Pro status the server confirmed for an account on this phone.
/// Used for ads only, so an offline start does not guess. Trips keep their
/// own strict live check.
abstract interface class AdsProCache {
  Future<ProStatus?> read(String owner);
  Future<void> write(String owner, ProStatus status);
}

class SharedPreferencesAdsProCache implements AdsProCache {
  const SharedPreferencesAdsProCache();

  static String _key(String owner, String field) => 'ads.pro.$field.$owner';

  @override
  Future<ProStatus?> read(String owner) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final active = prefs.getBool(_key(owner, 'active'));
      final checked = prefs.getInt(_key(owner, 'checked'));
      if (active == null || checked == null) return null;
      final until = prefs.getInt(_key(owner, 'until'));
      return ProStatus(
        active: active,
        checkedAt: DateTime.fromMillisecondsSinceEpoch(checked, isUtc: true),
        activeUntil: until == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(until, isUtc: true),
      );
    } on Object {
      return null;
    }
  }

  @override
  Future<void> write(String owner, ProStatus status) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key(owner, 'active'), status.active);
      await prefs.setInt(
        _key(owner, 'checked'),
        status.checkedAt.millisecondsSinceEpoch,
      );
      final until = status.activeUntil;
      if (until == null) {
        await prefs.remove(_key(owner, 'until'));
      } else {
        await prefs.setInt(_key(owner, 'until'), until.millisecondsSinceEpoch);
      }
    } on Object {
      // Worst case the next start shows no ads until Pro is checked.
    }
  }
}
