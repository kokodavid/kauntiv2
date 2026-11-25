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

@ProviderFor(planDayRoute)
const planDayRouteProvider = PlanDayRouteFamily._();

final class PlanDayRouteProvider
    extends
        $FunctionalProvider<
          AsyncValue<PlanRoute?>,
          PlanRoute?,
          FutureOr<PlanRoute?>
        >
    with $FutureModifier<PlanRoute?>, $FutureProvider<PlanRoute?> {
  const PlanDayRouteProvider._({
    required PlanDayRouteFamily super.from,
    required PlanLegRequest super.argument,
  }) : super(
         retry: _planDayRouteRetry,
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

String _$planDayRouteHash() => r'8a7991548f3e03fed9ba91e7b8edac47bbe29680';

final class PlanDayRouteFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<PlanRoute?>, PlanLegRequest> {
  const PlanDayRouteFamily._()
    : super(
        retry: _planDayRouteRetry,
        name: r'planDayRouteProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PlanDayRouteProvider call(PlanLegRequest request) =>
      PlanDayRouteProvider._(argument: request, from: this);

  @override
  String toString() => r'planDayRouteProvider';
}
