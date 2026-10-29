import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/plan_collapsed_store.dart';

part 'plan_collapsed_days.g.dart';

@riverpod
PlanCollapsedStore planCollapsedStore(Ref ref) => const PlanCollapsedStore();

/// Which days of a plan are folded, kept per plan on this phone. Null until
/// the person has folded or opened one, so the screen can use its default.
@riverpod
class PlanCollapsedDays extends _$PlanCollapsedDays {
  @override
  Future<Set<int>?> build(String planId) =>
      ref.watch(planCollapsedStoreProvider).read(planId);

  /// Folds or opens [day]. [current] is what the screen is showing now
  /// (the saved set, or its default).
  Future<void> toggle(int day, {required Set<int> current}) async {
    final next = {...current};
    if (!next.remove(day)) next.add(day);
    state = AsyncData(next);
    await ref.read(planCollapsedStoreProvider).write(planId, next);
  }

  /// What the screen shows before anything is saved: a short plan is all
  /// open, a long one has Day 1 open and the rest folded.
  static Set<int> defaultFor(int dayCount) =>
      dayCount <= 3 ? <int>{} : {for (var n = 2; n <= dayCount; n++) n};
}
