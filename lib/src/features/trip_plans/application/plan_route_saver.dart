import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/plan_day.dart';
import '../domain/plan_day_path.dart';
import '../domain/plan_route.dart';
import 'planned_trips_list.dart';
import 'trip_plans_providers.dart';

part 'plan_route_saver.g.dart';

/// Saves a day's worked-out distance, time and counties on the server, so
/// the Planned list and other members' phones show them without asking the
/// routing service again. Best effort: a refusal (the day changed meanwhile)
/// or a lost connection just means the next open saves it.
class PlanRouteSaver {
  PlanRouteSaver(this._ref);

  final Ref _ref;
  final _sent = <String>{};

  Future<void> save(PlanDay day, PlanRoute route) async {
    final repository = _ref.read(tripPlansRepositoryProvider);
    if (repository == null || day.hasFreshRoute) return;
    final key = '${day.id}|${day.stopsKey}';
    if (!_sent.add(key)) return;
    try {
      await repository.saveDayRoute(
        day.id,
        stopsKey: day.stopsKey,
        distanceM: route.distanceM,
        durationS: route.durationS,
        countyCodes: PlanDayPath.counties(day),
      );
      if (_ref.mounted) {
        unawaited(_ref.read(plannedTripsListProvider.notifier).refresh());
      }
    } on Object {
      _sent.remove(key);
    }
  }
}

@Riverpod(keepAlive: true)
PlanRouteSaver planRouteSaver(Ref ref) => PlanRouteSaver(ref);
