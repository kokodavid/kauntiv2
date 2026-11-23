// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'planned_trips_list.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PlannedTripsList)
const plannedTripsListProvider = PlannedTripsListProvider._();

final class PlannedTripsListProvider
    extends $AsyncNotifierProvider<PlannedTripsList, PlannedTripsView> {
  const PlannedTripsListProvider._()
    : super(
        from: null,
        argument: null,
        retry: _plannedTripsRetry,
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

String _$plannedTripsListHash() => r'a4c4c5fb67146afe1ff4624b171491f15a87eccf';

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
