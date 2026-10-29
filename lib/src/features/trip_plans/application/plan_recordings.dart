import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/plan_day_recording.dart';
import 'trip_plans_providers.dart';

part 'plan_recordings.g.dart';

/// My recorded Trips for a plan, by day id. Empty when they can't be read,
/// so days simply show Start trip.
@riverpod
Future<Map<String, PlanDayRecording>> planRecordings(
  Ref ref,
  String planId,
) async {
  final repository = ref.watch(tripPlansRepositoryProvider);
  if (repository == null) return const {};
  try {
    return {
      for (final r in await repository.myRecordings(planId)) r.dayId: r,
    };
  } on Object {
    return const {};
  }
}
