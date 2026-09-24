// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'arrival_nudge.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The arrival sheet's "already shown" history. Tests override it.

@ProviderFor(arrivalNudgeHistory)
const arrivalNudgeHistoryProvider = ArrivalNudgeHistoryProvider._();

/// The arrival sheet's "already shown" history. Tests override it.

final class ArrivalNudgeHistoryProvider
    extends
        $FunctionalProvider<
          ArrivalNudgeHistory,
          ArrivalNudgeHistory,
          ArrivalNudgeHistory
        >
    with $Provider<ArrivalNudgeHistory> {
  /// The arrival sheet's "already shown" history. Tests override it.
  const ArrivalNudgeHistoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'arrivalNudgeHistoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$arrivalNudgeHistoryHash();

  @$internal
  @override
  $ProviderElement<ArrivalNudgeHistory> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ArrivalNudgeHistory create(Ref ref) {
    return arrivalNudgeHistory(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ArrivalNudgeHistory value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ArrivalNudgeHistory>(value),
    );
  }
}

String _$arrivalNudgeHistoryHash() =>
    r'ffa3323f3e3eaa3b27d6e9aed8595eadfa788de2';

/// The crossing the app should show the arrival sheet for; null when
/// there's none. Offered by each detection cycle, taken by the sheet host.

@ProviderFor(PendingArrivalNudge)
const pendingArrivalNudgeProvider = PendingArrivalNudgeProvider._();

/// The crossing the app should show the arrival sheet for; null when
/// there's none. Offered by each detection cycle, taken by the sheet host.
final class PendingArrivalNudgeProvider
    extends $NotifierProvider<PendingArrivalNudge, PendingArrival?> {
  /// The crossing the app should show the arrival sheet for; null when
  /// there's none. Offered by each detection cycle, taken by the sheet host.
  const PendingArrivalNudgeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingArrivalNudgeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingArrivalNudgeHash();

  @$internal
  @override
  PendingArrivalNudge create() => PendingArrivalNudge();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PendingArrival? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PendingArrival?>(value),
    );
  }
}

String _$pendingArrivalNudgeHash() =>
    r'2990efe2c29e22b3abfdbc990d84a5754178ba98';

/// The crossing the app should show the arrival sheet for; null when
/// there's none. Offered by each detection cycle, taken by the sheet host.

abstract class _$PendingArrivalNudge extends $Notifier<PendingArrival?> {
  PendingArrival? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<PendingArrival?, PendingArrival?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PendingArrival?, PendingArrival?>,
              PendingArrival?,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
