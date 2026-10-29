// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_best_order.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The Best order service. Null when the build has no Supabase.

@ProviderFor(planBestOrderClient)
const planBestOrderClientProvider = PlanBestOrderClientProvider._();

/// The Best order service. Null when the build has no Supabase.

final class PlanBestOrderClientProvider
    extends
        $FunctionalProvider<
          PlanBestOrderClient?,
          PlanBestOrderClient?,
          PlanBestOrderClient?
        >
    with $Provider<PlanBestOrderClient?> {
  /// The Best order service. Null when the build has no Supabase.
  const PlanBestOrderClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'planBestOrderClientProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$planBestOrderClientHash();

  @$internal
  @override
  $ProviderElement<PlanBestOrderClient?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PlanBestOrderClient? create(Ref ref) {
    return planBestOrderClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlanBestOrderClient? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlanBestOrderClient?>(value),
    );
  }
}

String _$planBestOrderClientHash() =>
    r'67cbff360bd497505ff5d109816060a5c32117d3';

@ProviderFor(planBestOrder)
const planBestOrderProvider = PlanBestOrderProvider._();

final class PlanBestOrderProvider
    extends $FunctionalProvider<PlanBestOrder, PlanBestOrder, PlanBestOrder>
    with $Provider<PlanBestOrder> {
  const PlanBestOrderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'planBestOrderProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$planBestOrderHash();

  @$internal
  @override
  $ProviderElement<PlanBestOrder> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PlanBestOrder create(Ref ref) {
    return planBestOrder(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlanBestOrder value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlanBestOrder>(value),
    );
  }
}

String _$planBestOrderHash() => r'6628e726e1b04b36517a1019799cbf1f412a082d';
