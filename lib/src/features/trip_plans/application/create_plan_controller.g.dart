// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_plan_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The phone's position for the create sheet's "Current location" start.
/// Null without permission or a fix (design 2c: the plan can still be
/// made; the start becomes "where you are when you start").

@ProviderFor(planCurrentLocation)
const planCurrentLocationProvider = PlanCurrentLocationProvider._();

/// The phone's position for the create sheet's "Current location" start.
/// Null without permission or a fix (design 2c: the plan can still be
/// made; the start becomes "where you are when you start").

final class PlanCurrentLocationProvider
    extends
        $FunctionalProvider<
          AsyncValue<AppLocationFix?>,
          AppLocationFix?,
          FutureOr<AppLocationFix?>
        >
    with $FutureModifier<AppLocationFix?>, $FutureProvider<AppLocationFix?> {
  /// The phone's position for the create sheet's "Current location" start.
  /// Null without permission or a fix (design 2c: the plan can still be
  /// made; the start becomes "where you are when you start").
  const PlanCurrentLocationProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'planCurrentLocationProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$planCurrentLocationHash();

  @$internal
  @override
  $FutureProviderElement<AppLocationFix?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<AppLocationFix?> create(Ref ref) {
    return planCurrentLocation(ref);
  }
}

String _$planCurrentLocationHash() =>
    r'5883e6ea142e18ebf955d1ee67d8111225221c3e';

/// Creates a plan from the create sheet. The state is loading while the
/// server works; a refusal (a Free limit, offline) comes back as a
/// [PlanFailure] from [create] for the sheet to explain.

@ProviderFor(CreatePlanController)
const createPlanControllerProvider = CreatePlanControllerProvider._();

/// Creates a plan from the create sheet. The state is loading while the
/// server works; a refusal (a Free limit, offline) comes back as a
/// [PlanFailure] from [create] for the sheet to explain.
final class CreatePlanControllerProvider
    extends $NotifierProvider<CreatePlanController, bool> {
  /// Creates a plan from the create sheet. The state is loading while the
  /// server works; a refusal (a Free limit, offline) comes back as a
  /// [PlanFailure] from [create] for the sheet to explain.
  const CreatePlanControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'createPlanControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$createPlanControllerHash();

  @$internal
  @override
  CreatePlanController create() => CreatePlanController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$createPlanControllerHash() =>
    r'61e0ae0d93520e4e180d22a1f2a5ef117a9ffc17';

/// Creates a plan from the create sheet. The state is loading while the
/// server works; a refusal (a Free limit, offline) comes back as a
/// [PlanFailure] from [create] for the sheet to explain.

abstract class _$CreatePlanController extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
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
