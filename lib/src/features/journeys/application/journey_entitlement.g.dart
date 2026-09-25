// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'journey_entitlement.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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
    r'0f0bce52c8d7b2bd795db8721c873e11afe219f5';

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
