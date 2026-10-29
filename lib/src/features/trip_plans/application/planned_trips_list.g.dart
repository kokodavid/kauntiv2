// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'planned_trips_list.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The Planned list. Shows the copy on this phone at once (so the Trips tab
/// doesn't flash empty), then the server's list. Offline, the copy stays
/// with [PlannedTripsView.offline] set. The old planner's saved trips are
/// moved across once per session before the first server read.

@ProviderFor(PlannedTripsList)
const plannedTripsListProvider = PlannedTripsListProvider._();

/// The Planned list. Shows the copy on this phone at once (so the Trips tab
/// doesn't flash empty), then the server's list. Offline, the copy stays
/// with [PlannedTripsView.offline] set. The old planner's saved trips are
/// moved across once per session before the first server read.
final class PlannedTripsListProvider
    extends $AsyncNotifierProvider<PlannedTripsList, PlannedTripsView> {
  /// The Planned list. Shows the copy on this phone at once (so the Trips tab
  /// doesn't flash empty), then the server's list. Offline, the copy stays
  /// with [PlannedTripsView.offline] set. The old planner's saved trips are
  /// moved across once per session before the first server read.
  const PlannedTripsListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'plannedTripsListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$plannedTripsListHash();

  @$internal
  @override
  PlannedTripsList create() => PlannedTripsList();
}

String _$plannedTripsListHash() => r'91d491ebffe5a4d9e2748486908610c183b6997a';

/// The Planned list. Shows the copy on this phone at once (so the Trips tab
/// doesn't flash empty), then the server's list. Offline, the copy stays
/// with [PlannedTripsView.offline] set. The old planner's saved trips are
/// moved across once per session before the first server read.

abstract class _$PlannedTripsList extends $AsyncNotifier<PlannedTripsView> {
  FutureOr<PlannedTripsView> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref as $Ref<AsyncValue<PlannedTripsView>, PlannedTripsView>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<PlannedTripsView>, PlannedTripsView>,
              AsyncValue<PlannedTripsView>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
