import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/app_current_location.dart';
import '../../../counties/county_paths.dart';
import '../domain/explore_board.dart';
import '../domain/explore_labels.dart';
import '../domain/explore_lists.dart';
import 'explore_repository.dart';
import 'explore_rows.dart';

/// Explore from Supabase (ported from v1's `SupabaseDiscoverRepository`):
/// `discover_mine_counties()` and `discover_unclaimed_counties()` for the
/// county lists, `places` for previews, `counties` for rarity and photos,
/// `wishlist_items` for SAVED.
///
/// Gaps stay visible rather than faked: rarity is null until a real job
/// runs, and distances are straight-line (no routing step).
class SupabaseExploreRepository implements ExploreRepository {
  const SupabaseExploreRepository(
    this.client, {
    this.readLocation = _readForegroundFix,
  });

  final SupabaseClient client;

  /// One foreground fix for distances and UNCLAIMED's nearest-first
  /// order; null when unavailable. Never stored (doc 05).
  final Future<AppLocationFix?> Function() readLocation;

  static Future<AppLocationFix?> _readForegroundFix() =>
      AppCurrentLocation.read(timeout: const Duration(milliseconds: 1200));

  String _userId() {
    final id = client.auth.currentUser?.id;
    if (id == null) throw StateError('Explore requires a signed-in user.');
    return id;
  }

  @override
  Future<ExploreBoard> loadBoard() async {
    final userId = _userId();

    // Started first so its budget overlaps the reads below.
    final locationFuture = readLocation();

    final results = await Future.wait<Object?>([
      client.rpc<List<dynamic>>('discover_mine_counties'),
      client
          .from('places')
          .select(
            'id, county_id, name, type, summary, description, lat, lng, '
            'place_images(thumbnail_url, sort_order), '
            'place_promotions(disclosure_label, placement, starts_at, ends_at, '
            'deactivated_at)',
          ),
      client
          .from('wishlist_items')
          .select(
            'county_id, place_id, ticked_at, saved_at, '
            'places(name, type, summary, description, lat, lng, '
            'place_images(thumbnail_url, sort_order))',
          )
          .eq('user_id', userId),
      _countyColumn('rarity_pct'),
      _countyColumn('highlight_image_url'),
      _countyFacts(),
      _countyColumn('capital'),
    ]);
    final location = await locationFuture;

    // The one read that depends on the fix: the RPC falls back to the
    // last visited or home county when there's none.
    final unclaimedRows = await client.rpc<List<dynamic>>(
      'discover_unclaimed_counties',
      params: {
        if (location != null) 'p_latitude': location.latitude,
        if (location != null) 'p_longitude': location.longitude,
      },
    );

    final explored = [
      for (final row in _rows(results[0]))
        if (row['state'] == 'explored' && _known(row['county_id'])) row,
    ];
    final placesByCounty = <int, List<Map<String, dynamic>>>{};
    for (final row in _rows(results[1])) {
      placesByCounty.putIfAbsent(_code(row), () => []).add(row);
    }
    final wishlist = _rows(results[2]);
    final savedPlaceIds = {
      for (final row in wishlist)
        if (row['place_id'] is String) row['place_id'] as String,
    };
    final savedAloneCounties = {
      for (final row in wishlist)
        if (row['place_id'] == null) _code(row),
    };
    final rarity = results[3]! as Map<int, Object?>;
    final photos = results[4]! as Map<int, Object?>;
    final facts = results[5]! as Map<int, ExploreCountyFacts>;
    final headquarters = results[6]! as Map<int, Object?>;
    List<String> placeNames(int code) => [
      for (final place in placesByCounty[code] ?? const [])
        place['name'] as String,
    ];

    List<ExplorePlace> preview(int code) {
      final rows = placesByCounty[code] ?? const <Map<String, dynamic>>[];
      return [
        for (final row in ExploreRows.previewRows(rows))
          ExploreRows.place(
            row,
            id: row['id'] as String,
            saved: savedPlaceIds.contains(row['id']),
            location: location,
          ),
      ];
    }
    int placeCount(int code) => placesByCounty[code]?.length ?? 0;

    // The RPC orders by entered_at desc: the newest unlock is featured.
    final featuredCode = explored.isEmpty ? null : _code(explored.first);
    return ExploreBoard(
      featuredUnlock: featuredCode == null
          ? null
          : ExploreFeaturedUnlock(
              county: CountyPaths.byCode[featuredCode]!,
              rarityLabel: ExploreLabels.rarity(rarity[featuredCode] as num?),
              blurb: ExploreLabels.blurb(placeNames(featuredCode)),
              highlightImageUrl: photos[featuredCode] as String?,
              facts: facts[featuredCode] ?? noCountyFacts,
              headquarters: headquarters[featuredCode] as String?,
              previewPlaces: preview(featuredCode),
              totalPlaceCount: placeCount(featuredCode),
            ),
      mine: [
        for (final row in explored)
          if (_code(row) != featuredCode)
            ExploreMineCounty(
              county: CountyPaths.byCode[_code(row)]!,
              statusLabel: ExploreLabels.mineStatus(
                isLocalExpert: row['rank'] == 'local_expert',
                visits: (row['pass_count'] as num?)?.toInt() ?? 1,
              ),
              placeCount: placeCount(_code(row)),
              isLocalExpert: row['rank'] == 'local_expert',
              previewPlaces: preview(_code(row)),
            ),
      ],
      unclaimed: ExploreUnclaimedCounty.nearestFirst([
        for (final row in _rows(unclaimedRows))
          if (_known(row['county_id']))
            ExploreUnclaimedCounty(
              county: CountyPaths.byCode[_code(row)]!,
              blurb: ExploreLabels.blurb(placeNames(_code(row))),
              percentHaveBeen: (row['rarity_pct'] as num?)?.round(),
              placeCount: placeCount(_code(row)),
              distanceLabel: ExploreLabels.distance(row['distance_m'] as num?),
              distanceMeters: row['distance_m'] as num?,
              previewPlaces: preview(_code(row)),
              isSavedAlone: savedAloneCounties.contains(_code(row)),
              highlightImageUrl: photos[_code(row)] as String?,
              facts: facts[_code(row)] ?? noCountyFacts,
              headquarters: headquarters[_code(row)] as String?,
            ),
      ]),
      saved: ExploreRows.savedGroups(
        wishlist,
        rankByExploredCounty: {
          for (final row in explored)
            _code(row): row['rank'] as String? ?? 'visitor',
        },
        location: location,
      ),
    );
  }

