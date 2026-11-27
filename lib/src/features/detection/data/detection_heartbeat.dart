import 'package:shared_preferences/shared_preferences.dart';

/// When detection last ran, from either isolate: the foreground cycle and
/// the geofence background callback. Kept in shared preferences because the
/// callback has no providers; every read reloads first, since each isolate
/// caches its own copy. Only times, never places (doc 05).
class DetectionHeartbeat {
  const DetectionHeartbeat();

  static const _cycleKey = 'detection.last_cycle_ms';
  static const _geofenceKey = 'detection.last_geofence_ms';

  Future<void> markCycle([DateTime? at]) => _write(_cycleKey, at);

  Future<void> markGeofence([DateTime? at]) => _write(_geofenceKey, at);

  Future<DateTime?> lastCycle() => _read(_cycleKey);

  Future<DateTime?> lastGeofence() => _read(_geofenceKey);

  Future<void> _write(String key, DateTime? at) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        key,
        (at ?? DateTime.now()).toUtc().millisecondsSinceEpoch,
      );
    } on Object {
      // A heartbeat is a note, never a reason to fail a cycle.
    }
  }

  Future<DateTime?> _read(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final ms = prefs.getInt(key);
      return ms == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
    } on Object {
      return null;
    }
  }
}
