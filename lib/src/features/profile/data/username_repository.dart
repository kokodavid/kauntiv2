import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/username.dart';

abstract interface class UsernameRepository {
  /// Whether this account has picked (or confirmed) its own username.
  Future<bool> hasChosen();

  /// Free usernames, each built from a different word.
  Future<List<String>> suggest({int count = 4});

  Future<UsernameCheck> check(String handle);

  /// Saves [handle] and returns the stored username. Throws
  /// [UsernameRejectedException] or [UsernameRateLimitedException].
  Future<String> set(String handle);
}

/// The `suggest_usernames`, `check_username` and `set_username` RPCs. The
/// server owns every rule; the app only asks.
class SupabaseUsernameRepository implements UsernameRepository {
  const SupabaseUsernameRepository(this.client);

  final SupabaseClient client;

  static const _timeout = Duration(seconds: 8);

  @override
  Future<bool> hasChosen() async {
    final owner = client.auth.currentUser?.id;
    if (owner == null) return false;
    final row = await client
        .from('quest_public_profiles')
        .select('username_is_generated')
        .eq('user_id', owner)
        .maybeSingle()
        .timeout(_timeout);
    return row != null && row['username_is_generated'] == false;
  }

  @override
  Future<List<String>> suggest({int count = 4}) async {
    final result = await client
        .rpc<dynamic>('suggest_usernames', params: {'p_count': count})
        .timeout(_timeout);
    return [for (final item in result as List) item as String];
  }

  @override
  Future<UsernameCheck> check(String handle) async {
    final result = await client
        .rpc<dynamic>('check_username', params: {'p_handle': handle})
        .timeout(_timeout);
    return UsernameCheck.parse(result);
  }

  @override
  Future<String> set(String handle) async {
    try {
      final result = await client
          .rpc<dynamic>('set_username', params: {'p_handle': handle})
          .timeout(_timeout);
      final rows = result as List;
      return (rows.first as Map)['handle'] as String;
    } on PostgrestException catch (error) {
      final message = error.message;
      if (error.code == '54000') {
        final at = message.split('username_rate_limited:');
        throw UsernameRateLimitedException(
          at.length > 1 ? DateTime.tryParse(at[1].trim())?.toLocal() : null,
        );
      }
      if (message.startsWith('username_')) {
        throw UsernameRejectedException(
          UsernameCheck.parse(message.substring('username_'.length)),
        );
      }
      rethrow;
    }
  }
}
