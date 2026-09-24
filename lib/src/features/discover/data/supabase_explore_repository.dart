import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/app_current_location.dart';
import '../../../counties/county_paths.dart';
import '../domain/explore_board.dart';
import '../domain/explore_labels.dart';
import '../domain/place_category.dart';
import 'explore_repository.dart';

/// Explore's MINE board from Supabase (ported from v1's
/// `SupabaseDiscoverRepository.board`): `discover_mine_counties()` for the
/// traveller's explored counties, `places` for previews, `counties` for
/// rarity and `wishlist_items` for saved state.
///
/// Gaps stay visible rather than faked: rarity is null until a real job
/// runs, and distances are straight-line from a foreground fix.
class SupabaseExploreRepository implements ExploreRepository {
  const SupabaseExploreRepository(
    this.client, {
    this.readLocation = _readForegroundFix,
  });

  final SupabaseClient client;

  /// One foreground fix for distance labels; null when unavailable.
  /// Never stored (doc 05).
  final Future<AppLocationFix?> Function() readLocation;

  static Future<AppLocationFix?> _readForegroundFix() =>
      AppCurrentLocation.read(timeout: const Duration(milliseconds: 1200));

  @override
  Future<ExploreBoard> loadBoard() async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) throw StateError('Explore requires a signed-in user.');

    // Started first so its budget overlaps the reads below.
    final locationFuture = readLocation();

    final results = await Future.wait<Object?>([
      client.rpc<List<dynamic>>('discover_mine_counties'),
      client
          .from('places')
          .select(
            'id, county_id, name, type, summary, description, lat, lng, '
            'place_images(thumbnail_url, sort_order)',
          ),
      client.from('wishlist_items').select('place_id').eq('user_id', userId),
      _rarityByCounty(),
    ]);

    final mineRows = [
      for (final row in (results[0]! as List).cast<Map<String, dynamic>>())
        if (row['state'] == 'explored' &&
            CountyPaths.byCode.containsKey(row['county_id']))
          row,
    ];
    final placesByCounty = <int, List<Map<String, dynamic>>>{};
    for (final row in (results[1]! as List).cast<Map<String, dynamic>>()) {
      final countyId = (row['county_id'] as num).toInt();
      placesByCounty.putIfAbsent(countyId, () => []).add(row);
    }
    final savedIds = {
      for (final row in (results[2]! as List).cast<Map<String, dynamic>>())
        if (row['place_id'] is String) row['place_id'] as String,
    };
    final rarity = results[3]! as Map<int, num?>;
    final location = await locationFuture;

    List<ExplorePlace> preview(int code) => [
      for (final row in (placesByCounty[code] ?? const []).take(3))
        _place(row, savedIds, location),
    ];
    int placeCount(int code) => placesByCounty[code]?.length ?? 0;

    // The RPC orders by entered_at desc: the newest unlock is featured.
    final featuredCode = mineRows.isEmpty
        ? null
        : (mineRows.first['county_id'] as num).toInt();
    return ExploreBoard(
      featuredUnlock: featuredCode == null
          ? null
          : ExploreFeaturedUnlock(
              county: CountyPaths.byCode[featuredCode]!,
              rarityLabel: ExploreLabels.rarity(rarity[featuredCode]),
              previewPlaces: preview(featuredCode),
              totalPlaceCount: placeCount(featuredCode),
            ),
      mine: [
        for (final row in mineRows)
          if ((row['county_id'] as num).toInt() != featuredCode)
            _mineCounty(
              row,
              preview((row['county_id'] as num).toInt()),
              placeCount((row['county_id'] as num).toInt()),
            ),
      ],
    );
  }

  ExploreMineCounty _mineCounty(
    Map<String, dynamic> row,
    List<ExplorePlace> previewPlaces,
    int placeCount,
  ) {
    final isLocalExpert = row['rank'] == 'local_expert';
    return ExploreMineCounty(
      county: CountyPaths.byCode[(row['county_id'] as num).toInt()]!,
      statusLabel: ExploreLabels.mineStatus(
        isLocalExpert: isLocalExpert,
        visits: (row['pass_count'] as num?)?.toInt() ?? 1,
      ),
      placeCount: placeCount,
      isLocalExpert: isLocalExpert,
      previewPlaces: previewPlaces,
    );
  }

  /// Read on its own so a missing column on an older database only drops
  /// the rarity label instead of failing the whole board.
  Future<Map<int, num?>> _rarityByCounty() async {
    try {
      final rows = await client.from('counties').select('id, rarity_pct');
      return {
        for (final row in rows)
          (row['id'] as num).toInt(): row['rarity_pct'] as num?,
      };
    } on PostgrestException {
      return const {};
    }
  }

  ExplorePlace _place(
    Map<String, dynamic> row,
    Set<String> savedIds,
    AppLocationFix? location,
  ) {
    final id = row['id'] as String;
    return ExplorePlace(
      id: id,
      title: row['name'] as String,
      description:
          (row['summary'] as String?) ?? (row['description'] as String?) ?? '',
      category: PlaceCategory.fromType(row['type'] as String? ?? ''),
      saved: savedIds.contains(id),
      thumbnailUrl: _thumbnail(row['place_images']),
      distanceLabel: ExploreLabels.placeDistance(
        from: location,
        latitude: (row['lat'] as num?)?.toDouble(),
        longitude: (row['lng'] as num?)?.toDouble(),
      ),
    );
  }

  static String? _thumbnail(Object? images) {
    if (images is! List || images.isEmpty) return null;
    final sorted = [...images.cast<Map<String, dynamic>>()]
      ..sort(
        (a, b) => ((a['sort_order'] as num?) ?? 0).compareTo(
          (b['sort_order'] as num?) ?? 0,
        ),
      );
    return sorted.first['thumbnail_url'] as String?;
  }
}
