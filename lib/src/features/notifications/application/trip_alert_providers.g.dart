// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trip_alert_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The paused-trip reminder. Tests override it.

@ProviderFor(tripAlertNotifier)
const tripAlertProvider = TripAlertNotifierProvider._();

/// The paused-trip reminder. Tests override it.

final class TripAlertNotifierProvider
    extends
        $FunctionalProvider<
          TripAlertNotifier,
          TripAlertNotifier,
          TripAlertNotifier
        >
    with $Provider<TripAlertNotifier> {
  /// The paused-trip reminder. Tests override it.
  const TripAlertNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tripAlertProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tripAlertNotifierHash();

  @$internal
  @override
  $ProviderElement<TripAlertNotifier> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TripAlertNotifier create(Ref ref) {
    return tripAlertNotifier(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TripAlertNotifier value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TripAlertNotifier>(value),
    );
  }
}

String _$tripAlertNotifierHash() => r'ee0e51b330d687cc52b09e2517481ecbba1f0094';
