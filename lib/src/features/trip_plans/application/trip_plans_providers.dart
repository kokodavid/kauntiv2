import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/services/supabase_client_provider.dart';
import '../../badges/application/badges_providers.dart';
import '../data/supabase_trip_plans_repository.dart';
import '../data/trip_plans_flag_repository.dart';
import '../data/trip_plans_repository.dart';
import '../data/trip_plans_snapshot_store.dart';
import '../domain/plan_limits.dart';

part 'trip_plans_providers.g.dart';

/// The planner's database functions. Null when the build has no Supabase.
@riverpod
TripPlansRepository? tripPlansRepository(Ref ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? null : SupabaseTripPlansRepository(client);
}

@riverpod
TripPlansSnapshotStore tripPlansSnapshotStore(Ref ref) =>
    const TripPlansSnapshotStore();

@Riverpod(keepAlive: true)
TripPlansFlagRepository? tripPlansFlagRepository(Ref ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? null : SupabaseTripPlansFlagRepository(client);
}

/// Whether the dashboard has the planner switched on. Read once at start-up
/// (the Trips tab then shows Planned and Recorded); any failure means off,
/// so the Trips tab stays exactly as it was.
@Riverpod(keepAlive: true)
Future<bool> tripPlansEnabled(Ref ref) async {
  final repository = ref.watch(tripPlansFlagRepositoryProvider);
  if (repository == null) return false;
  try {
    return await repository.isEnabled().timeout(const Duration(seconds: 5));
  } on Object {
    return false;
  }
}

/// Whether invite links are switched on. Read once at start-up; any failure
/// means off, so only username invitations are offered.
@Riverpod(keepAlive: true)
Future<bool> tripPlanLinksEnabled(Ref ref) async {
  final repository = ref.watch(tripPlansFlagRepositoryProvider);
  if (repository == null) return false;
  try {
    return await repository.linksEnabled().timeout(const Duration(seconds: 5));
  } on Object {
    return false;
  }
}

/// The signed-in user's own limits and upcoming-plan count, for the create
/// sheet and "2 of 3 upcoming plans". Free limits when they can't be read.
@riverpod
Future<PlanLimits> myPlanLimits(Ref ref) async {
  final repository = ref.watch(tripPlansRepositoryProvider);
  if (repository == null) return PlanLimits.free;
  try {
    return await repository.myLimits();
  } on Object {
    return PlanLimits.free;
  }
}

/// The counties the signed-in user has claimed, for "new" on routes. Empty
/// when the Passport can't be read, so every county then reads as new.
@riverpod
Future<Set<int>> planClaimedCountyCodes(Ref ref) async {
  try {
    final collection = await ref.watch(badgeCollectionProvider.future);
    return {
      for (final badge in collection.badges)
        if (badge.isEarned) badge.county.code,
    };
  } on Object {
    return <int>{};
  }
}
