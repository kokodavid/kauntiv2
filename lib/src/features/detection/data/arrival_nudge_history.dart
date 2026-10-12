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

  /// `county@shownAtIso` per county: when its sheet last showed, for the
  /// revisit cooldown.
  static const _lastShownKey = 'arrival_nudge.last_shown_by_county';

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

  /// When each county's sheet last showed.
  Future<Map<int, DateTime>> lastShownByCounty() async {
    final prefs = await SharedPreferences.getInstance();
    final out = <int, DateTime>{};
    final entries = prefs.getStringList(_lastShownKey) ?? const <String>[];
    for (final String entry in entries) {
      final parts = entry.split('@');
      if (parts.length != 2) continue;
      final code = int.tryParse(parts[0]);
      final at = DateTime.tryParse(parts[1]);
      if (code != null && at != null) out[code] = at;
    }
    return out;
  }

  Future<void> markShown(CountyArrivalNudge nudge, {DateTime? now}) async {
    final prefs = await SharedPreferences.getInstance();
    final last = await lastShownByCounty();
    last[nudge.countyCode] = (now ?? DateTime.now()).toUtc();
    await prefs.setStringList(_lastShownKey, [
      for (final e in last.entries) '${e.key}@${e.value.toIso8601String()}',
    ]);
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
    await prefs.remove(_lastShownKey);
    for (final key in _v1Keys) {
      await prefs.remove(key);
    }
  }
}
