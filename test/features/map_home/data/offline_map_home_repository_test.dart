import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/core/domain/map_place.dart';
import 'package:kaunti47_v2/src/counties/county_paths.dart';
import 'package:kaunti47_v2/src/features/map_home/data/map_home_repository.dart';
import 'package:kaunti47_v2/src/features/map_home/data/offline_map_home_repository.dart';
import 'package:kaunti47_v2/src/features/map_home/domain/map_home_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Inner implements MapHomeRepository {
  _Inner(this.fail);
  bool fail;

  @override
  Future<MapHomeBoardData> loadBoard({CountyPath? homeCounty}) async {
    if (fail) throw Exception('offline');
    return const MockMapHomeRepository().loadBoard(homeCounty: homeCounty);
  }

  @override
  Future<List<MapPlace>> loadMapPlaces() async => const [];
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  OfflineMapHomeRepository repo(_Inner inner, {Set<int> pending = const {}}) =>
      OfflineMapHomeRepository(
        inner: inner,
        userId: () => 'u1',
        pendingCounties: () async => pending,
        clock: () => DateTime.utc(2026, 10, 12),
      );

  test('online loads pass through and are saved for later', () async {
    final inner = _Inner(false);
    final live = await repo(inner).loadBoard();
    expect(live.isOffline, isFalse);

    inner.fail = true;
    final offline = await repo(inner).loadBoard();
    expect(offline.isOffline, isTrue);
    expect(offline.savedAt, DateTime.utc(2026, 10, 12));
    expect(offline.exploredCount, live.exploredCount);
  });

  test('offline with nothing saved still opens, all locked', () async {
    final board = await repo(_Inner(true)).loadBoard();
    expect(board.isOffline, isTrue);
    expect(board.savedAt, isNull);
    expect(board.exploredCount, 0);
  });

  test('unsynced visits appear as pending', () async {
    final code = CountyPaths.all.first.code;
    final board = await repo(_Inner(true), pending: {code}).loadBoard();
    expect(
      board.countyBadges.firstWhere((b) => b.county.code == code).state,
      MapHomeCountyBadgeState.pending,
    );
  });
}
