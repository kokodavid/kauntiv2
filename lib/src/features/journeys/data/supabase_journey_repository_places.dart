part of 'supabase_journey_repository.dart';

/// Every place with coordinates, marked saved when on [userId]'s list.
Future<List<JourneyPlaceMark>> _journeyPlaces(
  SupabaseClient client,
  Duration timeout,
  String userId,
) async {
  final results = await Future.wait<List<Map<String, dynamic>>>([
    SupabaseJourneyRepository.readAllPages(
      (from, to) => client
          .from('places')
          .select(
            'id, county_id, name, type, summary, lat, lng, '
            'place_images(thumbnail_url, sort_order)',
          )
          .not('lat', 'is', null)
          .order('id', ascending: true)
          .range(from, to)
          .timeout(timeout),
    ),
    client
        .from('wishlist_items')
        .select('place_id')
        .eq('user_id', userId)
        .timeout(timeout),
  ]);
  final saved = {for (final row in results[1]) row['place_id']};
  return [
    for (final row in results[0])
      if (row case {
        'id': final String id,
        'county_id': final int county,
        'name': final String name,
        'lat': final num lat,
        'lng': final num lng,
      })
        JourneyPlaceMark(
          id: id,
          countyCode: county,
          name: name,
          latitude: lat.toDouble(),
          longitude: lng.toDouble(),
          saved: saved.contains(id),
          categoryLabel: row['type'] as String?,
          description: row['summary'] as String?,
          thumbnailUrl: journeyPlaceThumbnail(row['place_images']),
        ),
  ];
}

/// Every place with coordinates, as map pins for the recording map.
Future<List<MapPlace>> _journeyMapPlaces(
  SupabaseClient client,
  Duration timeout,
) async {
  final rows = await SupabaseJourneyRepository.readAllPages(
    (from, to) => client
        .from('places')
        .select(
          'id, name, type, summary, county_id, lat, lng, '
          'place_images(thumbnail_url, sort_order)',
        )
        .not('lat', 'is', null)
        .order('id', ascending: true)
        .range(from, to)
        .timeout(timeout),
  );
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
          thumbnailUrl: journeyPlaceThumbnail(row['place_images']),
        ),
  ];
}
