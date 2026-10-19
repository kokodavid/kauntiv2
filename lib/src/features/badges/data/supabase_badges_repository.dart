import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/app_logger.dart';
import '../domain/badge_collection.dart';
import '../domain/county_badge_detail.dart';
import '../domain/county_check_ins.dart';

/// The signed-in user's badges: visit state per county (`county_visits`)
/// and depth per explored county (`county_depth_ranks()`, computed from
/// the visit history). RLS keeps both to the owner.
class SupabaseBadgesRepository {
  const SupabaseBadgesRepository(this._client);

  final SupabaseClient _client;

  static const _timeout = Duration(seconds: 8);
  static const _logger = AppLogger.badges();

  /// The raw inputs of [collection], so the app can keep a copy for offline.
  Future<
    ({
      Map<int, String> visitStates,
      Map<int, String> ranks,
      DateTime? firstStampAt,
      CheckInsOverview checkIns,
    })
  >
  raw(String userId) async {
    final visitsFuture = _client
        .from('county_visits')
        .select('county_id, state, entered_at, confirmed_at')
        .eq('user_id', userId)
        .timeout(_timeout);
    final firstFuture = _firstStamp(userId);
    final overviewFuture = checkIns();
    final ranks = await _ranks();
    final visits = await visitsFuture;
    final overview = await overviewFuture;
    final firstStampAt = _earliest([
      await firstFuture,
      for (final row in visits) ..._visitDates(row),
    ]);
    return (
      firstStampAt: firstStampAt,
      checkIns: overview,
      visitStates: {
        for (final row in visits)
          if (row case {'county_id': final num code, 'state': final String s})
            code.toInt(): s,
      },
      ranks: ranks,
    );
  }

  /// Check-ins per county and whether the feature is on. A failure (an old
  /// database, no connection) reads as "off, none": Bronze to Gold stay
  /// "Later" rather than the whole load failing.
  Future<CheckInsOverview> checkIns() async {
    try {
      final row = await _client
          .rpc<Map<String, dynamic>>('my_check_in_summary')
          .timeout(_timeout);
      return CheckInsOverview(
        live: row['enabled'] == true,
        byCounty: {
          for (final entry
              in (row['counties'] as List<dynamic>? ?? const [])
                  .whereType<Map<String, dynamic>>())
            if (entry['county_id'] case final num id)
              id.toInt(): CountyCheckIns.fromJson(entry),
        },
      );
    } on Object catch (error, stackTrace) {
      _logger.warning(
        'Check-in summary unavailable.',
        error: error,
        stackTrace: stackTrace,
      );
      return CheckInsOverview.none;
    }
  }

  /// Dates on a county_visits row. The events log was backfilled from these
  /// (and only kept the latest entry per county), so the visit row can be
  /// older than anything in the log.
  static Iterable<DateTime?> _visitDates(Map<String, dynamic> row) sync* {
    for (final key in const ['confirmed_at', 'entered_at']) {
      final value = row[key];
      if (value is String) yield DateTime.tryParse(value);
    }
  }

  static DateTime? _earliest(Iterable<DateTime?> dates) {
    DateTime? best;
    for (final date in dates) {
      if (date != null && (best == null || date.isBefore(best))) best = date;
    }
    return best;
  }

  Future<BadgeCollection> collection(String userId) async {
    final data = await raw(userId);
    return BadgeCollection.from(
      visitStates: data.visitStates,
      ranks: data.ranks,
      firstStampAt: data.firstStampAt,
    );
  }

  /// When the traveller's very first stamp was earned: their earliest visit
  /// event. Null for no visits, or when it can't be read (the card then
  /// simply leaves the line out).
  Future<DateTime?> _firstStamp(String userId) async {
    try {
      final rows = await _client
          .from('county_visit_events')
          .select('entered_at')
          .eq('user_id', userId)
          .order('entered_at')
          .limit(1)
          .timeout(_timeout);
      if (rows.isEmpty) return null;
      return switch (rows.first['entered_at']) {
        final String value => DateTime.tryParse(value),
        _ => null,
      };
    } on Object catch (error, stackTrace) {
      _logger.warning(
        'First stamp date unavailable.',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
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
    final checkInsRow = await _countyCheckIns(countyCode);
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
      passCount: count('pass_count'),
      lastPassAt: at('last_pass_at'),
      lastPassStay: switch (row['last_pass_stay_seconds']) {
        final num seconds => Duration(seconds: seconds.toInt()),
        _ => null,
      },
      journeys: count('journeys'),
      journeyMeters: (row['journey_distance_m'] as num?)?.toDouble() ?? 0,
      placesTotal: count('places_total'),
      checkedInPlaces: checkInsRow.places,
      checkInDays: checkInsRow.days,
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

  Future<({List<CheckedInPlace> places, int days})> _countyCheckIns(
    int countyCode,
  ) async {
    try {
      final row = await _client
          .rpc<Map<String, dynamic>>(
            'my_county_check_ins',
            params: {'p_county_id': countyCode},
          )
          .timeout(_timeout);
      return (
        days: (row['visit_days'] as num?)?.toInt() ?? 0,
        places: [
          for (final place
              in (row['places'] as List<dynamic>? ?? const [])
                  .whereType<Map<String, dynamic>>())
            if (place case {
              'id': final String id,
              'name': final String name,
              'category': final String category,
              'visited_at': final String visitedAt,
            })
              if (DateTime.tryParse(visitedAt) case final at?)
                CheckedInPlace(
                  id: id,
                  name: name,
                  category: category,
                  visitedAt: at,
                  thumbnailUrl: place['thumbnail_url'] as String?,
                ),
        ],
      );
    } on Object catch (error, stackTrace) {
      _logger.warning(
        'County check-ins unavailable.',
        error: error,
        stackTrace: stackTrace,
      );
      return (places: const <CheckedInPlace>[], days: 0);
    }
  }
}
