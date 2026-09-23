import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../counties/county_paths.dart';
import '../domain/county_detail.dart';
import '../domain/place_category.dart';
import '../domain/place_detail.dart';
import 'discover_detail_repository.dart';

/// County and Place Detail from Supabase (ported from v1's
/// `SupabaseDiscoverRepository.countyDetail/placeDetail`). Distance labels
/// are left out until v2 has a foreground location read.
class SupabaseDiscoverDetailRepository implements DiscoverDetailRepository {
  const SupabaseDiscoverDetailRepository(this.client);

  final SupabaseClient client;

  String _userId() {
    final id = client.auth.currentUser?.id;
    if (id == null) throw StateError('This call requires a signed-in user.');
    return id;
  }

  @override
  Future<CountyDetailData> countyDetail(int countyCode) async {
    final userId = _userId();
    final county = CountyPaths.byCode[countyCode];
    if (county == null) throw ArgumentError('Unknown county: $countyCode');

    // Independent reads go out together.
    final results = await Future.wait<Object?>([
      client
          .from('counties')
          .select(
            'year_established, population, area_km2, elevation_m, '
            'governor_name, rarity_pct, highlight_image_url',
          )
          .eq('id', countyCode)
          .single(),
      client
          .from('places')
          .select(
            'id, name, type, summary, description, '
            'place_images(thumbnail_url, sort_order)',
          )
          .eq('county_id', countyCode),
      client
          .from('wishlist_items')
          .select('place_id')
          .eq('user_id', userId)
          .eq('county_id', countyCode),
      client
          .from('county_visits')
          .select('state, pass_count')
          .eq('user_id', userId)
          .eq('county_id', countyCode)
          .order('entered_at', ascending: false)
          .limit(1)
          .maybeSingle(),
      client
          .from('county_depth_progress')
          .select('rank')
          .eq('user_id', userId)
          .eq('county_id', countyCode)
          .maybeSingle(),
    ]);

    final countyRow = results[0]! as Map<String, dynamic>;
    final placeRows = (results[1]! as List).cast<Map<String, dynamic>>();
    final savedIds = {
      for (final row in (results[2]! as List).cast<Map<String, dynamic>>())
        if (row['place_id'] is String) row['place_id'] as String,
    };
    final visit = results[3] as Map<String, dynamic>?;
    final depth = results[4] as Map<String, dynamic>?;
    final state = visit?['state'] as String?;
    final passes = (visit?['pass_count'] as num?)?.toInt() ?? 1;

    return CountyDetailData(
      county: county,
      aboutBlurb: _aboutBlurb(
        county.name,
        [for (final row in placeRows) row['name'] as String],
        countyRow['rarity_pct'] as num?,
      ),
      highlightImageUrl: countyRow['highlight_image_url'] as String?,
      quickFacts: CountyQuickFacts(
        yearEstablished: (countyRow['year_established'] as num?)?.toInt(),
        population: (countyRow['population'] as num?)?.toInt(),
        areaKm2: countyRow['area_km2'] as num?,
        elevationM: countyRow['elevation_m'] as num?,
        governorName: countyRow['governor_name'] as String?,
      ),
      places: [
        for (final row in placeRows)
          CountyDetailPlace(
            id: row['id'] as String,
            title: row['name'] as String,
            description:
                (row['summary'] as String?) ??
                (row['description'] as String?) ??
                '',
            category: PlaceCategory.fromType(row['type'] as String),
            saved: savedIds.contains(row['id']),
            thumbnailUrl: _sortedImages(
              row['place_images'],
              'thumbnail_url',
            ).firstOrNull,
          ),
      ],
      personalStatusLabel: switch (state) {
        null => 'NOT VISITED YET',
        'passed_through' => 'PASSED THROUGH $passes TIME${passes == 1 ? '' : 'S'}',
        _ => depth?['rank'] == 'local_expert' ? 'LOCAL EXPERT' : 'EXPLORED',
      },
      isHeld: state == 'explored',
    );
  }

  @override
  Future<PlaceDetailData> placeDetail(String placeId) async {
    final userId = _userId();
    final results = await Future.wait<Object?>([
      client
          .from('places')
          .select(
            'id, county_id, name, type, summary, description, source, '
            'lat, lng, place_images(image_url, sort_order)',
          )
          .eq('id', placeId)
          .maybeSingle(),
      client
          .from('wishlist_items')
          .select('id')
          .eq('user_id', userId)
          .eq('place_id', placeId)
          .maybeSingle(),
    ]);
    final row = results[0] as Map<String, dynamic>?;
    if (row == null) throw StateError('No place on file with id "$placeId".');
    final county = CountyPaths.byCode[(row['county_id'] as num).toInt()];
    if (county == null) throw StateError('Place "$placeId" has no county.');

    return PlaceDetailData(
      id: placeId,
      title: row['name'] as String,
      category: PlaceCategory.fromType(row['type'] as String),
      county: county,
      description:
          (row['description'] as String?) ?? (row['summary'] as String?) ?? '',
      images: _sortedImages(row['place_images'], 'image_url'),
      source: (row['source'] as String?) ?? 'Unknown',
      saved: results[1] != null,
      latitude: (row['lat'] as num?)?.toDouble(),
      longitude: (row['lng'] as num?)?.toDouble(),
    );
  }

  @override
  Future<void> setPlaceSaved({
    required int countyCode,
    required String placeId,
    required bool saved,
  }) async {
    final userId = _userId();
    if (!saved) {
      await client
          .from('wishlist_items')
          .delete()
          .eq('user_id', userId)
          .eq('place_id', placeId);
      return;
    }
    final existing = await client
        .from('wishlist_items')
        .select('id')
        .eq('user_id', userId)
        .eq('place_id', placeId)
        .maybeSingle();
    if (existing != null) return;
    await client.from('wishlist_items').insert({
      'user_id': userId,
      'county_id': countyCode,
      'place_id': placeId,
    });
  }

  static List<String> _sortedImages(Object? images, String urlKey) {
    if (images is! List) return const [];
    final rows = images.whereType<Map<String, dynamic>>().toList()
      ..sort(
        (a, b) => ((a['sort_order'] as num?) ?? 0).compareTo(
          (b['sort_order'] as num?) ?? 0,
        ),
      );
    return [
      for (final row in rows)
        if (row[urlKey] is String) row[urlKey] as String,
    ];
  }

  static String _aboutBlurb(String county, List<String> places, num? rarity) {
    final placesClause = switch (places.length) {
      0 => '$county has no places on file yet.',
      1 => '$county has one place on file so far: ${places.first}.',
      _ =>
        '$county has ${places.length} places on file, including '
            '${places[0]} and ${places[1]}.',
    };
    if (rarity == null) return placesClause;
    final pct = rarity.round();
    final share = pct <= 5 ? 'Only $pct% have been here' : '$pct% have been here';
    return '$placesClause $share, among travellers tracked so far.';
  }
}
