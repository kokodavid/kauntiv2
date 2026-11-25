// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_live.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(planLiveSource)
const planLiveSourceProvider = PlanLiveSourceProvider._();

final class PlanLiveSourceProvider
    extends
        $FunctionalProvider<PlanLiveSource?, PlanLiveSource?, PlanLiveSource?>
    with $Provider<PlanLiveSource?> {
  const PlanLiveSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'planLiveSourceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$planLiveSourceHash();

  @$internal
  @override
  $ProviderElement<PlanLiveSource?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PlanLiveSource? create(Ref ref) {
    return planLiveSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlanLiveSource? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlanLiveSource?>(value),
    );
  }
}

String _$planLiveSourceHash() => r'534dab27672d8a1ca3dbbdfcbf9ead418649952b';

/// When Realtime is silent or down, the open plan is still read this often.
/// Null (tests) turns the fallback off.

@ProviderFor(planLivePollInterval)
const planLivePollIntervalProvider = PlanLivePollIntervalProvider._();

/// When Realtime is silent or down, the open plan is still read this often.
/// Null (tests) turns the fallback off.

final class PlanLivePollIntervalProvider
    extends $FunctionalProvider<Duration?, Duration?, Duration?>
    with $Provider<Duration?> {
  /// When Realtime is silent or down, the open plan is still read this often.
  /// Null (tests) turns the fallback off.
  const PlanLivePollIntervalProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'planLivePollIntervalProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$planLivePollIntervalHash();

  @$internal
  @override
  $ProviderElement<Duration?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Duration? create(Ref ref) {
    return planLivePollInterval(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Duration? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Duration?>(value),
    );
  }
}

String _$planLivePollIntervalHash() =>
    r'62e41c690c36637a70045bc2c2a7cf5618d40bfe';

/// Keeps an open plan current: reads it again after a change someone else
/// made, and on a slow timer as a fallback. Watch it from the plan screen;
/// it stops when the screen closes.

@ProviderFor(planLive)
const planLiveProvider = PlanLiveFamily._();

/// Keeps an open plan current: reads it again after a change someone else
/// made, and on a slow timer as a fallback. Watch it from the plan screen;
/// it stops when the screen closes.

final class PlanLiveProvider extends $FunctionalProvider<void, void, void>
    with $Provider<void> {
  /// Keeps an open plan current: reads it again after a change someone else
  /// made, and on a slow timer as a fallback. Watch it from the plan screen;
  /// it stops when the screen closes.
  const PlanLiveProvider._({
    required PlanLiveFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'planLiveProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$planLiveHash();

  @override
  String toString() {
    return r'planLiveProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<void> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  void create(Ref ref) {
    final argument = this.argument as String;
    return planLive(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PlanLiveProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$planLiveHash() => r'a2ac5c4c5b989e777110b01874174f74e50f8907';

/// Keeps an open plan current: reads it again after a change someone else
/// made, and on a slow timer as a fallback. Watch it from the plan screen;
/// it stops when the screen closes.

final class PlanLiveFamily extends $Family
    with $FunctionalFamilyOverride<void, String> {
  const PlanLiveFamily._()
    : super(
        retry: null,
        name: r'planLiveProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Keeps an open plan current: reads it again after a change someone else
  /// made, and on a slow timer as a fallback. Watch it from the plan screen;
  /// it stops when the screen closes.

  PlanLiveProvider call(String planId) =>
      PlanLiveProvider._(argument: planId, from: this);

  @override
  String toString() => r'planLiveProvider';
}
