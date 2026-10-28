// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'billing_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The dashboard's billing switch. Null without Supabase.

@ProviderFor(billingFlagRepository)
const billingFlagRepositoryProvider = BillingFlagRepositoryProvider._();

/// The dashboard's billing switch. Null without Supabase.

final class BillingFlagRepositoryProvider
    extends
        $FunctionalProvider<
          BillingFlagRepository?,
          BillingFlagRepository?,
          BillingFlagRepository?
        >
    with $Provider<BillingFlagRepository?> {
  /// The dashboard's billing switch. Null without Supabase.
  const BillingFlagRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'billingFlagRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$billingFlagRepositoryHash();

  @$internal
  @override
  $ProviderElement<BillingFlagRepository?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  BillingFlagRepository? create(Ref ref) {
    return billingFlagRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BillingFlagRepository? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BillingFlagRepository?>(value),
    );
  }
}

String _$billingFlagRepositoryHash() =>
    r'291546ed757eed765907cb0a76f0851064632654';

/// Whether the dashboard has purchases switched on. Read once at start-up;
/// any failure (offline, no config) means off, so no purchase screen shows
/// by accident.

@ProviderFor(billingFlag)
const billingFlagProvider = BillingFlagProvider._();

/// Whether the dashboard has purchases switched on. Read once at start-up;
/// any failure (offline, no config) means off, so no purchase screen shows
/// by accident.

final class BillingFlagProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// Whether the dashboard has purchases switched on. Read once at start-up;
  /// any failure (offline, no config) means off, so no purchase screen shows
  /// by accident.
  const BillingFlagProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'billingFlagProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$billingFlagHash();

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    return billingFlag(ref);
  }
}

String _$billingFlagHash() => r'd8dd8d2097ac2e0e6bfc684cc8819db8947bf742';

/// The store connection for this build, or null when this platform has no
/// RevenueCat key (purchases are then off).

@ProviderFor(billingRepository)
const billingRepositoryProvider = BillingRepositoryProvider._();

/// The store connection for this build, or null when this platform has no
/// RevenueCat key (purchases are then off).

final class BillingRepositoryProvider
    extends
        $FunctionalProvider<
          BillingRepository?,
          BillingRepository?,
          BillingRepository?
        >
    with $Provider<BillingRepository?> {
  /// The store connection for this build, or null when this platform has no
  /// RevenueCat key (purchases are then off).
  const BillingRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'billingRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$billingRepositoryHash();

  @$internal
  @override
  $ProviderElement<BillingRepository?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  BillingRepository? create(Ref ref) {
    return billingRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BillingRepository? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BillingRepository?>(value),
    );
  }
}

String _$billingRepositoryHash() => r'41789bb717ef923e6b68add4aa9f1f89f78a4d66';

/// Whether the app may offer Pro purchases right now: the dashboard switch
/// is on, this build has store keys, and someone is signed in (purchases
/// are recorded against the account).

@ProviderFor(billingAvailable)
const billingAvailableProvider = BillingAvailableProvider._();

/// Whether the app may offer Pro purchases right now: the dashboard switch
/// is on, this build has store keys, and someone is signed in (purchases
/// are recorded against the account).

final class BillingAvailableProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Whether the app may offer Pro purchases right now: the dashboard switch
  /// is on, this build has store keys, and someone is signed in (purchases
  /// are recorded against the account).
  const BillingAvailableProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'billingAvailableProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$billingAvailableHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return billingAvailable(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$billingAvailableHash() => r'30209da3a4c6e7ef421edfd45785997bc7a60fd4';

/// The plans to show, annual first. Empty when purchases aren't available.

@ProviderFor(proPlans)
const proPlansProvider = ProPlansProvider._();

/// The plans to show, annual first. Empty when purchases aren't available.

final class ProPlansProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ProPlan>>,
          List<ProPlan>,
          FutureOr<List<ProPlan>>
        >
    with $FutureModifier<List<ProPlan>>, $FutureProvider<List<ProPlan>> {
  /// The plans to show, annual first. Empty when purchases aren't available.
  const ProPlansProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'proPlansProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$proPlansHash();

  @$internal
  @override
  $FutureProviderElement<List<ProPlan>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ProPlan>> create(Ref ref) {
    return proPlans(ref);
  }
}

String _$proPlansHash() => r'd8f10aaf91f60c3d462114eb5f77338a5117832b';
