import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/services/supabase_client_provider.dart';
import '../data/plan_best_order_client.dart';
import '../domain/plan_day.dart';
import '../domain/plan_day_path.dart';
import '../domain/plan_failure.dart';
import '../domain/trip_plan.dart';
import 'plan_detail.dart';
import 'planned_trips_list.dart';
import 'trip_plans_providers.dart';

part 'plan_best_order.g.dart';

/// The Best order service. Null when the build has no Supabase.
@riverpod
PlanBestOrderClient? planBestOrderClient(Ref ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? null : SupabasePlanBestOrderClient(client);
}

/// What Best order did for a day.
class PlanOrderResult {
  const PlanOrderResult({this.failure, this.previous = const []});

  final PlanFailure? failure;

  /// The stop ids as they were, for Undo. Empty when nothing changed.
  final List<String> previous;

  bool get changed => failure == null && previous.isNotEmpty;
}

/// Best order for a day, and Undo. One run per day at a time, so a double
/// tap doesn't spend the hourly allowance twice.
class PlanBestOrder {
  PlanBestOrder(this._ref);

  final Ref _ref;
  final _running = <String>{};

  Future<PlanOrderResult> run(TripPlan plan, PlanDay day) async {
    final client = _ref.read(planBestOrderClientProvider);
    final repository = _ref.read(tripPlansRepositoryProvider);
    if (client == null || repository == null) {
      return const PlanOrderResult(
        failure: PlanFailure(PlanFailureKind.unavailable),
      );
    }
    final origin =
        PlanDayPath.origin(plan, day) ??
        PlanDayPath.stopPoints(day).firstOrNull;
    if (origin == null || !_running.add(day.id)) return const PlanOrderResult();
    final before = [for (final stop in day.stops) stop.id];
    try {
      final order = await client.order(
        day.id,
        lat: origin.lat,
        lng: origin.lng,
      );
      if (_sameOrder(order, before)) return const PlanOrderResult();
      await repository.setDayOrder(day.id, order);
    } on PlanFailure catch (failure) {
      return PlanOrderResult(failure: failure);
    } on Object {
      return const PlanOrderResult(
        failure: PlanFailure(PlanFailureKind.offline),
      );
    } finally {
      _running.remove(day.id);
    }
    await _refresh(plan.id);
    return PlanOrderResult(previous: before);
  }

  /// Puts the day back as it was.
  Future<PlanFailure?> restore(
    String planId,
    String dayId,
    List<String> stopIds,
  ) async {
    final repository = _ref.read(tripPlansRepositoryProvider);
    if (repository == null)
      return const PlanFailure(PlanFailureKind.unavailable);
    try {
      await repository.setDayOrder(dayId, stopIds);
    } on PlanFailure catch (failure) {
      return failure;
    } on Object {
      return const PlanFailure(PlanFailureKind.offline);
    }
    await _refresh(planId);
    return null;
  }

  Future<void> _refresh(String planId) async {
    if (!_ref.mounted) return;
    await _ref.read(planDetailProvider(planId).notifier).refresh();
    if (_ref.mounted) {
      await _ref.read(plannedTripsListProvider.notifier).refresh();
    }
  }

  static bool _sameOrder(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

@Riverpod(keepAlive: true)
PlanBestOrder planBestOrder(Ref ref) => PlanBestOrder(ref);
