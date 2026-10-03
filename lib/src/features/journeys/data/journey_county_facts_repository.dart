import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/journey_county_moment_facts.dart';

/// Batches the "Entered county" card's static facts and the user's own
/// visit count for every county a Trip crossed, in one round of queries -
/// the same `Future.wait` pattern as
/// `SupabaseDiscoverDetailRepository.countyDetail`, just for several
/// counties at once instead of one. Depth isn't queried here: it's merged
/// in from the Badges collection already loaded elsewhere, so this never
/// re-derives the depth ladder.
class JourneyCountyFactsRepository {
  const JourneyCountyFactsRepository(this.client);

  final SupabaseClient client;

  Future<Map<int, JourneyCountyMomentFacts>> factsFor(
    Set<int> countyCodes,
  ) async {
    if (countyCodes.isEmpty) return const {};
    final codes = countyCodes.toList();
    final userId = client.auth.currentUser?.id;

    final results = await Future.wait<Object?>([
      client
          .from('counties')
          .select('id, capital, population, rarity_pct, highlight_image_url')
          .inFilter('id', codes),
      client
          .from('places')
          .select('county_id, place_images(thumbnail_url, sort_order)')
          .inFilter('county_id', codes),
      if (userId != null)
        client
            .from('county_visits')
            .select('county_id, pass_count')
            .eq('user_id', userId)
            .inFilter('county_id', codes),
    ]);

    final countyRows = (results[0]! as List).cast<Map<String, dynamic>>();
    final placeRows = (results[1]! as List).cast<Map<String, dynamic>>();
    final visitRows = userId == null
        ? const <Map<String, dynamic>>[]
        : (results[2]! as List).cast<Map<String, dynamic>>();

    final placesByCounty = <int, List<Map<String, dynamic>>>{};
    for (final row in placeRows) {
      final code = (row['county_id'] as num).toInt();
      (placesByCounty[code] ??= []).add(row);
    }
    final passByCounty = {
      for (final row in visitRows)
        (row['county_id'] as num).toInt():
            (row['pass_count'] as num?)?.toInt() ?? 1,
    };

    return {
      for (final row in countyRows)
        (row['id'] as num).toInt(): _facts(
          row,
          places: placesByCounty[(row['id'] as num).toInt()] ?? const [],
          passCount: passByCounty[(row['id'] as num).toInt()],
        ),
    };
  }

  JourneyCountyMomentFacts _facts(
    Map<String, dynamic> row, {
    required List<Map<String, dynamic>> places,
    int? passCount,
  }) {
    final capital = (row['capital'] as String?)?.trim();
    final firstThumbnail = places
        .expand(
          (place) => (place['place_images'] as List? ?? const [])
              .cast<Map<String, dynamic>>(),
        )
        .map((image) => image['thumbnail_url'] as String?)
        .whereType<String>()
        .firstOrNull;
    return JourneyCountyMomentFacts(
      capital: capital != null && capital.isNotEmpty ? capital : null,
      population: (row['population'] as num?)?.toInt(),
      rarityPct: row['rarity_pct'] as num?,
      highlightImageUrl: row['highlight_image_url'] as String?,
      placesCount: places.length,
      firstPlaceThumbnailUrl: firstThumbnail,
      passCount: passCount ?? 1,
    );
  }
}
