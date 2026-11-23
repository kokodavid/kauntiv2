// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_places_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(planPlacesRepository)
const planPlacesRepositoryProvider = PlanPlacesRepositoryProvider._();

final class PlanPlacesRepositoryProvider
    extends
        $FunctionalProvider<
          PlanPlacesRepository?,
          PlanPlacesRepository?,
          PlanPlacesRepository?
        >
    with $Provider<PlanPlacesRepository?> {
  const PlanPlacesRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'planPlacesRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$planPlacesRepositoryHash();

  @$internal
  @override
  $ProviderElement<PlanPlacesRepository?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PlanPlacesRepository? create(Ref ref) {
    return planPlacesRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlanPlacesRepository? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlanPlacesRepository?>(value),
    );
  }
}

String _$planPlacesRepositoryHash() =>
    r'338432097e12443b4918a2f2f6da8dcca0631d02';

/// Places matching [query]; every place when it asks for nothing.

@ProviderFor(planPlaceSearch)
const planPlaceSearchProvider = PlanPlaceSearchFamily._();

/// Places matching [query]; every place when it asks for nothing.

final class PlanPlaceSearchProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PlanPlace>>,
          List<PlanPlace>,
          FutureOr<List<PlanPlace>>
        >
    with $FutureModifier<List<PlanPlace>>, $FutureProvider<List<PlanPlace>> {
  /// Places matching [query]; every place when it asks for nothing.
  const PlanPlaceSearchProvider._({
    required PlanPlaceSearchFamily super.from,
    required PlanPlaceQuery super.argument,
  }) : super(
         retry: null,
         name: r'planPlaceSearchProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$planPlaceSearchHash();

  @override
  String toString() {
    return r'planPlaceSearchProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<PlanPlace>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<PlanPlace>> create(Ref ref) {
    final argument = this.argument as PlanPlaceQuery;
    return planPlaceSearch(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PlanPlaceSearchProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$planPlaceSearchHash() => r'b2e792ec978485170298ab929ecc72c17a22a671';

/// Places matching [query]; every place when it asks for nothing.

final class PlanPlaceSearchFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<PlanPlace>>, PlanPlaceQuery> {
  const PlanPlaceSearchFamily._()
    : super(
        retry: null,
        name: r'planPlaceSearchProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Places matching [query]; every place when it asks for nothing.

  PlanPlaceSearchProvider call(PlanPlaceQuery query) =>
      PlanPlaceSearchProvider._(argument: query, from: this);

  @override
  String toString() => r'planPlaceSearchProvider';
}

/// Which types and counties have places, for the filter chips.

@ProviderFor(planPlaceFacets)
const planPlaceFacetsProvider = PlanPlaceFacetsProvider._();

/// Which types and counties have places, for the filter chips.

final class PlanPlaceFacetsProvider
    extends
        $FunctionalProvider<
          AsyncValue<PlanPlaceFacets>,
          PlanPlaceFacets,
          FutureOr<PlanPlaceFacets>
        >
    with $FutureModifier<PlanPlaceFacets>, $FutureProvider<PlanPlaceFacets> {
  /// Which types and counties have places, for the filter chips.
  const PlanPlaceFacetsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'planPlaceFacetsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$planPlaceFacetsHash();

  @$internal
  @override
  $FutureProviderElement<PlanPlaceFacets> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PlanPlaceFacets> create(Ref ref) {
    return planPlaceFacets(ref);
  }
}

String _$planPlaceFacetsHash() => r'1455fc6e6e0c91ab97288a51ab91c23371d1c185';

/// The plans that already hold [placeId], for "In 2 trips". Empty when it
/// can't be read, so the button simply says "Add to trip".

@ProviderFor(placeTrips)
const placeTripsProvider = PlaceTripsFamily._();

/// The plans that already hold [placeId], for "In 2 trips". Empty when it
/// can't be read, so the button simply says "Add to trip".

final class PlaceTripsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PlanRef>>,
          List<PlanRef>,
          FutureOr<List<PlanRef>>
        >
    with $FutureModifier<List<PlanRef>>, $FutureProvider<List<PlanRef>> {
  /// The plans that already hold [placeId], for "In 2 trips". Empty when it
  /// can't be read, so the button simply says "Add to trip".
  const PlaceTripsProvider._({
    required PlaceTripsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'placeTripsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$placeTripsHash();

  @override
  String toString() {
    return r'placeTripsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<PlanRef>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<PlanRef>> create(Ref ref) {
    final argument = this.argument as String;
    return placeTrips(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PlaceTripsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$placeTripsHash() => r'b13495aaddd7e0a44ea2f709bd4830d744dfe24e';

/// The plans that already hold [placeId], for "In 2 trips". Empty when it
/// can't be read, so the button simply says "Add to trip".

final class PlaceTripsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<PlanRef>>, String> {
  const PlaceTripsFamily._()
    : super(
        retry: null,
        name: r'placeTripsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The plans that already hold [placeId], for "In 2 trips". Empty when it
  /// can't be read, so the button simply says "Add to trip".

  PlaceTripsProvider call(String placeId) =>
      PlaceTripsProvider._(argument: placeId, from: this);

  @override
  String toString() => r'placeTripsProvider';
}
