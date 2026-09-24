import '../../../core/services/app_current_location.dart';
import '../../../counties/county_paths.dart';
import '../domain/explore_board.dart';
import '../domain/explore_labels.dart';
import '../domain/explore_lists.dart';
import '../domain/place_category.dart';

/// Row-to-model helpers for [SupabaseExploreRepository], kept apart so
/// the repository stays about queries.
abstract final class ExploreRows {
  static ExplorePlace place(
    Map<String, dynamic> row, {
    required String id,
    required bool saved,
    required AppLocationFix? location,
    bool seen = false,
  }) => ExplorePlace(
    id: id,
    title: row['name'] as String,
    description:
        (row['summary'] as String?) ?? (row['description'] as String?) ?? '',
    category: PlaceCategory.fromType(row['type'] as String? ?? ''),
    saved: saved,
    seen: seen,
    isPromoted: activePromotion(row) != null,
    promotionLabel:
        (activePromotion(row)?['disclosure_label'] as String?) ?? 'AD',
    thumbnailUrl: thumbnail(row['place_images']),
    distanceLabel: ExploreLabels.placeDistance(
      from: location,
      latitude: (row['lat'] as num?)?.toDouble(),
      longitude: (row['lng'] as num?)?.toDouble(),
    ),
  );

  static Map<String, dynamic>? activePromotion(Map<String, dynamic> row) {
    final promotions = row['place_promotions'];
    if (promotions is! List || promotions.isEmpty) return null;

    final now = DateTime.now().toUtc();
    for (final raw in promotions.cast<Map<String, dynamic>>()) {
      if (raw['deactivated_at'] != null) continue;
      final startsAt = DateTime.tryParse(raw['starts_at'] as String? ?? '');
      final endsAt = DateTime.tryParse(raw['ends_at'] as String? ?? '');
      final hasStarted = startsAt == null || !startsAt.isAfter(now);
      final hasNotEnded = endsAt == null || endsAt.isAfter(now);
      if (hasStarted && hasNotEnded) return raw;
    }
    return null;
  }

  /// Discover previews show up to three places. If a county has an active
  /// paid placement, include it and pin it to the second slot whenever any
  /// normal place can appear before it. With only one place, it stays first.
  static List<Map<String, dynamic>> previewRows(
    List<Map<String, dynamic>> rows,
  ) {
    Map<String, dynamic>? promoted;
    for (final row in rows) {
      if (activePromotion(row) != null) {
        promoted = row;
        break;
      }
    }
    if (promoted == null) return rows.take(3).toList();

    final normal = [
      for (final row in rows)
        if (row['id'] != promoted['id']) row,
    ];
    if (normal.isEmpty) return [promoted];
    if (normal.length == 1) return [normal.first, promoted];
    return [normal[0], promoted, normal[1]];
  }

  static String? thumbnail(Object? images) {
    if (images is! List || images.isEmpty) return null;
    final sorted = [...images.cast<Map<String, dynamic>>()]
      ..sort(
        (a, b) => ((a['sort_order'] as num?) ?? 0).compareTo(
          (b['sort_order'] as num?) ?? 0,
        ),
      );
    return sorted.first['thumbnail_url'] as String?;
  }

  /// SAVED: wishlist rows grouped by county, most recently saved county
  /// first (doc 03: that county opens by default).
  static List<ExploreSavedGroup> savedGroups(
    List<Map<String, dynamic>> wishlistRows, {
    required Map<int, String> rankByExploredCounty,
    required AppLocationFix? location,
  }) {
    final byCounty = <int, List<Map<String, dynamic>>>{};
    for (final row in wishlistRows) {
      final code = (row['county_id'] as num).toInt();
      if (!CountyPaths.byCode.containsKey(code)) continue;
      byCounty.putIfAbsent(code, () => []).add(row);
    }

    final groups = <({DateTime? latest, ExploreSavedGroup group})>[];
    for (final MapEntry(key: code, value: rows) in byCounty.entries) {
      final placeRows = [
        for (final row in rows)
          if (row['place_id'] is String && row['places'] is Map) row,
      ];
      final (status, label) = ExploreSavedGroup.statusFor(
        rank: rankByExploredCounty[code],
        savedPlaces: placeRows.length,
        stillToSee: placeRows.where((r) => r['ticked_at'] == null).length,
      );
      DateTime? latest;
      for (final row in rows) {
        final saved = DateTime.tryParse(row['saved_at'] as String? ?? '');
        if (saved != null && (latest == null || saved.isAfter(latest))) {
          latest = saved;
        }
      }
      groups.add((
        latest: latest,
        group: ExploreSavedGroup(
          county: CountyPaths.byCode[code]!,
          status: status,
          statusLabel: label,
          places: [
            for (final row in placeRows)
              place(
                (row['places'] as Map).cast<String, dynamic>(),
                id: row['place_id'] as String,
                saved: true,
                seen: row['ticked_at'] != null,
                location: location,
              ),
          ],
        ),
      ));
    }

    groups.sort((a, b) {
      final (ta, tb) = (a.latest, b.latest);
      if (ta == null && tb == null) return 0;
      if (ta == null) return 1;
      if (tb == null) return -1;
      return tb.compareTo(ta);
    });
    return [for (final entry in groups) entry.group];
  }
}
