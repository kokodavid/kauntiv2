import 'package:shared_preferences/shared_preferences.dart';

/// What the geofence callback needs to decide on a "record your trip"
/// reminder, kept in shared preferences because that background isolate
/// has no providers, no network and no profile. The main isolate mirrors
/// the settings (the Trip reminders switch, whether a Trip can start, the
/// recording state, when the last Trip ended); the callback reads them and
/// records when it last reminded. Every read reloads first: each isolate
/// caches its own copy.
class TripStartReminderState {
  const TripStartReminderState();

  static const _enabledKey = 'trip_start_reminder.enabled';
  static const _eligibleKey = 'trip_start_reminder.eligible';
  static const _recordingKey = 'trip_start_reminder.recording';
  static const _endedKey = 'trip_start_reminder.last_trip_ended_ms';
  static const _remindedKey = 'trip_start_reminder.last_reminded_ms';

  Future<SharedPreferences> _fresh() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    return prefs;
  }

  Future<bool> enabled() async => (await _fresh()).getBool(_enabledKey) ?? true;

  /// False until the app has confirmed this account can start a Trip.
  Future<bool> eligible() async =>
      (await _fresh()).getBool(_eligibleKey) ?? false;

  Future<bool> recording() async =>
      (await _fresh()).getBool(_recordingKey) ?? false;

  Future<DateTime?> lastTripEndedAt() => _time(_endedKey);

  Future<DateTime?> lastRemindedAt() => _time(_remindedKey);

  Future<DateTime?> _time(String key) async {
    final ms = (await _fresh()).getInt(key);
    return ms == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
  }

  Future<void> setEnabled(bool value) async =>
      (await _fresh()).setBool(_enabledKey, value);

  Future<void> setEligible(bool value) async =>
      (await _fresh()).setBool(_eligibleKey, value);

  /// A Trip started or stopped. [at] is when it stopped, for the quiet
  /// period after it.
  Future<void> setRecording(bool recording, {DateTime? at}) async {
    final prefs = await _fresh();
    await prefs.setBool(_recordingKey, recording);
    if (!recording && at != null) {
      await prefs.setInt(_endedKey, at.toUtc().millisecondsSinceEpoch);
    }
  }

  Future<void> markReminded({DateTime? now}) async => (await _fresh()).setInt(
    _remindedKey,
    (now ?? DateTime.now()).toUtc().millisecondsSinceEpoch,
  );
}
