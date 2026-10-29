import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/services/app_current_location.dart';
import '../domain/new_plan_request.dart';
import '../domain/plan_failure.dart';
import 'planned_trips_list.dart';
import 'trip_plans_providers.dart';

part 'create_plan_controller.g.dart';

/// The phone's position for the create sheet's "Current location" start.
/// Null without permission or a fix (design 2c: the plan can still be
/// made; the start becomes "where you are when you start").
@riverpod
Future<AppLocationFix?> planCurrentLocation(Ref ref) =>
    AppCurrentLocation.read();

/// Creates a plan from the create sheet. The state is loading while the
/// server works; a refusal (a Free limit, offline) comes back as a
/// [PlanFailure] from [create] for the sheet to explain.
@riverpod
class CreatePlanController extends _$CreatePlanController {
  @override
  bool build() => false;

  /// Returns the new plan's id.
  Future<String> create(NewPlanRequest request) async {
    final repository = ref.read(tripPlansRepositoryProvider);
    if (repository == null) {
      throw const PlanFailure(PlanFailureKind.unavailable);
    }
    if (state) throw const PlanFailure(PlanFailureKind.badInput);
    state = true;
    try {
      final id = await repository.create(request);
      ref.invalidate(myPlanLimitsProvider);
      await ref.read(plannedTripsListProvider.notifier).refresh();
      return id;
    } finally {
      if (ref.mounted) state = false;
    }
  }
}
