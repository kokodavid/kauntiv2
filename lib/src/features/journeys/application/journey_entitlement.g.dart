// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'journey_entitlement.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Pro for starting a Journey. The server is asked first; its answer is
/// cached so a start also works offline for up to
/// [ProStatus.maxCacheAge]. This only gates the Start button: the upload
/// re-checks Pro on the server, so a stale cache can't earn a cloud write.

@ProviderFor(JourneyEntitlement)
const journeyEntitlementProvider = JourneyEntitlementProvider._();

/// Pro for starting a Journey. The server is asked first; its answer is
/// cached so a start also works offline for up to
/// [ProStatus.maxCacheAge]. This only gates the Start button: the upload
/// re-checks Pro on the server, so a stale cache can't earn a cloud write.
final class JourneyEntitlementProvider
    extends $NotifierProvider<JourneyEntitlement, ProStatus?> {
  /// Pro for starting a Journey. The server is asked first; its answer is
  /// cached so a start also works offline for up to
  /// [ProStatus.maxCacheAge]. This only gates the Start button: the upload
  /// re-checks Pro on the server, so a stale cache can't earn a cloud write.
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
    r'dac62c1f1f8eb5b0ad20f4d7ca851885b972c050';

/// Pro for starting a Journey. The server is asked first; its answer is
/// cached so a start also works offline for up to
/// [ProStatus.maxCacheAge]. This only gates the Start button: the upload
/// re-checks Pro on the server, so a stale cache can't earn a cloud write.

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
