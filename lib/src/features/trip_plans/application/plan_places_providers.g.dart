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

/// Places matching [query]; nothing until the query is ready.

@ProviderFor(planPlaceSearch)
const planPlaceSearchProvider = PlanPlaceSearchFamily._();

/// Places matching [query]; nothing until the query is ready.

final class PlanPlaceSearchProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PlanPlace>>,
          List<PlanPlace>,
          FutureOr<List<PlanPlace>>
        >
    with $FutureModifier<List<PlanPlace>>, $FutureProvider<List<PlanPlace>> {
  /// Places matching [query]; nothing until the query is ready.
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

String _$planPlaceSearchHash() => r'671c0c4a8ec030d3a3e31bee36f4feea91df8cc4';

/// Places matching [query]; nothing until the query is ready.

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

  /// Places matching [query]; nothing until the query is ready.

  PlanPlaceSearchProvider call(PlanPlaceQuery query) =>
      PlanPlaceSearchProvider._(argument: query, from: this);

  @override
  String toString() => r'planPlaceSearchProvider';
}

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
