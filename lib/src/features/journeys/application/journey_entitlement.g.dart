// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'journey_entitlement.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Cached display state for this account's monthly free-Trip usage.

@ProviderFor(JourneyTrialUsage)
const journeyTrialUsageProvider = JourneyTrialUsageProvider._();

/// Cached display state for this account's monthly free-Trip usage.
final class JourneyTrialUsageProvider
    extends $NotifierProvider<JourneyTrialUsage, JourneyTrialStatus?> {
  /// Cached display state for this account's monthly free-Trip usage.
  const JourneyTrialUsageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'journeyTrialUsageProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$journeyTrialUsageHash();

  @$internal
  @override
  JourneyTrialUsage create() => JourneyTrialUsage();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(JourneyTrialStatus? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<JourneyTrialStatus?>(value),
    );
  }
}

String _$journeyTrialUsageHash() => r'1ff4d1ef50f1b0df44c9ff66edd7d79084133819';

/// Cached display state for this account's monthly free-Trip usage.

abstract class _$JourneyTrialUsage extends $Notifier<JourneyTrialStatus?> {
  JourneyTrialStatus? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<JourneyTrialStatus?, JourneyTrialStatus?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<JourneyTrialStatus?, JourneyTrialStatus?>,
              JourneyTrialStatus?,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// Pro for starting a Journey, checked live on the server every time. No
/// cached status can start one: a Journey started on a stale "Pro" would
/// be refused at upload and stranded on the phone. The upload re-checks
/// Pro at the start time on the server as well.

@ProviderFor(JourneyEntitlement)
const journeyEntitlementProvider = JourneyEntitlementProvider._();

/// Pro for starting a Journey, checked live on the server every time. No
/// cached status can start one: a Journey started on a stale "Pro" would
/// be refused at upload and stranded on the phone. The upload re-checks
/// Pro at the start time on the server as well.
final class JourneyEntitlementProvider
    extends $NotifierProvider<JourneyEntitlement, ProStatus?> {
  /// Pro for starting a Journey, checked live on the server every time. No
  /// cached status can start one: a Journey started on a stale "Pro" would
  /// be refused at upload and stranded on the phone. The upload re-checks
  /// Pro at the start time on the server as well.
  const JourneyEntitlementProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'journeyEntitlementProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$journeyEntitlementHash();

  @$internal
  @override
  JourneyEntitlement create() => JourneyEntitlement();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProStatus? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProStatus?>(value),
    );
  }
}

String _$journeyEntitlementHash() =>
    r'5b4d61b33482e69d744f5de9546ebb07d44c1fc3';

/// Pro for starting a Journey, checked live on the server every time. No
/// cached status can start one: a Journey started on a stale "Pro" would
/// be refused at upload and stranded on the phone. The upload re-checks
/// Pro at the start time on the server as well.

abstract class _$JourneyEntitlement extends $Notifier<ProStatus?> {
  ProStatus? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<ProStatus?, ProStatus?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ProStatus?, ProStatus?>,
              ProStatus?,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