  @override
  Future<void> setCountySaved({
    required int countyCode,
    required bool saved,
  }) async {
    final userId = _userId();
    // Filtered for "no place" in Dart (v1 parity): a county has a
    // handful of wishlist rows at most.
    final rows = await client
        .from('wishlist_items')
        .select('id, place_id')
        .eq('user_id', userId)
        .eq('county_id', countyCode);
    final countyRowIds = [
      for (final row in rows)
        if (row['place_id'] == null) row['id'] as String,
    ];
    if (saved && countyRowIds.isEmpty) {
      await client.from('wishlist_items').insert({
        'user_id': userId,
        'county_id': countyCode,
        'place_id': null,
      });
    } else if (!saved) {
      for (final id in countyRowIds) {
        await client.from('wishlist_items').delete().eq('id', id);
      }
    }
  }

  @override
  Future<void> setPlaceTicked({
    required String placeId,
    required bool ticked,
  }) async {
    final updated = await client
        .from('wishlist_items')
        .update({
          'ticked_at': ticked ? DateTime.now().toUtc().toIso8601String() : null,
        })
        .eq('user_id', _userId())
        .eq('place_id', placeId)
        .select('id');
    // Only a saved place shows a tick, so a missing row is a bug: fail
    // loudly rather than look like a successful tick.
    if (updated.isEmpty) {
      throw StateError('No saved row to tick for place $placeId.');
    }
  }

  /// Area / Elevation / Duration per county, read on its own for the same
  /// reason as [_countyColumn].
  Future<Map<int, ExploreCountyFacts>> _countyFacts() async {
    try {
      final rows = await client
          .from('counties')
          .select('id, area_km2, elevation_m, duration_minutes');
      return {
        for (final row in rows)
          _code(row, key: 'id'): (
            areaKm2: row['area_km2'] as num?,
            elevationM: row['elevation_m'] as num?,
            durationMinutes: (row['duration_minutes'] as num?)?.toInt(),
          ),
      };
    } on PostgrestException {
      return const {};
    }
  }

  /// One `counties` column by id, read on its own so a column missing on
  /// an older database drops that detail instead of failing the board.
  Future<Map<int, Object?>> _countyColumn(String column) async {
    try {
      final rows = await client.from('counties').select('id, $column');
      return {for (final row in rows) _code(row, key: 'id'): row[column]};
    } on PostgrestException {
      return const {};
    }
  }

  static List<Map<String, dynamic>> _rows(Object? result) =>
      (result! as List).cast<Map<String, dynamic>>();

  static int _code(Map<String, dynamic> row, {String key = 'county_id'}) =>
      (row[key] as num).toInt();

  static bool _known(Object? countyId) =>
      countyId is num && CountyPaths.byCode.containsKey(countyId.toInt());
}
