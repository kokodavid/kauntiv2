import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/domain/county_tier.dart';
import '../../../core/domain/map_place.dart';
import '../../../counties/county_paths.dart';
import '../../../services/app_logger.dart';
import '../domain/map_home_models.dart';
import 'map_home_county_reads.dart';
import 'map_home_for_you_reads.dart';
import 'map_home_place_reads.dart';
import 'map_home_repository.dart';

class SupabaseMapHomeRepository implements MapHomeRepository {
  const SupabaseMapHomeRepository(this.client);

  final SupabaseClient client;
  static const _logger = AppLogger.mapHome();

  @override
  Future<MapHomeBoardData> loadBoard({CountyPath? homeCounty}) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Map Home requires a signed-in user.');
    }

    final resolvedHomeCounty = await _homeCounty(userId, fallback: homeCounty);
    final countyReads = MapHomeCountyReads(client, _readOptional);
    final (countyFacts, visits, headquarters, placeNames) = await (
      _countyFacts(),
      _visits(userId),
      countyReads.headquarters(),
      countyReads.placeNames(),
    ).wait;
    final badges = [
      for (final county in CountyPaths.all)
        MapHomeCountyBadge(
          county: county,
          state: _stateFor(visits[county.code]),
          areaKm2: countyFacts[county.code]?.areaKm2,
          elevationM: countyFacts[county.code]?.elevationM,
          durationMinutes: countyFacts[county.code]?.durationMinutes,
          highlightImageUrl: countyFacts[county.code]?.highlightImageUrl,
          headquarters: headquarters[county.code],
          placeNames: placeNames[county.code] ?? const [],
        ),
    ];
    final exploredCount = badges
        .where((badge) => badge.state == MapHomeCountyBadgeState.earned)
        .length;

    final forYou = MapHomeForYouReads(client, _readOptional);
    final (suggestions, promotion, unclaimed, lastClaim) = await (
      _suggestions(countyFacts),
      forYou.promotion(),
      forYou.unclaimed(countyFacts, _distanceLabel),
      _lastClaim(userId),
    ).wait;

    return MapHomeBoardData(
      tier: CountyTier.forClaimed(exploredCount),
      totalCounties: CountyPaths.all.length,
      homeCounty: resolvedHomeCounty,
      countyBadges: badges,
      suggestions: suggestions,
      promotion: promotion,
      unclaimed: unclaimed.row,
      unclaimedCount: unclaimed.total,
      lastClaim: lastClaim,
    );
  }

  @override
  Future<List<MapPlace>> loadMapPlaces() =>
      MapHomePlaceReads(client).loadMapPlaces();

  Future<CountyPath?> _homeCounty(
    String userId, {
    required CountyPath? fallback,
  }) async {
    final row = await _readOptional<Map<String, dynamic>?>(
      () => client
          .from('profiles')
          .select('home_county_id, home_county_slug')
          .eq('id', userId)
          .maybeSingle()
          .timeout(const Duration(seconds: 8)),
      label: 'profile home county',
    );

    final slug = row?['home_county_slug'] as String?;
    if (slug != null && CountyPaths.bySlug.containsKey(slug)) {
      return CountyPaths.bySlug[slug];
    }

    final code = row?['home_county_id'] as int?;
    if (code != null && CountyPaths.byCode.containsKey(code)) {
      return CountyPaths.byCode[code];
    }

    return fallback;
  }

  /// Photos and facts are read separately: they come from different
  /// migrations, and a dev database missing one fact column shouldn't also
  /// drop every county photo from the For You cards.
  Future<Map<int, CountyCardFacts>> _countyFacts() async {
    final results = await Future.wait([
      _readCountyColumns('id, highlight_image_url', label: 'county photos'),
      _readCountyColumns(
        'id, area_km2, elevation_m, duration_minutes',
        label: 'county facts',
      ),
    ]);
    final photos = results[0];
    final facts = results[1];

    return {
      for (final id in {...photos.keys, ...facts.keys})
        id: (
          areaKm2: facts[id]?['area_km2'] as num?,
          elevationM: facts[id]?['elevation_m'] as num?,
          durationMinutes: (facts[id]?['duration_minutes'] as num?)?.toInt(),
          highlightImageUrl: photos[id]?['highlight_image_url'] as String?,
        ),
    };
  }

  Future<Map<int, Map<dynamic, dynamic>>> _readCountyColumns(
    String columns, {
    required String label,
  }) async {
    final rows = await _readOptional<List<dynamic>>(
      () => client
          .from('counties')
          .select(columns)
          .timeout(const Duration(seconds: 8)),
      label: label,
    );
    return {
      for (final raw in rows ?? const <dynamic>[])
        if (raw is Map && raw['id'] is num) (raw['id'] as num).toInt(): raw,
    };
  }

  Future<Map<int, String>> _visits(String userId) async {
    final rows = await client
        .from('county_visits')
        .select('county_id, state')
        .eq('user_id', userId)
        .timeout(const Duration(seconds: 8));

    return {
      for (final raw in rows)
        if ((raw as Map)['county_id'] != null && raw['state'] != null)
          raw['county_id'] as int: raw['state'] as String,
    };
  }

  /// The newest county that became explored, by `confirmed_at`. Optional:
  /// without it Home just never celebrates.
  Future<MapHomeClaim?> _lastClaim(String userId) async {
    final rows = await _readOptional<List<dynamic>>(
      () => client
          .from('county_visits')
          .select('county_id, confirmed_at')
          .eq('user_id', userId)
          .eq('state', 'explored')
          .not('confirmed_at', 'is', null)
          .order('confirmed_at', ascending: false)
          .limit(1)
          .timeout(const Duration(seconds: 8)),
      label: 'latest county claim',
    );
    final row = rows?.firstOrNull;
    if (row is! Map) return null;
    final county = CountyPaths.byCode[(row['county_id'] as num?)?.toInt()];
    final at = DateTime.tryParse('${row['confirmed_at']}');
    if (county == null || at == null) return null;
    return MapHomeClaim(county: county, claimedAt: at);
  }

  Future<List<MapHomeSuggestion>> _suggestions(
    Map<int, CountyCardFacts> countyFacts,
  ) async {
    final rows = await _suggestionRows();

    return [
      for (final raw in rows)
        if (CountyPaths.byCode[(raw as Map)['county_id'] as int?] != null)
          MapHomeSuggestion(
            county: CountyPaths.byCode[raw['county_id'] as int]!,
            reason: _suggestionReason(raw['reason'] as String?),
            distanceAway: _distanceLabel(raw['distance_m'] as num?),
            isNear: ((raw['distance_m'] as num?) ?? double.infinity) < 80000,
            placeName: raw['place_name'] as String?,
            // A place suggestion shows the place's own stats; a county
            // suggestion shows the county's (never a mix of the two).
            areaKm2: raw['place_name'] == null
                ? countyFacts[raw['county_id'] as int]?.areaKm2?.toDouble()
                : (raw['area_km2'] as num?)?.toDouble(),
            elevationM: raw['place_name'] == null
                ? countyFacts[raw['county_id'] as int]?.elevationM?.toInt()
                : (raw['elevation_m'] as num?)?.toInt(),
            visitDurationMinutes: raw['place_name'] == null
                ? countyFacts[raw['county_id'] as int]?.durationMinutes
                : (raw['visit_duration_minutes'] as num?)?.toInt(),
            highlightImageUrl:
                countyFacts[raw['county_id'] as int]?.highlightImageUrl,
          ),
    ];
  }

  Future<List<dynamic>> _suggestionRows() async {
    final currentShape = await _readOptional<List<dynamic>>(
      () => client
          .rpc<List<dynamic>>(
            'for_you_candidates',
            params: const {'p_latitude': null, 'p_longitude': null},
          )
          .timeout(const Duration(seconds: 8)),
      label: 'for_you_candidates current shape',
    );
    if (currentShape != null) return currentShape;

    final legacyShape = await _readOptional<List<dynamic>>(
      () => client
          .rpc<List<dynamic>>('for_you_candidates')
          .timeout(const Duration(seconds: 8)),
      label: 'for_you_candidates legacy shape',
    );
    return legacyShape ?? const [];
  }

  Future<T?> _readOptional<T>(
    Future<T> Function() read, {
    required String label,
  }) async {
    try {
      return await read();
    } catch (error, stackTrace) {
      _logger.warning(
        'Skipping optional Map Home data: $label.',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  MapHomeCountyBadgeState _stateFor(String? state) {
    return switch (state) {
      'explored' => MapHomeCountyBadgeState.earned,
      'passed_through' => MapHomeCountyBadgeState.passedThrough,
      'pending' => MapHomeCountyBadgeState.pending,
      _ => MapHomeCountyBadgeState.locked,
    };
  }

  MapHomeSuggestionReason _suggestionReason(String? reason) {
    return switch (reason) {
      'depth_progress' => MapHomeSuggestionReason.depthRank,
      'saved' => MapHomeSuggestionReason.savedHere,
      _ => MapHomeSuggestionReason.unclaimed,
    };
  }

  String _distanceLabel(num? meters) {
    if (meters == null) return 'Nearby';
    final km = meters / 1000;
    if (km < 10) return '${km.toStringAsFixed(1)} km away';
    return '${km.round()} km away';
  }
}
