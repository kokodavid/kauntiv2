import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/plan_day.dart';
import '../domain/plan_failure.dart';
import 'plan_detail.dart';
import 'planned_trips_list.dart';
import 'trip_plans_providers.dart';

part 'plan_editor.g.dart';

/// Every change to a plan from the plan screen. Each call goes to the
/// server (which checks role and limits), then the plan and the Planned
/// list are read again. Returns null when it worked, or why it didn't.
class PlanEditor {
  PlanEditor(this._ref);

  final Ref _ref;

  Future<PlanFailure?> _run(String planId, Future<void> Function() change) async {
    final repository = _ref.read(tripPlansRepositoryProvider);
    if (repository == null) return const PlanFailure(PlanFailureKind.unavailable);
    try {
      await change();
    } on PlanFailure catch (failure) {
      return failure;
    } on Object {
      return const PlanFailure(PlanFailureKind.offline);
    }
    if (_ref.mounted) {
      await _ref.read(planDetailProvider(planId).notifier).refresh();
      await _ref.read(plannedTripsListProvider.notifier).refresh();
    }
    return null;
  }

  Future<PlanFailure?> rename(String planId, String title) =>
      _run(planId, () => _ref.read(tripPlansRepositoryProvider)!.rename(planId, title.trim()));

  Future<PlanFailure?> setStartDate(String planId, DateTime? date) => _run(
    planId,
    () => _ref.read(tripPlansRepositoryProvider)!.setStartDate(planId, date),
  );

  Future<PlanFailure?> archive(String planId) => _run(
    planId,
    () => _ref.read(tripPlansRepositoryProvider)!.archive(planId, archived: true),
  );

  Future<PlanFailure?> unarchive(String planId) => _run(
    planId,
    () =>
        _ref.read(tripPlansRepositoryProvider)!.archive(planId, archived: false),
  );

  Future<PlanFailure?> delete(String planId) => _run(
    planId,
    () => _ref.read(tripPlansRepositoryProvider)!.delete(planId),
  );

  Future<PlanFailure?> addDay(String planId, {String? afterDayId}) => _run(
    planId,
    () => _ref
        .read(tripPlansRepositoryProvider)!
        .addDay(planId, afterDayId: afterDayId),
  );

  Future<PlanFailure?> removeDay(String planId, String dayId) => _run(
    planId,
    () => _ref.read(tripPlansRepositoryProvider)!.removeDay(dayId),
  );

  Future<PlanFailure?> renameDay(String planId, String dayId, String? title) =>
      _run(
        planId,
        () => _ref.read(tripPlansRepositoryProvider)!.renameDay(
          dayId,
          title == null || title.trim().isEmpty ? null : title.trim(),
        ),
      );

  /// One place earlier ([delta] -1) or later (+1) on the same day.
  Future<PlanFailure?> nudgeStop(String planId, PlanDay day, int index, int delta) {
    final stops = day.stops;
    final target = index + delta;
    if (target < 0 || target >= stops.length) return Future.value();
    // The stop goes in front of the one now at the spot after it.
    final after = delta < 0 ? target : target + 1;
    final before = after < stops.length ? stops[after].id : null;
    return _run(
      planId,
      () => _ref
          .read(tripPlansRepositoryProvider)!
          .moveStop(stops[index].id, day.id, beforeStopId: before),
    );
  }

  /// To the end of [toDayId].
  Future<PlanFailure?> moveStopToDay(String planId, String stopId, String toDayId) =>
      _run(
        planId,
        () => _ref.read(tripPlansRepositoryProvider)!.moveStop(stopId, toDayId),
      );

  Future<PlanFailure?> removeStop(
    String planId,
    String stopId, {
    bool toPlacesList = false,
  }) => _run(
    planId,
    () => _ref
        .read(tripPlansRepositoryProvider)!
        .removeStop(stopId, toPlacesList: toPlacesList),
  );

  Future<PlanFailure?> setNote(String planId, String stopId, String? note) =>
      _run(
        planId,
        () => _ref.read(tripPlansRepositoryProvider)!.setStopNote(
          stopId,
          note == null || note.trim().isEmpty ? null : note.trim(),
        ),
      );

  /// A place onto the end of [dayId]. Returns the new stop's id for Undo.
  Future<(PlanFailure?, String?)> addStop(
    String planId,
    String dayId,
    String placeId,
  ) async {
    String? stopId;
    final failure = await _run(planId, () async {
      stopId = await _ref
          .read(tripPlansRepositoryProvider)!
          .addStop(dayId, placeId);
    });
    return (failure, stopId);
  }

  /// A place onto Places to visit.
  Future<PlanFailure?> addToList(String planId, String placeId) => _run(
    planId,
    () => _ref.read(tripPlansRepositoryProvider)!.addPlace(planId, placeId),
  );

  /// A place from Places to visit onto the end of [dayId].
  Future<PlanFailure?> addIdeaToDay(String planId, String dayId, String placeId) =>
      _run(
        planId,
        // The server takes the place off Places to visit as it adds it.
        () => _ref.read(tripPlansRepositoryProvider)!.addStop(dayId, placeId),
      );

  Future<PlanFailure?> removeIdea(String planId, String placeId) => _run(
    planId,
    () => _ref.read(tripPlansRepositoryProvider)!.removePlace(planId, placeId),
  );
}

@Riverpod(keepAlive: true)
PlanEditor planEditor(Ref ref) => PlanEditor(ref);
