import '../../../core/domain/county_tier.dart';
import '../../../counties/county_paths.dart';
import 'map_home_models.dart';

/// What Home remembers between loads so it can still open, on the drawn
/// county map, with no connection: each county's state and facts, the home
/// county and when the copy was taken. Nothing personal beyond that.
class MapHomeSnapshot {
  const MapHomeSnapshot({
    required this.savedAt,
    required this.homeCountyCode,
    required this.counties,
  });

  final DateTime savedAt;
  final int? homeCountyCode;
  final Map<int, MapHomeSnapshotCounty> counties;

  factory MapHomeSnapshot.fromBoard(MapHomeBoardData board, DateTime now) =>
      MapHomeSnapshot(
        savedAt: now,
        homeCountyCode: board.homeCounty?.code,
        counties: {
          for (final badge in board.countyBadges)
            badge.county.code: MapHomeSnapshotCounty(
              state: _wireFor(badge.state),
              areaKm2: badge.areaKm2,
              elevationM: badge.elevationM,
              durationMinutes: badge.durationMinutes,
              headquarters: badge.headquarters,
            ),
        },
      );

  Map<String, dynamic> toJson() => {
    'saved_at': savedAt.toUtc().toIso8601String(),
    'home_county': homeCountyCode,
    'counties': {
      for (final entry in counties.entries)
        '${entry.key}': entry.value.toJson(),
    },
  };

  static MapHomeSnapshot? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final savedAt = DateTime.tryParse('${raw['saved_at']}');
    final counties = raw['counties'];
    if (savedAt == null || counties is! Map) return null;
    return MapHomeSnapshot(
      savedAt: savedAt,
      homeCountyCode: (raw['home_county'] as num?)?.toInt(),
      counties: {
        for (final entry in counties.entries)
          if (int.tryParse('${entry.key}') != null && entry.value is Map)
            int.parse('${entry.key}'): MapHomeSnapshotCounty.fromJson(
              entry.value as Map,
            ),
      },
    );
  }

  static String? _wireFor(MapHomeCountyBadgeState state) => switch (state) {
    MapHomeCountyBadgeState.earned => 'explored',
    MapHomeCountyBadgeState.passedThrough => 'passed_through',
    MapHomeCountyBadgeState.pending => 'pending',
    _ => null,
  };

  /// The board Home shows without a connection. [pending] are counties
  /// detected on this phone and not yet synced: they show as pending unless
  /// the saved copy already has them earned. With no [snapshot] (first
  /// launch offline) every county is locked.
  static MapHomeBoardData offlineBoard({
    required MapHomeSnapshot? snapshot,
    required Set<int> pending,
    CountyPath? homeFallback,
  }) {
    final badges = [
      for (final county in CountyPaths.all)
        _badge(county, snapshot?.counties[county.code], pending),
    ];
    final explored = badges
        .where((b) => b.state == MapHomeCountyBadgeState.earned)
        .length;
    return MapHomeBoardData(
      tier: CountyTier.forClaimed(explored),
      totalCounties: CountyPaths.all.length,
      countyBadges: badges,
      homeCounty: CountyPaths.byCode[snapshot?.homeCountyCode] ?? homeFallback,
      suggestions: const [],
      isOffline: true,
      savedAt: snapshot?.savedAt,
    );
  }

  static MapHomeCountyBadge _badge(
    CountyPath county,
    MapHomeSnapshotCounty? saved,
    Set<int> pending,
  ) {
    var state = switch (saved?.state) {
      'explored' => MapHomeCountyBadgeState.earned,
      'passed_through' => MapHomeCountyBadgeState.passedThrough,
      'pending' => MapHomeCountyBadgeState.pending,
      _ => MapHomeCountyBadgeState.locked,
    };
    if (pending.contains(county.code) &&
        state != MapHomeCountyBadgeState.earned) {
      state = MapHomeCountyBadgeState.pending;
    }
    return MapHomeCountyBadge(
      county: county,
      state: state,
      areaKm2: saved?.areaKm2,
      elevationM: saved?.elevationM,
      durationMinutes: saved?.durationMinutes,
      headquarters: saved?.headquarters,
    );
  }
}

class MapHomeSnapshotCounty {
  const MapHomeSnapshotCounty({
    this.state,
    this.areaKm2,
    this.elevationM,
    this.durationMinutes,
    this.headquarters,
  });

  factory MapHomeSnapshotCounty.fromJson(Map<dynamic, dynamic> raw) => MapHomeSnapshotCounty(
    state: raw['s'] as String?,
    areaKm2: raw['a'] as num?,
    elevationM: raw['e'] as num?,
    durationMinutes: (raw['d'] as num?)?.toInt(),
    headquarters: raw['h'] as String?,
  );

  /// 'explored', 'passed_through', 'pending', or null (unclaimed).
  final String? state;
  final num? areaKm2;
  final num? elevationM;
  final int? durationMinutes;
  final String? headquarters;

  Map<String, dynamic> toJson() => {
    's': ?state,
    'a': ?areaKm2,
    'e': ?elevationM,
    'd': ?durationMinutes,
    'h': ?headquarters,
  };
}
