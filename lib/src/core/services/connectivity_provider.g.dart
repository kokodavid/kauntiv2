// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connectivity_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The probe against the project's own server host.

@ProviderFor(connectivityProbe)
const connectivityProbeProvider = ConnectivityProbeProvider._();

/// The probe against the project's own server host.

final class ConnectivityProbeProvider
    extends
        $FunctionalProvider<
          ConnectivityProbe,
          ConnectivityProbe,
          ConnectivityProbe
        >
    with $Provider<ConnectivityProbe> {
  /// The probe against the project's own server host.
  const ConnectivityProbeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'connectivityProbeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$connectivityProbeHash();

  @$internal
  @override
  $ProviderElement<ConnectivityProbe> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ConnectivityProbe create(Ref ref) {
    return connectivityProbe(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ConnectivityProbe value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ConnectivityProbe>(value),
    );
  }
}

String _$connectivityProbeHash() => r'ac5adf9f6fca7f61f1e7e49da94683a830f9b94b';

/// One app-wide answer to "are we online?". Everything offline-aware
/// (banner, notices, chips, Home's reload) reads this; nothing is shown or
/// hidden by hand. Goes offline only after a failed check is confirmed
/// 1.5 s later, so a flaky signal doesn't flicker.

@ProviderFor(Connectivity)
const connectivityProvider = ConnectivityProvider._();

/// One app-wide answer to "are we online?". Everything offline-aware
/// (banner, notices, chips, Home's reload) reads this; nothing is shown or
/// hidden by hand. Goes offline only after a failed check is confirmed
/// 1.5 s later, so a flaky signal doesn't flicker.
final class ConnectivityProvider
    extends $NotifierProvider<Connectivity, ConnectivityState> {
  /// One app-wide answer to "are we online?". Everything offline-aware
  /// (banner, notices, chips, Home's reload) reads this; nothing is shown or
  /// hidden by hand. Goes offline only after a failed check is confirmed
  /// 1.5 s later, so a flaky signal doesn't flicker.
  const ConnectivityProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'connectivityProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$connectivityHash();

  @$internal
  @override
  Connectivity create() => Connectivity();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ConnectivityState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ConnectivityState>(value),
    );
  }
}

String _$connectivityHash() => r'17ca26b37661d461ba9bc1d49aff71d789efa752';

/// One app-wide answer to "are we online?". Everything offline-aware
/// (banner, notices, chips, Home's reload) reads this; nothing is shown or
/// hidden by hand. Goes offline only after a failed check is confirmed
/// 1.5 s later, so a flaky signal doesn't flicker.

abstract class _$Connectivity extends $Notifier<ConnectivityState> {
  ConnectivityState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<ConnectivityState, ConnectivityState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ConnectivityState, ConnectivityState>,
              ConnectivityState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
