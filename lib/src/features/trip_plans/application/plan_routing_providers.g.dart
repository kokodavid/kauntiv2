// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_routing_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The routing service. Null in a build without a Mapbox token, where days
/// simply show no road.

@ProviderFor(planRoutingClient)
const planRoutingClientProvider = PlanRoutingClientProvider._();

/// The routing service. Null in a build without a Mapbox token, where days
/// simply show no road.

final class PlanRoutingClientProvider
    extends
        $FunctionalProvider<
          PlanRoutingClient?,
          PlanRoutingClient?,
          PlanRoutingClient?
        >
    with $Provider<PlanRoutingClient?> {
  /// The routing service. Null in a build without a Mapbox token, where days
  /// simply show no road.
  const PlanRoutingClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'planRoutingClientProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$planRoutingClientHash();

  @$internal
  @override
  $ProviderElement<PlanRoutingClient?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PlanRoutingClient? create(Ref ref) {
    return planRoutingClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlanRoutingClient? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlanRoutingClient?>(value),
    );
  }
}

String _$planRoutingClientHash() => r'c28e3cb29eed21b439f851e2448502c62a47dc75';

/// The road for one day's points. Waits a moment first, so a burst of edits
/// asks once; a good answer is kept for the session, keyed by the points,
/// so the same stops never ask twice. A failure is not kept, so Retry (an
/// invalidate) asks again. Null when there is nothing to route.

@ProviderFor(planDayRoute)
const planDayRouteProvider = PlanDayRouteFamily._();

/// The road for one day's points. Waits a moment first, so a burst of edits
/// asks once; a good answer is kept for the session, keyed by the points,
/// so the same stops never ask twice. A failure is not kept, so Retry (an
/// invalidate) asks again. Null when there is nothing to route.

final class PlanDayRouteProvider
    extends
        $FunctionalProvider<
          AsyncValue<PlanRoute?>,
          PlanRoute?,
          FutureOr<PlanRoute?>
        >
    with $FutureModifier<PlanRoute?>, $FutureProvider<PlanRoute?> {
  /// The road for one day's points. Waits a moment first, so a burst of edits
  /// asks once; a good answer is kept for the session, keyed by the points,
  /// so the same stops never ask twice. A failure is not kept, so Retry (an
  /// invalidate) asks again. Null when there is nothing to route.
  const PlanDayRouteProvider._({
    required PlanDayRouteFamily super.from,
    required PlanLegRequest super.argument,
  }) : super(
         retry: null,
         name: r'planDayRouteProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$planDayRouteHash();

  @override
  String toString() {
    return r'planDayRouteProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<PlanRoute?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<PlanRoute?> create(Ref ref) {
    final argument = this.argument as PlanLegRequest;
    return planDayRoute(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PlanDayRouteProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$planDayRouteHash() => r'f2712be61dcf3d90506a66fe857a514c893c11c9';

/// The road for one day's points. Waits a moment first, so a burst of edits
/// asks once; a good answer is kept for the session, keyed by the points,
/// so the same stops never ask twice. A failure is not kept, so Retry (an
/// invalidate) asks again. Null when there is nothing to route.

final class PlanDayRouteFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<PlanRoute?>, PlanLegRequest> {
  const PlanDayRouteFamily._()
    : super(
        retry: null,
        name: r'planDayRouteProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The road for one day's points. Waits a moment first, so a burst of edits
  /// asks once; a good answer is kept for the session, keyed by the points,
  /// so the same stops never ask twice. A failure is not kept, so Retry (an
  /// invalidate) asks again. Null when there is nothing to route.

  PlanDayRouteProvider call(PlanLegRequest request) =>
      PlanDayRouteProvider._(argument: request, from: this);

  @override
  String toString() => r'planDayRouteProvider';
}
