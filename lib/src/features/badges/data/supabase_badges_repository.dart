import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/app_logger.dart';
import '../domain/badge_collection.dart';
import '../domain/county_badge_detail.dart';

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

  /// One county's badge in detail (`county_badge_detail`).
  Future<CountyBadgeDetail> detail(int countyCode) async {
    final row = await _client
        .rpc<Map<String, dynamic>>(
          'county_badge_detail',
          params: {'p_county_id': countyCode},
        )
        .timeout(_timeout);
    int count(String key) => (row[key] as num?)?.toInt() ?? 0;
    DateTime? at(String key) => switch (row[key]) {
      final String value => DateTime.parse(value),
      _ => null,
    };
    return CountyBadgeDetail(
      earnedAt: at('earned_at'),
      exploredVisits: count('explored_visits'),
      exploredMonths: count('explored_months'),
      lastVisitedAt: at('last_visited_at'),
      journeys: count('journeys'),
      journeyMeters: (row['journey_distance_m'] as num?)?.toDouble() ?? 0,
      suggestedPlaces: [
        for (final place
            in (row['suggested_places'] as List<dynamic>? ?? const [])
                .whereType<Map<String, dynamic>>())
          if (place case {
            'id': final String id,
            'name': final String name,
            'type': final String type,
          })
            BadgeSuggestedPlace(
              id: id,
              name: name,
              type: type,
              summary: place['summary'] as String?,
              latitude: (place['lat'] as num?)?.toDouble(),
              longitude: (place['lng'] as num?)?.toDouble(),
              thumbnailUrl: place['thumbnail_url'] as String?,
              saved: place['saved'] == true,
            ),
      ],
    );
  }
}
