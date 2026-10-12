// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trip_planner_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(directionsClient)
const directionsClientProvider = DirectionsClientProvider._();

final class DirectionsClientProvider
    extends
        $FunctionalProvider<
          MapboxDirectionsClient,
          MapboxDirectionsClient,
          MapboxDirectionsClient
        >
    with $Provider<MapboxDirectionsClient> {
  const DirectionsClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'directionsClientProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$directionsClientHash();

  @$internal
  @override
  $ProviderElement<MapboxDirectionsClient> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MapboxDirectionsClient create(Ref ref) {
    return directionsClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MapboxDirectionsClient value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MapboxDirectionsClient>(value),
    );
  }
}

String _$directionsClientHash() => r'c83f0c6a7fef11c4c3f9142fe363a6372079b4e6';

/// The county boundaries, parsed once.

@ProviderFor(countyShapes)
const countyShapesProvider = CountyShapesProvider._();

/// The county boundaries, parsed once.

final class CountyShapesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CountyShape>>,
          List<CountyShape>,
          FutureOr<List<CountyShape>>
        >
    with
        $FutureModifier<List<CountyShape>>,
        $FutureProvider<List<CountyShape>> {
  /// The county boundaries, parsed once.
  const CountyShapesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'countyShapesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$countyShapesHash();

  @$internal
  @override
  $FutureProviderElement<List<CountyShape>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<CountyShape>> create(Ref ref) {
    return countyShapes(ref);
  }
}

String _$countyShapesHash() => r'5efd907776bdecfbf392d898a40dcf1eda775b6c';

/// Every place the planner can suggest, read once and kept.

@ProviderFor(placesCatalog)
const placesCatalogProvider = PlacesCatalogProvider._();

/// Every place the planner can suggest, read once and kept.

final class PlacesCatalogProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MapPlace>>,
          List<MapPlace>,
          FutureOr<List<MapPlace>>
        >
    with $FutureModifier<List<MapPlace>>, $FutureProvider<List<MapPlace>> {
  /// Every place the planner can suggest, read once and kept.
  const PlacesCatalogProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'placesCatalogProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$placesCatalogHash();

  @$internal
  @override
  $FutureProviderElement<List<MapPlace>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<MapPlace>> create(Ref ref) {
    return placesCatalog(ref);
  }
}

String _$placesCatalogHash() => r'b728fbab5880911f5c273b0aed3a4e70548c961d';

/// Where the user is, read once for the page and shared by the plan.

@ProviderFor(tripOrigin)
const tripOriginProvider = TripOriginProvider._();

/// Where the user is, read once for the page and shared by the plan.

final class TripOriginProvider
    extends
        $FunctionalProvider<
          AsyncValue<TripRoutePoint?>,
          TripRoutePoint?,
          FutureOr<TripRoutePoint?>
        >
    with $FutureModifier<TripRoutePoint?>, $FutureProvider<TripRoutePoint?> {
  /// Where the user is, read once for the page and shared by the plan.
  const TripOriginProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tripOriginProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tripOriginHash();

  @$internal
  @override
  $FutureProviderElement<TripRoutePoint?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<TripRoutePoint?> create(Ref ref) {
    return tripOrigin(ref);
  }
}

String _$tripOriginHash() => r'7639d42515232d77cd3e3b237832ee39ae7155c1';

/// The places picked as stops on the way to [placeId], in the order they
/// were picked. The planner orders them for the road.

@ProviderFor(TripStops)
const tripStopsProvider = TripStopsFamily._();

