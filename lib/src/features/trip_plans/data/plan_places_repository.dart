import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/plan_place.dart';
import '../domain/plan_place_query.dart';

/// Finds places to put in a plan.
abstract interface class PlanPlacesRepository {
  Future<List<PlanPlace>> search(PlanPlaceQuery query, {int limit = 30});
}

/// Reviewed places from `places` (any signed-in user may read them).
class SupabasePlanPlacesRepository implements PlanPlacesRepository {
  const SupabasePlanPlacesRepository(this.client);

  final SupabaseClient client;

  @override
  Future<List<PlanPlace>> search(PlanPlaceQuery query, {int limit = 30}) async {
    var request = client
        .from('places')
        .select(
          'id, name, type, county_id, lat, lng, '
          'place_images(thumbnail_url, sort_order)',
        )
        .eq('status', 'reviewed')
        .isFilter('archived_at', null);
    final county = query.countyCode;
    if (county != null) request = request.eq('county_id', county);
    final type = query.type;
    if (type != null) request = request.eq('type', type);
    final text = query.text.trim().replaceAll(RegExp(r'[%_,()*\\]'), ' ');
    if (text.length >= 2) request = request.ilike('name', '%$text%');
    final rows = await request
        .order('name')
        .limit(limit)
        .timeout(const Duration(seconds: 8));
    return [
      for (final row in rows)
        if (row['county_id'] is num)
          PlanPlace(
            id: row['id'] as String,
            name: row['name'] as String,
            type: row['type'] is String ? row['type'] as String : '',
            countyCode: (row['county_id'] as num).toInt(),
            lat: row['lat'] is num ? (row['lat'] as num).toDouble() : null,
            lng: row['lng'] is num ? (row['lng'] as num).toDouble() : null,
            thumbnailUrl: _thumbnail(row['place_images']),
          ),
    ];
  }

  static String? _thumbnail(Object? images) {
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
