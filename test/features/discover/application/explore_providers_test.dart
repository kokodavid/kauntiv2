import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/discover/application/explore_providers.dart';
import 'package:kaunti47_v2/src/features/discover/data/discover_detail_repository.dart';
import 'package:kaunti47_v2/src/features/discover/data/explore_repository.dart';
import 'package:kaunti47_v2/src/features/discover/domain/county_detail.dart';
import 'package:kaunti47_v2/src/features/discover/domain/explore_board.dart';
import 'package:kaunti47_v2/src/features/discover/domain/place_detail.dart';

class _FakeExploreRepository implements ExploreRepository {
  var loads = 0;
  bool fail = false;
  final countySaves = <(int, bool)>[];
  final ticks = <(String, bool)>[];

  @override
  Future<void> setCountySaved({
    required int countyCode,
    required bool saved,
  }) async {
    if (fail) throw StateError('offline');
    countySaves.add((countyCode, saved));
  }

  @override
  Future<void> setPlaceTicked({
    required String placeId,
    required bool ticked,
  }) async {
    if (fail) throw StateError('offline');
    ticks.add((placeId, ticked));
  }

  @override
  Future<ExploreBoard> loadBoard() async {
    loads++;
    return const ExploreBoard(featuredUnlock: null, mine: []);
  }
}

class _FakeDetailRepository implements DiscoverDetailRepository {
  bool fail = false;
  final saves = <(String, bool)>[];

  @override
  Future<CountyDetailData> countyDetail(int countyCode) =>
      throw UnimplementedError();

  @override
  Future<PlaceDetailData> placeDetail(String placeId) =>
      throw UnimplementedError();

  @override
  Future<void> setPlaceSaved({
    required int countyCode,
    required String placeId,
    required bool saved,
  }) async {
    if (fail) throw StateError('offline');
    saves.add((placeId, saved));
  }
}

void main() {
  late _FakeExploreRepository explore;
  late _FakeDetailRepository detail;
  late ProviderContainer container;

  setUp(() {
    explore = _FakeExploreRepository();
    detail = _FakeDetailRepository();
    container = ProviderContainer(
      overrides: [
        exploreRepositoryProvider.overrideWithValue(explore),
        discoverDetailRepositoryProvider.overrideWithValue(detail),
      ],
    );
    addTearDown(container.dispose);
  });

  test('board loads from the repository', () async {
    final board = await container.read(exploreBoardProvider.future);
    expect(board.isEmpty, isTrue);
    expect(explore.loads, 1);
  });

  test('tab selection and search start empty and update', () {
    final tab = container.listen(exploreTabSelectionProvider, (_, _) {});
    final query = container.listen(exploreSearchQueryProvider, (_, _) {});
    expect(tab.read(), ExploreTab.mine);
    expect(query.read(), '');

    container
        .read(exploreTabSelectionProvider.notifier)
        .select(ExploreTab.saved);
    container.read(exploreSearchQueryProvider.notifier).update('lamu');
    expect(tab.read(), ExploreTab.saved);
    expect(query.read(), 'lamu');
  });

  test('saving records the override and writes through', () async {
    final saved = container.listen(exploreSavedPlacesProvider, (_, _) {});
    await container
        .read(exploreSavedPlacesProvider.notifier)
        .setSaved(countyCode: 1, placeId: 'p1', saved: true);
    expect(saved.read(), {'p1': true});
    expect(detail.saves, [('p1', true)]);
  });

  test('a failed save restores the previous state and rethrows', () async {
    final saved = container.listen(exploreSavedPlacesProvider, (_, _) {});
    detail.fail = true;
    await expectLater(
      container
          .read(exploreSavedPlacesProvider.notifier)
          .setSaved(countyCode: 1, placeId: 'p1', saved: true),
      throwsStateError,
    );
    expect(saved.read(), isEmpty);
  });

  test('a successful save refreshes the board so SAVED updates', () async {
    final board = container.listen(exploreBoardProvider, (_, _) {});
    await container.read(exploreBoardProvider.future);
    container.listen(exploreSavedPlacesProvider, (_, _) {});
    await container
        .read(exploreSavedPlacesProvider.notifier)
        .setSaved(countyCode: 1, placeId: 'p1', saved: true);
    await container.read(exploreBoardProvider.future);
    expect(explore.loads, 2);
    board.close();
  });

  test('county saves are optimistic and revert on failure', () async {
    final saved = container.listen(exploreSavedCountiesProvider, (_, _) {});
    await container
        .read(exploreSavedCountiesProvider.notifier)
        .setSaved(countyCode: 7, saved: true);
    expect(saved.read(), {7: true});
    expect(explore.countySaves, [(7, true)]);

    explore.fail = true;
    await expectLater(
      container
          .read(exploreSavedCountiesProvider.notifier)
          .setSaved(countyCode: 7, saved: false),
      throwsStateError,
    );
    expect(saved.read(), {7: true});
  });

  test('ticks are optimistic and revert on failure', () async {
    final ticked = container.listen(exploreTickedPlacesProvider, (_, _) {});
    await container
        .read(exploreTickedPlacesProvider.notifier)
        .setTicked(placeId: 'p1', ticked: true);
    expect(ticked.read(), {'p1': true});
    expect(explore.ticks, [('p1', true)]);

    explore.fail = true;
    await expectLater(
      container
          .read(exploreTickedPlacesProvider.notifier)
          .setTicked(placeId: 'p2', ticked: true),
      throwsStateError,
    );
    expect(ticked.read(), {'p1': true});
  });
}
