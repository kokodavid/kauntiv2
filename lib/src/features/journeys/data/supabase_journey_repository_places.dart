part of 'supabase_journey_repository.dart';

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