/// The places picked as stops on the way to [placeId], in the order they
/// were picked. The planner orders them for the road.
final class TripStopsProvider
    extends $NotifierProvider<TripStops, List<MapPlace>> {
  /// The places picked as stops on the way to [placeId], in the order they
  /// were picked. The planner orders them for the road.
  const TripStopsProvider._({
    required TripStopsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'tripStopsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$tripStopsHash();

  @override
  String toString() {
    return r'tripStopsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  TripStops create() => TripStops();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<MapPlace> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<MapPlace>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TripStopsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$tripStopsHash() => r'a25569a373431bd403a0d62270f39c45695fa683';

/// The places picked as stops on the way to [placeId], in the order they
/// were picked. The planner orders them for the road.

final class TripStopsFamily extends $Family
    with
        $ClassFamilyOverride<
          TripStops,
          List<MapPlace>,
          List<MapPlace>,
          List<MapPlace>,
          String
        > {
  const TripStopsFamily._()
    : super(
        retry: null,
        name: r'tripStopsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The places picked as stops on the way to [placeId], in the order they
  /// were picked. The planner orders them for the road.

  TripStopsProvider call(String placeId) =>
      TripStopsProvider._(argument: placeId, from: this);

  @override
  String toString() => r'tripStopsProvider';
}

/// The places picked as stops on the way to [placeId], in the order they
/// were picked. The planner orders them for the road.

abstract class _$TripStops extends $Notifier<List<MapPlace>> {
  late final _$args = ref.$arg as String;
  String get placeId => _$args;

  List<MapPlace> build(String placeId);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args);
    final ref = this.ref as $Ref<List<MapPlace>, List<MapPlace>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<MapPlace>, List<MapPlace>>,
              List<MapPlace>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// True once the user has set the stop order themselves; false while the
/// planner picks the shortest order.

@ProviderFor(TripCustomOrder)
const tripCustomOrderProvider = TripCustomOrderFamily._();

/// True once the user has set the stop order themselves; false while the
/// planner picks the shortest order.
final class TripCustomOrderProvider
    extends $NotifierProvider<TripCustomOrder, bool> {
  /// True once the user has set the stop order themselves; false while the
  /// planner picks the shortest order.
  const TripCustomOrderProvider._({
    required TripCustomOrderFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'tripCustomOrderProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$tripCustomOrderHash();

  @override
  String toString() {
    return r'tripCustomOrderProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  TripCustomOrder create() => TripCustomOrder();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TripCustomOrderProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$tripCustomOrderHash() => r'dc6cf89d52aa5838342b6c3e2d3cbeaf2c7e34f8';

/// True once the user has set the stop order themselves; false while the
/// planner picks the shortest order.

final class TripCustomOrderFamily extends $Family
    with $ClassFamilyOverride<TripCustomOrder, bool, bool, bool, String> {
  const TripCustomOrderFamily._()
    : super(
        retry: null,
        name: r'tripCustomOrderProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// True once the user has set the stop order themselves; false while the
  /// planner picks the shortest order.

  TripCustomOrderProvider call(String placeId) =>
      TripCustomOrderProvider._(argument: placeId, from: this);

  @override
  String toString() => r'tripCustomOrderProvider';
}

/// True once the user has set the stop order themselves; false while the
/// planner picks the shortest order.

abstract class _$TripCustomOrder extends $Notifier<bool> {
  late final _$args = ref.$arg as String;
  String get placeId => _$args;

  bool build(String placeId);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args);
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// The driving route from where the user is, through [stopIds] (comma
/// separated place ids, in driving order when it starts with "!"; else
/// the planner puts them in driving order), to a
/// place, and the counties it passes through. Fails with a
/// [TripRouteException] that is fit to show.

@ProviderFor(tripPlan)
const tripPlanProvider = TripPlanFamily._();

/// The driving route from where the user is, through [stopIds] (comma
/// separated place ids, in driving order when it starts with "!"; else
/// the planner puts them in driving order), to a
/// place, and the counties it passes through. Fails with a
/// [TripRouteException] that is fit to show.

final class TripPlanProvider
    extends
        $FunctionalProvider<AsyncValue<TripPlan>, TripPlan, FutureOr<TripPlan>>
    with $FutureModifier<TripPlan>, $FutureProvider<TripPlan> {
  /// The driving route from where the user is, through [stopIds] (comma
  /// separated place ids, in driving order when it starts with "!"; else
  /// the planner puts them in driving order), to a
  /// place, and the counties it passes through. Fails with a
  /// [TripRouteException] that is fit to show.
  const TripPlanProvider._({
    required TripPlanFamily super.from,
    required (double, double, String) super.argument,
  }) : super(
         retry: null,
         name: r'tripPlanProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$tripPlanHash();

  @override
  String toString() {
    return r'tripPlanProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<TripPlan> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<TripPlan> create(Ref ref) {
    final argument = this.argument as (double, double, String);
    return tripPlan(ref, argument.$1, argument.$2, argument.$3);
  }

  @override
  bool operator ==(Object other) {
    return other is TripPlanProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$tripPlanHash() => r'db4b26547eda3fcfe4bac245b5c9fd7f325debd7';

/// The driving route from where the user is, through [stopIds] (comma
/// separated place ids, in driving order when it starts with "!"; else
/// the planner puts them in driving order), to a
/// place, and the counties it passes through. Fails with a
/// [TripRouteException] that is fit to show.

final class TripPlanFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<TripPlan>,
          (double, double, String)
        > {
  const TripPlanFamily._()
    : super(
        retry: null,
        name: r'tripPlanProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The driving route from where the user is, through [stopIds] (comma
  /// separated place ids, in driving order when it starts with "!"; else
  /// the planner puts them in driving order), to a
  /// place, and the counties it passes through. Fails with a
  /// [TripRouteException] that is fit to show.

  TripPlanProvider call(double destLat, double destLng, String stopIds) =>
      TripPlanProvider._(argument: (destLat, destLng, stopIds), from: this);

  @override
  String toString() => r'tripPlanProvider';
}

/// The counties the signed-in user has claimed. Empty when the badge
/// collection cannot be read, so every county then reads as new.

@ProviderFor(claimedCountyCodes)
const claimedCountyCodesProvider = ClaimedCountyCodesProvider._();

/// The counties the signed-in user has claimed. Empty when the badge
/// collection cannot be read, so every county then reads as new.

final class ClaimedCountyCodesProvider
    extends
        $FunctionalProvider<AsyncValue<Set<int>>, Set<int>, FutureOr<Set<int>>>
    with $FutureModifier<Set<int>>, $FutureProvider<Set<int>> {
  /// The counties the signed-in user has claimed. Empty when the badge
  /// collection cannot be read, so every county then reads as new.
  const ClaimedCountyCodesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'claimedCountyCodesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$claimedCountyCodesHash();

  @$internal
  @override
  $FutureProviderElement<Set<int>> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Set<int>> create(Ref ref) {
    return claimedCountyCodes(ref);
  }
}

String _$claimedCountyCodesHash() =>
    r'4d3470daa8bd24f3703d2496cc7c6aa41a6aa812';

/// The places nearest a place, for "Also near here". Empty without Supabase.

@ProviderFor(nearbyPlaces)
const nearbyPlacesProvider = NearbyPlacesFamily._();

/// The places nearest a place, for "Also near here". Empty without Supabase.

final class NearbyPlacesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<NearbyPlace>>,
          List<NearbyPlace>,
          FutureOr<List<NearbyPlace>>
        >
    with
        $FutureModifier<List<NearbyPlace>>,
        $FutureProvider<List<NearbyPlace>> {
  /// The places nearest a place, for "Also near here". Empty without Supabase.
  const NearbyPlacesProvider._({
    required NearbyPlacesFamily super.from,
    required (String, double, double) super.argument,
  }) : super(
         retry: null,
         name: r'nearbyPlacesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$nearbyPlacesHash();

  @override
  String toString() {
    return r'nearbyPlacesProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<NearbyPlace>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<NearbyPlace>> create(Ref ref) {
    final argument = this.argument as (String, double, double);
    return nearbyPlaces(ref, argument.$1, argument.$2, argument.$3);
  }

  @override
  bool operator ==(Object other) {
    return other is NearbyPlacesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$nearbyPlacesHash() => r'ace02329433b31977f1ae866ef48c4ccb3a20df9';

/// The places nearest a place, for "Also near here". Empty without Supabase.

final class NearbyPlacesFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<NearbyPlace>>,
          (String, double, double)
        > {
  const NearbyPlacesFamily._()
    : super(
        retry: null,
        name: r'nearbyPlacesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The places nearest a place, for "Also near here". Empty without Supabase.

  NearbyPlacesProvider call(String placeId, double lat, double lng) =>
      NearbyPlacesProvider._(argument: (placeId, lat, lng), from: this);

  @override
  String toString() => r'nearbyPlacesProvider';
}
