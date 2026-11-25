// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_route_saver.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(planRouteSaver)
const planRouteSaverProvider = PlanRouteSaverProvider._();

final class PlanRouteSaverProvider
    extends $FunctionalProvider<PlanRouteSaver, PlanRouteSaver, PlanRouteSaver>
    with $Provider<PlanRouteSaver> {
  const PlanRouteSaverProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'planRouteSaverProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$planRouteSaverHash();

  @$internal
  @override
  $ProviderElement<PlanRouteSaver> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PlanRouteSaver create(Ref ref) {
    return planRouteSaver(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlanRouteSaver value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlanRouteSaver>(value),
    );
  }
}

String _$planRouteSaverHash() => r'956115b2b2f560f000965a415288f8244ed793df';
