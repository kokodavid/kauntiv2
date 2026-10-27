import 'package:shared_preferences/shared_preferences.dart';

import '../domain/arrival_nudge_rules.dart';
import '../domain/visit_models.dart';

/// What the geofence callback needs to decide on an arrival notification,
/// kept in shared preferences because that background isolate has no
/// providers, no network and no profile. The main isolate writes the
/// mirrored settings (home county, the `notify_county_nudges` switch, the
/// foreground heartbeat); the callback reads them and records what it
/// notified. Every read reloads first: each isolate caches its own copy.
class ArrivalNotificationState {
  const ArrivalNotificationState();

  static const _enabledKey = 'arrival_notify.enabled';
  static const _homeKey = 'arrival_notify.home_county';
  static const _foregroundKey = 'arrival_notify.foreground_at_ms';
  static const _askedKey = 'arrival_notify.permission_asked';
  // The old key held a permanent flag; the card now snoozes instead, so
  // everyone who had dismissed it for good sees it again.
  static const _legacyDismissedKey = 'arrival_notify.home_prompt_dismissed';
  static const _promptSnoozedKey = 'arrival_notify.home_prompt_snoozed_at_ms';

  /// How long a dismissed card stays away while notifications are still off.
  static const promptSnooze = Duration(days: 3);
  static const _notifiedKey = 'arrival_notify.notified_keys';
  static const _lastNotifiedKey = 'arrival_notify.last_notified_by_county';

  /// The foreground cycle beats every 15 s; a heartbeat older than this
  /// means the app was killed without saying it left.
  static const foregroundWindow = Duration(seconds: 45);

  static const maxEntries = 200;

  Future<SharedPreferences> _fresh() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    return prefs;
  }

  Future<bool> enabled() async => (await _fresh()).getBool(_enabledKey) ?? true;

  Future<int?> homeCounty() async => (await _fresh()).getInt(_homeKey);

  Future<bool> permissionAsked() async =>
      (await _fresh()).getBool(_askedKey) ?? false;

  /// True while the app is in front: the sheet covers that case, so the
  /// callback stays quiet.
  Future<bool> inForeground({DateTime? now}) async {
    final ms = (await _fresh()).getInt(_foregroundKey) ?? 0;
    if (ms == 0) return false;
    final beat = DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
    return (now ?? DateTime.now()).toUtc().difference(beat) < foregroundWindow;
  }

  Future<Set<String>> notifiedKeys() async =>
      ((await _fresh()).getStringList(_notifiedKey) ?? const []).toSet();

  Future<Map<int, DateTime>> lastNotifiedByCounty() async {
    final out = <int, DateTime>{};
    final entries =
        (await _fresh()).getStringList(_lastNotifiedKey) ?? const <String>[];
    for (final entry in entries) {
      final parsed = ArrivalNudgeRules.parseKey(entry);
      if (parsed != null) out[parsed.countyCode] = parsed.enteredAt;
    }
    return out;
  }

  Future<void> setEnabled(bool value) async =>
      (await _fresh()).setBool(_enabledKey, value);

  Future<void> setHomeCounty(int? code) async {
    final prefs = await _fresh();
    if (code == null) {
      await prefs.remove(_homeKey);
    } else {
      await prefs.setInt(_homeKey, code);
    }
  }

  /// A beat while in front; [foreground] false when the app leaves it.
  Future<void> setForeground(bool foreground, {DateTime? now}) async {
    final prefs = await _fresh();
    await prefs.setInt(
      _foregroundKey,
      foreground ? (now ?? DateTime.now()).toUtc().millisecondsSinceEpoch : 0,
    );
  }

  Future<void> markPermissionAsked() async =>
      (await _fresh()).setBool(_askedKey, true);

  /// Home's "turn on notifications" card was dismissed recently. It comes
  /// back after [promptSnooze] for as long as notifications stay off.
  Future<bool> promptDismissed({DateTime? now}) async {
    final ms = (await _fresh()).getInt(_promptSnoozedKey);
    if (ms == null) return false;
    final at = DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
    return (now ?? DateTime.now()).toUtc().difference(at) < promptSnooze;
  }

  Future<void> dismissPrompt({DateTime? now}) async => (await _fresh()).setInt(
    _promptSnoozedKey,
    (now ?? DateTime.now()).toUtc().millisecondsSinceEpoch,
  );

  /// Records a posted notification: the crossing key (so it never repeats)
  /// and when the county last notified (the revisit cooldown). The sheet's
  /// own history is untouched, so opening the app still shows the sheet.
  Future<void> markNotified(CountyArrivalNudge nudge, {DateTime? now}) async {
    final prefs = await _fresh();
    final last = await lastNotifiedByCounty();
    last[nudge.countyCode] = (now ?? DateTime.now()).toUtc();
    await prefs.setStringList(_lastNotifiedKey, [
      for (final e in last.entries) ArrivalNudgeRules.keyFor(e.key, e.value),
    ]);
    final keys = [
      ...?prefs.getStringList(_notifiedKey),
      ArrivalNudgeRules.keyFor(nudge.countyCode, nudge.enteredAt),
    ];
    await prefs.setStringList(
      _notifiedKey,
      keys.length > maxEntries ? keys.sublist(keys.length - maxEntries) : keys,
    );
  }

  /// Sign-out: the next account starts clean.
  Future<void> clear() async {
    final prefs = await _fresh();
    for (final key in [
      _enabledKey,
      _homeKey,
      _foregroundKey,
      _askedKey,
      _legacyDismissedKey,
      _promptSnoozedKey,
      _notifiedKey,
      _lastNotifiedKey,
    ]) {
      await prefs.remove(key);
    }
  }
}
