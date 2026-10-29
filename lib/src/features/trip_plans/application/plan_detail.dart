import 'dart:async';
import 'dart:developer' as developer;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/application/auth_providers.dart';
import '../domain/plan_failure.dart';
import '../domain/trip_plan.dart';
import 'trip_plans_providers.dart';

part 'plan_detail.g.dart';

/// One plan as the plan screen shows it, and where it came from.
class PlanDetailView {
  const PlanDetailView({
    required this.plan,
    this.offline = false,
    this.savedAt,
  });

  final TripPlan plan;

  /// Shown from the copy on this phone because the server couldn't be
  /// reached. Read-only (decision D4).
  final bool offline;
  final DateTime? savedAt;
}

/// A plan by id. Shows the copy on this phone at once, then the server's
/// plan; offline, the copy stays with [PlanDetailView.offline] set. A plan
/// the server no longer knows (deleted, or you were removed) is an error
/// with [PlanFailureKind.notFound] and its copy is dropped.
@riverpod
class PlanDetail extends _$PlanDetail {
  @override
  Future<PlanDetailView> build(String planId) async {
    final userId = ref.watch(currentUserIdProvider)();
    final repository = ref.watch(tripPlansRepositoryProvider);
    if (userId == null || repository == null) {
      throw const PlanFailure(PlanFailureKind.signedOut);
    }
    final store = ref.watch(tripPlansSnapshotStoreProvider);
    final cached = await store.readPlan(userId, planId);
    if (cached != null) {
      unawaited(_refreshQuietly(userId));
      return PlanDetailView(
        plan: cached,
        savedAt: await store.planSavedAt(userId, planId),
      );
    }
    return _fetch(userId);
  }

  /// Pull-to-refresh, and after a change.
  Future<void> refresh() async {
    final userId = ref.read(currentUserIdProvider)();
    if (userId == null) return;
    await _refreshQuietly(userId);
  }

  Future<void> _refreshQuietly(String userId) async {
    try {
      final view = await _fetch(userId);
      if (ref.mounted) state = AsyncData(view);
    } on PlanFailure catch (failure) {
      if (ref.mounted && failure.kind == PlanFailureKind.notFound) {
        state = AsyncError(failure, StackTrace.current);
      }
    } on Object catch (error) {
      developer.log('Plan refresh failed: $error', name: 'trip_plans');
    }
  }

  Future<PlanDetailView> _fetch(String userId) async {
    final repository = ref.read(tripPlansRepositoryProvider)!;
    final store = ref.read(tripPlansSnapshotStoreProvider);
    final TripPlan plan;
    try {
      plan = await repository.get(planId);
    } on PlanFailure catch (failure) {
      if (failure.kind == PlanFailureKind.notFound) {
        await store.removePlan(userId, planId);
        rethrow;
      }
      return _offlineOrThrow(userId, failure);
    } on Object catch (error) {
      return _offlineOrThrow(userId, error);
    }
    final now = DateTime.now();
    await store.writePlan(userId, plan, now);
    return PlanDetailView(plan: plan, savedAt: now);
  }

  Future<PlanDetailView> _offlineOrThrow(String userId, Object error) async {
    final store = ref.read(tripPlansSnapshotStoreProvider);
    final cached = await store.readPlan(userId, planId);
    if (cached == null) throw error;
    return PlanDetailView(
      plan: cached,
      offline: true,
      savedAt: await store.planSavedAt(userId, planId),
    );
  }
}
