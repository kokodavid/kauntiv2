import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../counties/county_paths.dart';
import '../../../services/app_logger.dart';
import '../domain/map_home_models.dart';
import '../domain/map_place.dart';
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
    final countyFacts = await _countyFacts();
    final visits = await _visits(userId);
    final badges = [
      for (final county in CountyPaths.all)
        MapHomeCountyBadge(
          county: county,
          state: _stateFor(visits[county.code]),
          areaKm2: countyFacts[county.code]?.areaKm2,
          elevationM: countyFacts[county.code]?.elevationM,
          durationMinutes: countyFacts[county.code]?.durationMinutes,
        ),
    ];
    final exploredCount = badges
        .where((badge) => badge.state == MapHomeCountyBadgeState.earned)
        .length;

    return MapHomeBoardData(
      tierLabel: _tierLabelFor(exploredCount),
      totalCounties: CountyPaths.all.length,
      homeCounty: resolvedHomeCounty,
      countyBadges: badges,
      suggestions: await _suggestions(countyFacts),
    );
  }

  @override
  Future<List<MapPlace>> loadMapPlaces() async {
    final rows = await client
        .from('places')
        .select(
          'id, name, type, summary, county_id, lat, lng, '
          'place_images(thumbnail_url, sort_order)',
        )
        .timeout(const Duration(seconds: 8));
    return [
      for (final row in rows)
        if (row['lat'] is num && row['lng'] is num)
          MapPlace(
            id: row['id'] as String,
            name: row['name'] as String,
            type: row['type'] as String,
            countyCode: (row['county_id'] as num).toInt(),
            lat: (row['lat'] as num).toDouble(),
            lng: (row['lng'] as num).toDouble(),
            summary: row['summary'] as String?,
            thumbnailUrl: _firstThumbnail(row['place_images']),
          ),
    ];
  }

  String? _firstThumbnail(Object? images) {
    if (images is! List || images.isEmpty) return null;
    final sorted = [...images.whereType<Map<String, dynamic>>()]
      ..sort(
        (a, b) => ((a['sort_order'] as num?) ?? 0).compareTo(
          (b['sort_order'] as num?) ?? 0,
        ),
      );
    return sorted.isEmpty ? null : sorted.first['thumbnail_url'] as String?;
  }

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

  Future<Map<int, _CountyFactRow>> _countyFacts() async {
    final rows = await _readOptional<List<dynamic>>(
      () => client
        .from('counties')
          .select('id, area_km2, elevation_m, duration_minutes, highlight_image_url')
          .timeout(const Duration(seconds: 8)),
      label: 'county facts',
    );

    if (rows == null) return const {};

    return {
      for (final raw in rows)
        if ((raw as Map)['id'] != null)
          raw['id'] as int: _CountyFactRow(
            areaKm2: raw['area_km2'] as num?,
            elevationM: raw['elevation_m'] as num?,
            durationMinutes: (raw['duration_minutes'] as num?)?.toInt(),
            highlightImageUrl: raw['highlight_image_url'] as String?,
          ),
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

  Future<List<MapHomeSuggestion>> _suggestions(
    Map<int, _CountyFactRow> countyFacts,
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
            areaKm2: (raw['area_km2'] as num?)?.toDouble(),
            elevationM: (raw['elevation_m'] as num?)?.toInt(),
            visitDurationMinutes:
                (raw['visit_duration_minutes'] as num?)?.toInt(),
            highlightImageUrl:
                countyFacts[raw['county_id'] as int]?.highlightImageUrl,
          ),
    ];
  }

  Future<List<dynamic>> _suggestionRows() async {
    final currentShape = await _readOptional<List<dynamic>>(
      () async {
        final rows = await client
            .rpc(
              'for_you_candidates',
              params: const {'p_latitude': null, 'p_longitude': null},
            )
            .timeout(const Duration(seconds: 8));
        return rows as List<dynamic>;
      },
      label: 'for_you_candidates current shape',
    );
    if (currentShape != null) return currentShape;

    final legacyShape = await _readOptional<List<dynamic>>(
      () async {
        final rows = await client
            .rpc('for_you_candidates')
            .timeout(const Duration(seconds: 8));
        return rows as List<dynamic>;
      },
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

  String _tierLabelFor(int exploredCount) {
    if (exploredCount >= 47) return 'MKENYA HALISI';
    if (exploredCount >= 25) return 'MZURURAJI';
    if (exploredCount >= 10) return 'MSAFIRI';
    return 'MGENI';
  }
}

class _CountyFactRow {
  const _CountyFactRow({
    required this.areaKm2,
    required this.elevationM,
    required this.durationMinutes,
    required this.highlightImageUrl,
  });

  final num? areaKm2;
  final num? elevationM;
  final int? durationMinutes;
  final String? highlightImageUrl;
}
