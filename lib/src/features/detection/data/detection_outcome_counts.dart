import 'package:shared_preferences/shared_preferences.dart';

import '../domain/detection_health_report.dart';

/// Running totals of [DetectionOutcome]s since the last health report, in
/// shared preferences so the geofence background isolate and the app add to
/// the same numbers. Counts only; never a place or a time of day.
class DetectionOutcomeCounts {
  const DetectionOutcomeCounts();

  static String _key(DetectionOutcome o) => 'detection.outcome.${o.wireName}';

  Future<void> add(DetectionOutcome outcome, [int by = 1]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      await prefs.setInt(
        _key(outcome),
        (prefs.getInt(_key(outcome)) ?? 0) + by,
      );
    } on Object {
      // A count is a note, never a reason to fail detection.
    }
  }

  /// The current totals, keyed by wire name (zeros left out).
  Future<Map<String, int>> snapshot() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      return {
        for (final o in DetectionOutcome.values)
          if ((prefs.getInt(_key(o)) ?? 0) > 0)
            o.wireName: prefs.getInt(_key(o))!,
      };
    } on Object {
      return const {};
    }
  }

  /// Takes [sent] off the totals once a report went out, so anything
  /// counted meanwhile goes in the next one.
  Future<void> subtract(Map<String, int> sent) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      for (final o in DetectionOutcome.values) {
        final taken = sent[o.wireName];
        if (taken == null) continue;
        final left = (prefs.getInt(_key(o)) ?? 0) - taken;
        await prefs.setInt(_key(o), left < 0 ? 0 : left);
      }
    } on Object {
      // Left as is: the next report just carries a few extra.
    }
  }
}
