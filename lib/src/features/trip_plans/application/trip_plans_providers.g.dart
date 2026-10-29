// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trip_plans_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The planner's database functions. Null when the build has no Supabase.

@ProviderFor(tripPlansRepository)
const tripPlansRepositoryProvider = TripPlansRepositoryProvider._();

/// The planner's database functions. Null when the build has no Supabase.

final class TripPlansRepositoryProvider
    extends
        $FunctionalProvider<
          TripPlansRepository?,
          TripPlansRepository?,
          TripPlansRepository?
        >
    with $Provider<TripPlansRepository?> {
  /// The planner's database functions. Null when the build has no Supabase.
  const TripPlansRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tripPlansRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tripPlansRepositoryHash();

  @$internal
  @override
  $ProviderElement<TripPlansRepository?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TripPlansRepository? create(Ref ref) {
    return tripPlansRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TripPlansRepository? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TripPlansRepository?>(value),
    );
  }
}

String _$tripPlansRepositoryHash() =>
    r'1e521453c96bf8fd186bd35fda5f5c609f36368a';

@ProviderFor(tripPlansSnapshotStore)
const tripPlansSnapshotStoreProvider = TripPlansSnapshotStoreProvider._();

final class TripPlansSnapshotStoreProvider
    extends
        $FunctionalProvider<
          TripPlansSnapshotStore,
          TripPlansSnapshotStore,
          TripPlansSnapshotStore
        >
    with $Provider<TripPlansSnapshotStore> {
  const TripPlansSnapshotStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tripPlansSnapshotStoreProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tripPlansSnapshotStoreHash();

  @$internal
  @override
  $ProviderElement<TripPlansSnapshotStore> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TripPlansSnapshotStore create(Ref ref) {
    return tripPlansSnapshotStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TripPlansSnapshotStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TripPlansSnapshotStore>(value),
    );
  }
}

String _$tripPlansSnapshotStoreHash() =>
    r'bd744d109c8efaf9aa75aa8a002213d414d477e4';

@ProviderFor(tripPlansFlagRepository)
const tripPlansFlagRepositoryProvider = TripPlansFlagRepositoryProvider._();

final class TripPlansFlagRepositoryProvider
    extends
        $FunctionalProvider<
          TripPlansFlagRepository?,
          TripPlansFlagRepository?,
          TripPlansFlagRepository?
        >
    with $Provider<TripPlansFlagRepository?> {
  const TripPlansFlagRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tripPlansFlagRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tripPlansFlagRepositoryHash();

  @$internal
  @override
  $ProviderElement<TripPlansFlagRepository?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TripPlansFlagRepository? create(Ref ref) {
    return tripPlansFlagRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TripPlansFlagRepository? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TripPlansFlagRepository?>(value),
    );
  }
}

String _$tripPlansFlagRepositoryHash() =>
    r'b492c91338350d209b60e0dacbfca28f6ae641dc';

/// Whether the dashboard has the planner switched on. Read once at start-up
/// (the Trips tab then shows Planned and Recorded); any failure means off,
/// so the Trips tab stays exactly as it was.

@ProviderFor(tripPlansEnabled)
const tripPlansEnabledProvider = TripPlansEnabledProvider._();

/// Whether the dashboard has the planner switched on. Read once at start-up
/// (the Trips tab then shows Planned and Recorded); any failure means off,
/// so the Trips tab stays exactly as it was.

final class TripPlansEnabledProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// Whether the dashboard has the planner switched on. Read once at start-up
  /// (the Trips tab then shows Planned and Recorded); any failure means off,
  /// so the Trips tab stays exactly as it was.
  const TripPlansEnabledProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tripPlansEnabledProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tripPlansEnabledHash();

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    return tripPlansEnabled(ref);
  }
}

String _$tripPlansEnabledHash() => r'd848ee8b96480ab2e9442cd16ff712031e2a18a1';

/// The signed-in user's own limits and upcoming-plan count, for the create
/// sheet and "2 of 3 upcoming plans". Free limits when they can't be read.

@ProviderFor(myPlanLimits)
const myPlanLimitsProvider = MyPlanLimitsProvider._();

/// The signed-in user's own limits and upcoming-plan count, for the create
/// sheet and "2 of 3 upcoming plans". Free limits when they can't be read.

final class MyPlanLimitsProvider
    extends
        $FunctionalProvider<
          AsyncValue<PlanLimits>,
          PlanLimits,
          FutureOr<PlanLimits>
        >
    with $FutureModifier<PlanLimits>, $FutureProvider<PlanLimits> {
  /// The signed-in user's own limits and upcoming-plan count, for the create
  /// sheet and "2 of 3 upcoming plans". Free limits when they can't be read.
  const MyPlanLimitsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myPlanLimitsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myPlanLimitsHash();

  @$internal
  @override
  $FutureProviderElement<PlanLimits> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<PlanLimits> create(Ref ref) {
    return myPlanLimits(ref);
  }
}

String _$myPlanLimitsHash() => r'5ad90a3bf17774167404e700c92978f3bd201e58';

/// The counties the signed-in user has claimed, for "new" on routes. Empty
/// when the Passport can't be read, so every county then reads as new.

@ProviderFor(planClaimedCountyCodes)
const planClaimedCountyCodesProvider = PlanClaimedCountyCodesProvider._();

/// The counties the signed-in user has claimed, for "new" on routes. Empty
/// when the Passport can't be read, so every county then reads as new.

final class PlanClaimedCountyCodesProvider
    extends
        $FunctionalProvider<AsyncValue<Set<int>>, Set<int>, FutureOr<Set<int>>>
    with $FutureModifier<Set<int>>, $FutureProvider<Set<int>> {
  /// The counties the signed-in user has claimed, for "new" on routes. Empty
  /// when the Passport can't be read, so every county then reads as new.
  const PlanClaimedCountyCodesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'planClaimedCountyCodesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$planClaimedCountyCodesHash();

  @$internal
  @override
  $FutureProviderElement<Set<int>> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Set<int>> create(Ref ref) {
    return planClaimedCountyCodes(ref);
  }
}

String _$planClaimedCountyCodesHash() =>
    r'0db0bc7ef2084dcbc7f94ca1c6a81473410e472f';
