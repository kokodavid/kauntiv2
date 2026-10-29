import 'package:supabase_flutter/supabase_flutter.dart';

/// Reads the dashboard's planner switch (`app_feature_flags.trip_plans`).
abstract interface class TripPlansFlagRepository {
  Future<bool> isEnabled();
}

class SupabaseTripPlansFlagRepository implements TripPlansFlagRepository {
  const SupabaseTripPlansFlagRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<bool> isEnabled() async {
    final row = await _client
        .from('app_feature_flags')
        .select('enabled')
        .eq('feature_key', 'trip_plans')
        .maybeSingle();
    return row?['enabled'] == true;
  }
}
