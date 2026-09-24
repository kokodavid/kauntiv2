import 'package:shared_preferences/shared_preferences.dart';

import '../domain/arrival_nudge_rules.dart';
import '../domain/visit_models.dart';

/// Which crossings have already shown the arrival sheet, so a county still
/// being timed doesn't show it again on every foreground cycle (ported
/// from v1, same key). Main isolate only; the geofence callback never
/// touches it.
class ArrivalNudgeHistory {
  const ArrivalNudgeHistory();

  static const _shownKey = 'arrival_nudge.shown_arrival_keys';

  /// v1 keys this port no longer reads; cleared with the rest.
  static const _v1Keys = [
    'arrival_nudge.ever_visited_counties',
    'arrival_nudge.shown_visit_keys',
  ];

  /// Oldest entries drop first past this, so it never grows unbounded.
  static const maxEntries = 200;

  Future<Set<String>> shownKeys() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_shownKey) ?? const []).toSet();
  }

  Future<void> markShown(CountyArrivalNudge nudge) async {
    final prefs = await SharedPreferences.getInstance();
    final shown = [
      ...?prefs.getStringList(_shownKey),
      ArrivalNudgeRules.keyFor(nudge.countyCode, nudge.enteredAt),
    ];
    await prefs.setStringList(
      _shownKey,
      shown.length > maxEntries
          ? shown.sublist(shown.length - maxEntries)
          : shown,
    );
  }

  /// Sign-out: another account on this phone starts with a clean history.
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_shownKey);
    for (final key in _v1Keys) {
      await prefs.remove(key);
    }
  }
}
