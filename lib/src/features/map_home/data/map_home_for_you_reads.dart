import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../counties/county_paths.dart';
import '../domain/map_home_models.dart';
import '../domain/map_home_promotion.dart';

/// Reads a Supabase call that may fail on an older database; null then.
typedef ReadOptional = Future<T?> Function<T>(
  Future<T> Function() read, {
  required String label,
});

/// County facts For You needs per county code.
typedef CountyCardFacts = ({
  num? areaKm2,
  num? elevationM,
  int? durationMinutes,
  String? highlightImageUrl,
});

/// For You's promoted place and "Nearby and unclaimed" row.
class MapHomeForYouReads {
  const MapHomeForYouReads(this.client, this.readOptional);

  final SupabaseClient client;
  final ReadOptional readOptional;

  static const _timeout = Duration(seconds: 8);

  /// How many unclaimed counties the row shows.
  static const unclaimedRowLength = 10;

  /// The active `for_you` promotion with the highest priority (RLS only
  /// returns rows inside their start/end window and not deactivated).
  Future<MapHomePromotedPlace?> promotion() async {
    final rows = await readOptional<List<dynamic>>(
      () => client
          .from('place_promotions')
          .select(
            'disclosure_label, sponsor_name, priority, starts_at, '
            'places(id, name, county_id, summary, lat, lng, area_km2, '
            'elevation_m, visit_duration_minutes, '
            'place_images(image_url, thumbnail_url, sort_order))',
          )
          .eq('placement', 'for_you')
          .order('priority', ascending: false)
          .order('starts_at', ascending: false)
          .limit(5)
          .timeout(_timeout),
      label: 'for_you promotion',
    );
    for (final raw in rows ?? const <dynamic>[]) {
      final place = raw is Map ? raw['places'] : null;
      if (place is! Map) continue;
      final county = CountyPaths.byCode[(place['county_id'] as num?)?.toInt()];
      if (county == null) continue;
      return MapHomePromotedPlace(
        placeId: place['id'] as String,
        placeName: place['name'] as String,
        county: county,
        disclosureLabel: (raw as Map)['disclosure_label'] as String? ?? 'AD',
        sponsorName: raw['sponsor_name'] as String? ?? '',
        summary: place['summary'] as String?,
        photoUrl: _firstImage(place['place_images']),
        latitude: (place['lat'] as num?)?.toDouble(),
        longitude: (place['lng'] as num?)?.toDouble(),
        areaKm2: (place['area_km2'] as num?)?.toDouble(),
        elevationM: (place['elevation_m'] as num?)?.toInt(),
        visitDurationMinutes: (place['visit_duration_minutes'] as num?)
            ?.toInt(),
      );
    }
    return null;
  }

  /// Every unclaimed county, nearest first (the RPC anchors on the last
  /// visited or home county). Returns the row's first few plus the total.
  Future<({List<MapHomeSuggestion> row, int total})> unclaimed(
    Map<int, CountyCardFacts> facts,
    String Function(num? meters) distanceLabel,
  ) async {
    final rows = await readOptional<List<dynamic>>(
      () => client
          .rpc<List<dynamic>>('discover_unclaimed_counties')
          .timeout(_timeout),
      label: 'unclaimed counties',
    );
    final known = [
      for (final raw in rows ?? const <dynamic>[])
        if (raw is Map && CountyPaths.byCode.containsKey(raw['county_id']))
          raw,
    ]..sort((a, b) => _distance(a).compareTo(_distance(b)));

    return (
      total: known.length,
      row: [
        for (final raw in known.take(unclaimedRowLength))
          _unclaimedCard(raw, facts, distanceLabel),
      ],
    );
  }

  MapHomeSuggestion _unclaimedCard(
    Map<dynamic, dynamic> raw,
    Map<int, CountyCardFacts> facts,
    String Function(num? meters) distanceLabel,
  ) {
    final code = (raw['county_id'] as num).toInt();
    final meters = raw['distance_m'] as num?;
    return MapHomeSuggestion(
      county: CountyPaths.byCode[code]!,
      reason: MapHomeSuggestionReason.unclaimed,
      distanceAway: distanceLabel(meters),
      isNear: (meters ?? double.infinity) < 80000,
      areaKm2: facts[code]?.areaKm2?.toDouble(),
      elevationM: facts[code]?.elevationM?.toInt(),
      visitDurationMinutes: facts[code]?.durationMinutes,
      highlightImageUrl: facts[code]?.highlightImageUrl,
    );
  }

  static num _distance(Map<dynamic, dynamic> raw) =>
      (raw['distance_m'] as num?) ?? double.infinity;

  static String? _firstImage(Object? images) {
    if (images is! List || images.isEmpty) return null;
    final sorted = [...images.whereType<Map<dynamic, dynamic>>()]
      ..sort(
        (a, b) => ((a['sort_order'] as num?) ?? 0).compareTo(
          (b['sort_order'] as num?) ?? 0,
        ),
      );
    if (sorted.isEmpty) return null;
    return (sorted.first['image_url'] ?? sorted.first['thumbnail_url'])
        as String?;
  }
}
