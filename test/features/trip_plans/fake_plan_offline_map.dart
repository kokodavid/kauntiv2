import 'package:kaunti47_v2/src/features/trip_plans/data/plan_offline_map.dart';
import 'package:kaunti47_v2/src/features/trip_plans/data/plan_offline_store.dart';
import 'package:kaunti47_v2/src/features/trip_plans/domain/plan_offline.dart';

/// A [PlanOfflineMap] for tests: records what was saved, or fails.
class FakePlanOfflineMap implements PlanOfflineMap {
  bool fail = false;
  final downloads = <String>[];
  final removed = <String>[];
  PlanBounds? lastBounds;

  @override
  Future<void> download(
    String regionId,
    PlanBounds bounds,
    void Function(double progress) onProgress,
  ) async {
    if (fail) throw StateError('no network');
    onProgress(0.5);
    downloads.add(regionId);
    lastBounds = bounds;
    onProgress(1);
  }

  @override
  Future<void> remove(String regionId) async => removed.add(regionId);
}

/// Picture prefetching that touches nothing.
class FakePlanOfflineImages implements PlanOfflineImages {
  final fetched = <String>[];

  @override
  Future<void> prefetch(Iterable<String> urls) async => fetched.addAll(urls);
}
