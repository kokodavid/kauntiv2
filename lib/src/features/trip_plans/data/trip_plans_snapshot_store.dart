import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/trip_plan.dart';
import '../domain/trip_plan_summary.dart';

/// The last Planned list and each plan opened on this phone, kept per
/// account so plans stay readable offline (decision D4: read-only for
/// everyone; editing needs a connection).
class TripPlansSnapshotStore {
  const TripPlansSnapshotStore();

  static String _listKey(String userId) => 'trip_plans.list.$userId';
  static String _planKey(String userId, String planId) =>
      'trip_plans.plan.$userId.$planId';

  Future<List<TripPlanSummary>?> readList(String userId) async {
    final raw = await _read(_listKey(userId));
    final plans = raw?['plans'];
    if (plans is! List) return null;
    return [
      for (final item in plans)
        if (TripPlanSummary.fromJson(item) case final plan?) plan,
    ];
  }

  Future<void> writeList(
    String userId,
    List<TripPlanSummary> plans,
    DateTime now,
  ) => _write(_listKey(userId), {
    'saved_at': now.toIso8601String(),
    'plans': [for (final plan in plans) plan.toJson()],
  });

  Future<TripPlan?> readPlan(String userId, String planId) async {
    final raw = await _read(_planKey(userId, planId));
    return TripPlan.fromJson(raw?['plan']);
  }

  /// When [planId]'s copy was saved, for "Offline · saved copy from 9:12".
  Future<DateTime?> planSavedAt(String userId, String planId) async {
    final raw = await _read(_planKey(userId, planId));
    return DateTime.tryParse('${raw?['saved_at']}');
  }

  Future<void> writePlan(String userId, TripPlan plan, DateTime now) =>
      _write(_planKey(userId, plan.id), {
        'saved_at': now.toIso8601String(),
        'plan': plan.toJson(),
      });

  Future<void> removePlan(String userId, String planId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_planKey(userId, planId));
  }

  Future<Map<String, Object?>?> _read(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final text = prefs.getString(key);
      if (text == null) return null;
      final json = jsonDecode(text);
      return json is Map<String, Object?> ? json : null;
    } on Object {
      return null;
    }
  }

  Future<void> _write(String key, Map<String, Object?> value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, jsonEncode(value));
    } on Object {
      // A copy that can't be saved only costs the offline view.
    }
  }
}
