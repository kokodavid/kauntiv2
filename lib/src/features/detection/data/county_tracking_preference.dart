import 'package:shared_preferences/shared_preferences.dart';

/// Whether the user turned on "Accurate county times" on this phone. Off
/// until they choose it.
class CountyTrackingPreference {
  const CountyTrackingPreference();

  static const _key = 'detection.accurate_county_times';

  Future<bool> enabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  Future<void> setEnabled(bool on) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, on);
  }
}
