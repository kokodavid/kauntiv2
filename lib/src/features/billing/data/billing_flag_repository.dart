import 'package:supabase_flutter/supabase_flutter.dart';

/// Reads the dashboard's "billing" switch (app_feature_flags). Anyone may
/// read it, signed in or not.
abstract interface class BillingFlagRepository {
  Future<bool> isEnabled();
}

class SupabaseBillingFlagRepository implements BillingFlagRepository {
  const SupabaseBillingFlagRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<bool> isEnabled() async {
    final row = await _client
        .from('app_feature_flags')
        .select('enabled')
        .eq('feature_key', 'billing')
        .maybeSingle();
    return row?['enabled'] == true;
  }
}
