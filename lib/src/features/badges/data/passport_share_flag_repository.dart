import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Reads the dashboard's "passport_share" switch (app_feature_flags).
abstract interface class PassportShareFlagRepository {
  /// The live value; throws when it can't be read (offline, timeout).
  Future<bool> isEnabled();

  /// The last value read successfully, or null when there never was one.
  Future<bool?> lastKnown();
}

class SupabasePassportShareFlagRepository
    implements PassportShareFlagRepository {
  const SupabasePassportShareFlagRepository(this._client);

  final SupabaseClient _client;

  static const _key = 'passport_share.enabled';

  @override
  Future<bool> isEnabled() async {
    final row = await _client
        .from('app_feature_flags')
        .select('enabled')
        .eq('feature_key', 'passport_share')
        .maybeSingle();
    final enabled = row?['enabled'] == true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, enabled);
    } on Object {
      // Remembering it is a nicety; the live value still stands.
    }
    return enabled;
  }

  @override
  Future<bool?> lastKnown() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_key);
    } on Object {
      return null;
    }
  }
}
