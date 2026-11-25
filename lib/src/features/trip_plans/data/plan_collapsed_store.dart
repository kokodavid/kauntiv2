import 'package:shared_preferences/shared_preferences.dart';

/// Which days of a plan are folded, kept per plan on this phone.
class PlanCollapsedStore {
  const PlanCollapsedStore();

  static String _key(String planId) => 'trip_plans.collapsed.$planId';

  /// Null when nothing was ever folded or opened for [planId].
  Future<Set<int>?> read(String planId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList(_key(planId));
      if (saved == null) return null;
      return {for (final value in saved) ?int.tryParse(value)};
    } on Object {
      return null;
    }
  }

  Future<void> write(String planId, Set<int> days) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_key(planId), [for (final n in days) '$n']);
    } on Object {
      // Folding only lasts this visit if it can't be saved.
    }
  }
}
