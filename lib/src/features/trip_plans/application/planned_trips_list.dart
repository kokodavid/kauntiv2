import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/application/auth_providers.dart';
import '../domain/planned_trips.dart';
import '../domain/trip_plan_summary.dart';
import 'trip_plans_providers.dart';

part 'planned_trips_list.g.dart';

/// The Planned list and where it came from.
class PlannedTripsView {
  const PlannedTripsView({
    required this.plans,
    this.offline = false,
    this.savedAt,
  });

  final PlannedTrips plans;

  /// Shown from the copy on this phone because the server couldn't be
  /// reached.
  final bool offline;
  final DateTime? savedAt;
}

/// The Planned list. Shows the copy on this phone at once (so the Trips tab
/// doesn't flash empty), then the server's list. Offline, the copy stays
/// with [PlannedTripsView.offline] set. The old planner's saved trips are
/// moved across once per session before the first server read.
@riverpod
class PlannedTripsList extends _$PlannedTripsList {
  /// Accounts whose saved trips were moved across in this session.
  static final _convertedThisSession = <String>{};

  /// Lets a test run the saved-trip conversion again.
  @visibleForTesting
  static void resetSessionForTest() => _convertedThisSession.clear();

  @override
  Future<PlannedTripsView> build() async {
    final userId = ref.watch(currentUserIdProvider)();
    if (userId == null) {
      return const PlannedTripsView(plans: PlannedTrips());
    }
    final cached = await ref.read(tripPlansSnapshotStoreProvider).readList(userId);
    if (cached != null) {
      unawaited(_refreshQuietly(userId));
      return PlannedTripsView(plans: PlannedTrips.split(cached));
    }
    return _fetch(userId);
  }

  /// Pull-to-refresh, and after a change made elsewhere.
  Future<void> refresh() async {
    final userId = ref.read(currentUserIdProvider)();
    if (userId == null) return;
    await _refreshQuietly(userId);
  }

  Future<void> _refreshQuietly(String userId) async {
    try {
      final view = await _fetch(userId);
      if (ref.mounted) state = AsyncData(view);
    } on Object catch (error) {
      developer.log('Planned list refresh failed: $error', name: 'trip_plans');
      final current = state.value;
      if (ref.mounted && current != null) {
        state = AsyncData(
          PlannedTripsView(
            plans: current.plans,
            offline: true,
            savedAt: current.savedAt,
          ),
        );
      }
    }
  }

  Future<PlannedTripsView> _fetch(String userId) async {
    final repository = ref.read(tripPlansRepositoryProvider);
    final store = ref.read(tripPlansSnapshotStoreProvider);
    if (repository == null) {
      return const PlannedTripsView(plans: PlannedTrips());
    }
    if (!_convertedThisSession.contains(userId)) {
      try {
        await repository.convertSavedTrips();
        _convertedThisSession.add(userId);
      } on Object catch (error) {
        developer.log('Saved trip conversion failed: $error', name: 'trip_plans');
      }
    }
    final List<TripPlanSummary> plans;
    try {
      plans = await repository.list();
    } on Object {
      final cached = await store.readList(userId);
      if (cached == null) rethrow;
      return PlannedTripsView(plans: PlannedTrips.split(cached), offline: true);
    }
    final now = DateTime.now();
    await store.writeList(userId, plans, now);
    return PlannedTripsView(plans: PlannedTrips.split(plans), savedAt: now);
  }
}
