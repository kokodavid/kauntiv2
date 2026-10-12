import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/domain/map_place.dart';

/// Every place with a position, for finding the ones near another place.
class PlacesRepository {
  const PlacesRepository(this.client);

  final SupabaseClient client;

  Future<List<MapPlace>> all() async {
    final rows = await client
        .from('places')
        .select(
          'id, name, type, summary, county_id, lat, lng, '
          'place_images(thumbnail_url, sort_order)',
        )
        .timeout(const Duration(seconds: 8));
    return [
      for (final row in rows)
        if (row['lat'] is num && row['lng'] is num && row['county_id'] is num)
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

  static String? _firstThumbnail(Object? images) {
    if (images is! List || images.isEmpty) return null;
    final sorted = [...images.whereType<Map<String, dynamic>>()]
      ..sort(
        (a, b) => ((a['sort_order'] as num?) ?? 0).compareTo(
          (b['sort_order'] as num?) ?? 0,
        ),
      );
    return sorted.isEmpty ? null : sorted.first['thumbnail_url'] as String?;
  }
}
