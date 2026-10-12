import '../../../core/domain/map_place.dart';
import '../../../counties/county_paths.dart';
import '../domain/map_home_models.dart';
import '../domain/map_home_snapshot.dart';
import 'map_home_repository.dart';
import 'map_home_snapshot_store.dart';

/// Wraps the live repository: every good board is saved, and when the live
/// load fails or stalls, Home gets a board built from the saved copy plus
/// counties detected on this phone but not synced yet.
class OfflineMapHomeRepository implements MapHomeRepository {
  const OfflineMapHomeRepository({
    required this.inner,
    required this.userId,
    required this.pendingCounties,
    this.store = const MapHomeSnapshotStore(),
    this.patience = const Duration(seconds: 8),
    this.clock = DateTime.now,
  });

  final MapHomeRepository inner;
  final String? Function() userId;
  final Future<Set<int>> Function() pendingCounties;
  final MapHomeSnapshotStore store;

  /// How long the live load gets before Home opens from the saved copy.
  final Duration patience;
  final DateTime Function() clock;

  @override
  Future<MapHomeBoardData> loadBoard({CountyPath? homeCounty}) async {
    try {
      final board = await inner
          .loadBoard(homeCounty: homeCounty)
          .timeout(patience);
      final user = userId();
      if (user != null) {
        await store.write(user, MapHomeSnapshot.fromBoard(board, clock()));
      }
      return board;
    } on Object {
      final user = userId();
      final snapshot = user == null ? null : await store.read(user);
      Set<int> pending;
      try {
        pending = await pendingCounties();
      } on Object {
        pending = const {};
      }
      return MapHomeSnapshot.offlineBoard(
        snapshot: snapshot,
        pending: pending,
        homeFallback: homeCounty,
      );
    }
  }

  @override
  Future<List<MapPlace>> loadMapPlaces() => inner.loadMapPlaces();
}
