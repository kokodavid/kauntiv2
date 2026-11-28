import 'package:shared_preferences/shared_preferences.dart';

/// "The phone was in transit until this time", shared with the geofence
/// background isolate so a location-less geofence entry under a flight path
/// is ignored there too. Only a time, never a place (doc 05). Fails open: if
/// preferences can't be read, nothing is blocked.
class TransitFlag {
  const TransitFlag();

  static const _key = 'detection.transit_until_ms';

  Future<void> markUntil(DateTime until) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_key, until.toUtc().millisecondsSinceEpoch);
    } on Object {
      // A note only.
    }
  }

  Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } on Object {
      // A note only.
    }
  }

  Future<bool> activeAt(DateTime now) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final ms = prefs.getInt(_key);
      return ms != null && now.toUtc().millisecondsSinceEpoch < ms;
    } on Object {
      return false;
    }
  }
}
