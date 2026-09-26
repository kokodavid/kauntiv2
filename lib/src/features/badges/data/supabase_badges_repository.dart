import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/app_logger.dart';
import '../domain/badge_collection.dart';

/// The signed-in user's badges: visit state per county (`county_visits`)
/// and depth per explored county (`county_depth_ranks()`, computed from
/// the visit history). RLS keeps both to the owner.
class SupabaseBadgesRepository {
  const SupabaseBadgesRepository(this._client);

  final SupabaseClient _client;

  static const _timeout = Duration(seconds: 8);
  static const _logger = AppLogger.badges();

  Future<BadgeCollection> collection(String userId) async {
    final visitsFuture = _client
        .from('county_visits')
        .select('county_id, state')
        .eq('user_id', userId)
        .timeout(_timeout);
    final ranks = await _ranks();
    final visits = await visitsFuture;
    return BadgeCollection.from(
      visitStates: {
        for (final row in visits)
          if (row case {'county_id': final num code, 'state': final String s})
            code.toInt(): s,
      },
      ranks: ranks,
    );
  }

  /// Depth ranks; without them explored counties still show, at
  /// "Visited", rather than the whole screen failing.
  Future<Map<int, String>> _ranks() async {
    try {
      final rows = await _client
          .rpc<List<dynamic>>('county_depth_ranks')
          .timeout(_timeout);
      return {
        for (final row in rows.whereType<Map<String, dynamic>>())
          if (row case {'county_id': final num code, 'rank': final String r})
            code.toInt(): r,
      };
    } on Object catch (error, stackTrace) {
      _logger.warning(
        'Depth ranks unavailable; showing badges without depth.',
        error: error,
        stackTrace: stackTrace,
      );
      return const {};
    }
  }
}
