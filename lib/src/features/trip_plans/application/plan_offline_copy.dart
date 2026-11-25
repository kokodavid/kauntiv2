import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/application/auth_providers.dart';
import '../data/plan_offline_map.dart';
import '../data/plan_offline_store.dart';
import '../domain/plan_failure.dart';
import '../domain/plan_offline.dart';
import '../domain/trip_plan.dart';

part 'plan_offline_copy.g.dart';

@riverpod
PlanOfflineMap planOfflineMap(Ref ref) => const MapboxPlanOfflineMap();

@riverpod
PlanOfflineStore planOfflineStore(Ref ref) => const PlanOfflineStore();

@riverpod
PlanOfflineImages planOfflineImages(Ref ref) => const PlanOfflineImages();

/// A plan's offline copy (Pro): the map around its stops and its place
/// pictures, saved on this phone. Reading a plan you've opened before
/// already works offline for everyone; this adds the map and pictures.
@riverpod
class PlanOfflineCopy extends _$PlanOfflineCopy {
  @override
  Future<PlanOfflineState> build(String planId) async {
    final userId = ref.watch(currentUserIdProvider)();
    if (userId == null) return PlanOfflineState.none;
    final at = await ref.read(planOfflineStoreProvider).savedAt(userId, planId);
    return PlanOfflineState(savedAt: at);
  }

  static String regionId(String userId, String planId) =>
      'plan-$userId-$planId';

  /// Saves the copy. Null when it worked, or why it didn't.
  Future<PlanFailure?> download(TripPlan plan) async {
    final userId = ref.read(currentUserIdProvider)();
    final bounds = PlanBounds.of(plan);
    if (userId == null) return const PlanFailure(PlanFailureKind.signedOut);
    if (bounds == null) return const PlanFailure(PlanFailureKind.badInput);
    final before = state.value?.savedAt;
    state = AsyncData(PlanOfflineState(savedAt: before, progress: 0));
    try {
      await ref.read(planOfflineMapProvider).download(
        regionId(userId, plan.id),
        bounds,
        (progress) {
          if (ref.mounted) {
            state = AsyncData(
              PlanOfflineState(savedAt: before, progress: progress),
            );
          }
        },
      );
      await ref.read(planOfflineImagesProvider).prefetch([
        for (final day in plan.days)
          for (final stop in day.stops) ?stop.place.thumbnailUrl,
        for (final idea in plan.places) ?idea.place.thumbnailUrl,
      ]);
    } on Object {
      if (ref.mounted) {
        state = AsyncData(PlanOfflineState(savedAt: before, failed: true));
      }
      return const PlanFailure(PlanFailureKind.offline);
    }
    final now = DateTime.now();
    await ref.read(planOfflineStoreProvider).markSaved(userId, plan.id, now);
    if (ref.mounted) state = AsyncData(PlanOfflineState(savedAt: now));
    return null;
  }

  Future<void> remove() async {
    final userId = ref.read(currentUserIdProvider)();
    if (userId == null) return;
    try {
      await ref.read(planOfflineMapProvider).remove(regionId(userId, planId));
    } on Object {
      // The record goes either way; the tiles expire on their own.
    }
    await ref.read(planOfflineStoreProvider).clear(userId, planId);
    if (ref.mounted) state = const AsyncData(PlanOfflineState.none);
  }
}
