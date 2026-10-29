// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_collapsed_days.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(planCollapsedStore)
const planCollapsedStoreProvider = PlanCollapsedStoreProvider._();

final class PlanCollapsedStoreProvider
    extends
        $FunctionalProvider<
          PlanCollapsedStore,
          PlanCollapsedStore,
          PlanCollapsedStore
        >
    with $Provider<PlanCollapsedStore> {
  const PlanCollapsedStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'planCollapsedStoreProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$planCollapsedStoreHash();

  @$internal
  @override
  $ProviderElement<PlanCollapsedStore> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PlanCollapsedStore create(Ref ref) {
    return planCollapsedStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlanCollapsedStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlanCollapsedStore>(value),
    );
  }
}

String _$planCollapsedStoreHash() =>
    r'c328eafcb786b7de28881da6d37fbf35ddfe42e4';

/// Which days of a plan are folded, kept per plan on this phone. Null until
/// the person has folded or opened one, so the screen can use its default.

@ProviderFor(PlanCollapsedDays)
const planCollapsedDaysProvider = PlanCollapsedDaysFamily._();

/// Which days of a plan are folded, kept per plan on this phone. Null until
/// the person has folded or opened one, so the screen can use its default.
final class PlanCollapsedDaysProvider
    extends $AsyncNotifierProvider<PlanCollapsedDays, Set<int>?> {
  /// Which days of a plan are folded, kept per plan on this phone. Null until
  /// the person has folded or opened one, so the screen can use its default.
  const PlanCollapsedDaysProvider._({
    required PlanCollapsedDaysFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'planCollapsedDaysProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$planCollapsedDaysHash();

  @override
  String toString() {
    return r'planCollapsedDaysProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  PlanCollapsedDays create() => PlanCollapsedDays();

  @override
  bool operator ==(Object other) {
    return other is PlanCollapsedDaysProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$planCollapsedDaysHash() => r'b595900de4d3d7d8223c59574fc920d2bfc84c49';

/// Which days of a plan are folded, kept per plan on this phone. Null until
/// the person has folded or opened one, so the screen can use its default.

final class PlanCollapsedDaysFamily extends $Family
    with
        $ClassFamilyOverride<
          PlanCollapsedDays,
          AsyncValue<Set<int>?>,
          Set<int>?,
          FutureOr<Set<int>?>,
          String
        > {
  const PlanCollapsedDaysFamily._()
    : super(
        retry: null,
        name: r'planCollapsedDaysProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Which days of a plan are folded, kept per plan on this phone. Null until
  /// the person has folded or opened one, so the screen can use its default.

  PlanCollapsedDaysProvider call(String planId) =>
      PlanCollapsedDaysProvider._(argument: planId, from: this);

  @override
  String toString() => r'planCollapsedDaysProvider';
}

/// Which days of a plan are folded, kept per plan on this phone. Null until
/// the person has folded or opened one, so the screen can use its default.

abstract class _$PlanCollapsedDays extends $AsyncNotifier<Set<int>?> {
  late final _$args = ref.$arg as String;
  String get planId => _$args;

  FutureOr<Set<int>?> build(String planId);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args);
    final ref = this.ref as $Ref<AsyncValue<Set<int>?>, Set<int>?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Set<int>?>, Set<int>?>,
              AsyncValue<Set<int>?>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
