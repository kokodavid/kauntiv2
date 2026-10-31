import 'package:supabase_flutter/supabase_flutter.dart';

/// Reads the dashboard's planner switch (`app_feature_flags.trip_plans`).
abstract interface class TripPlansFlagRepository {
  Future<bool> isEnabled();

  /// Whether invite links are on (`trip_plan_links`); people can always be
  /// invited by username.
  Future<bool> linksEnabled();
}

class SupabaseTripPlansFlagRepository implements TripPlansFlagRepository {
  const SupabaseTripPlansFlagRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<bool> isEnabled() => _read('trip_plans');

  @override
  Future<bool> linksEnabled() => _read('trip_plan_links');

  Future<bool> _read(String key) async {
    final row = await _client
        .from('app_feature_flags')
        .select('enabled')
        .eq('feature_key', key)
        .maybeSingle();
    return row?['enabled'] == true;
  }
}
