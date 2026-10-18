// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'arrival_notifier_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The arrival notification's OS permission and tap plumbing. Onboarding
/// asks through it; tests override it.

@ProviderFor(arrivalNotifierService)
const arrivalNotifierServiceProvider = ArrivalNotifierServiceProvider._();

/// The arrival notification's OS permission and tap plumbing. Onboarding
/// asks through it; tests override it.

final class ArrivalNotifierServiceProvider
    extends
        $FunctionalProvider<ArrivalNotifier, ArrivalNotifier, ArrivalNotifier>
    with $Provider<ArrivalNotifier> {
  /// The arrival notification's OS permission and tap plumbing. Onboarding
  /// asks through it; tests override it.
  const ArrivalNotifierServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'arrivalNotifierServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$arrivalNotifierServiceHash();

  @$internal
  @override
  $ProviderElement<ArrivalNotifier> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ArrivalNotifier create(Ref ref) {
    return arrivalNotifierService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ArrivalNotifier value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ArrivalNotifier>(value),
    );
  }
}

String _$arrivalNotifierServiceHash() =>
    r'966bd0bd0c5707380028f128f051963031685253';
