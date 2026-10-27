import 'package:supabase_flutter/supabase_flutter.dart';

/// Reads the dashboard's "ads" switch (app_feature_flags). Anyone may read
/// it, signed in or not.
abstract interface class AdsFlagRepository {
  Future<bool> isEnabled();
}

class SupabaseAdsFlagRepository implements AdsFlagRepository {
  const SupabaseAdsFlagRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<bool> isEnabled() async {
    final row = await _client
        .from('app_feature_flags')
        .select('enabled')
        .eq('feature_key', 'ads')
        .maybeSingle();
    return row?['enabled'] == true;
  }
}
