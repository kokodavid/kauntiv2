import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/counties/county_paths.dart';
import 'package:kaunti47_v2/src/features/map_home/domain/map_home_models.dart';
import 'package:kaunti47_v2/src/features/map_home/domain/map_home_snapshot.dart';

MapHomeBoardData _board() => MapHomeBoardData(
  tier: null,
  totalCounties: CountyPaths.all.length,
  homeCounty: CountyPaths.all.first,
  suggestions: const [],
  countyBadges: [
    for (var i = 0; i < CountyPaths.all.length; i++)
      MapHomeCountyBadge(
        county: CountyPaths.all[i],
        state: switch (i) {
          0 => MapHomeCountyBadgeState.earned,
          1 => MapHomeCountyBadgeState.passedThrough,
          _ => MapHomeCountyBadgeState.locked,
        },
        areaKm2: i == 0 ? 694 : null,
        headquarters: i == 0 ? 'Town' : null,
      ),
  ],
);

void main() {
  final now = DateTime.utc(2026, 10, 12, 9, 41);

  test('a snapshot survives JSON and rebuilds the same states', () {
    final snapshot = MapHomeSnapshot.fromBoard(_board(), now);
    final back = MapHomeSnapshot.fromJson(snapshot.toJson())!;
    final board = MapHomeSnapshot.offlineBoard(snapshot: back, pending: {});
    expect(board.isOffline, isTrue);
    expect(board.savedAt, now);
    expect(board.countyBadges[0].state, MapHomeCountyBadgeState.earned);
    expect(board.countyBadges[0].areaKm2, 694);
    expect(board.countyBadges[0].headquarters, 'Town');
    expect(board.countyBadges[1].state, MapHomeCountyBadgeState.passedThrough);
    expect(board.countyBadges[2].state, MapHomeCountyBadgeState.locked);
    expect(board.exploredCount, 1);
  });

  test('unsynced visits show as pending, never downgrading earned', () {
    final snapshot = MapHomeSnapshot.fromBoard(_board(), now);
    final first = CountyPaths.all[0].code;
    final second = CountyPaths.all[1].code;
    final third = CountyPaths.all[2].code;
    final board = MapHomeSnapshot.offlineBoard(
      snapshot: snapshot,
      pending: {first, second, third},
    );
    expect(board.countyBadges[0].state, MapHomeCountyBadgeState.earned);
    expect(board.countyBadges[1].state, MapHomeCountyBadgeState.pending);
    expect(board.countyBadges[2].state, MapHomeCountyBadgeState.pending);
  });

  test('with no snapshot every county is locked and savedAt is null', () {
    final board = MapHomeSnapshot.offlineBoard(
      snapshot: null,
      pending: {},
      homeFallback: CountyPaths.all.first,
    );
    expect(board.savedAt, isNull);
    expect(board.homeCounty, CountyPaths.all.first);
    expect(board.exploredCount, 0);
  });

  test('junk JSON is ignored', () {
    expect(MapHomeSnapshot.fromJson('nope'), isNull);
    expect(MapHomeSnapshot.fromJson({'saved_at': 'x'}), isNull);
  });
}
