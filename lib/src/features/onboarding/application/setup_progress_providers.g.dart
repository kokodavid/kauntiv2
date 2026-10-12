// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'setup_progress_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether new-user setup is under way on this phone. Tests override it.

@ProviderFor(setupProgressStore)
const setupProgressStoreProvider = SetupProgressStoreProvider._();

/// Whether new-user setup is under way on this phone. Tests override it.

final class SetupProgressStoreProvider
    extends
        $FunctionalProvider<
          SetupProgressStore,
          SetupProgressStore,
          SetupProgressStore
        >
    with $Provider<SetupProgressStore> {
  /// Whether new-user setup is under way on this phone. Tests override it.
  const SetupProgressStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'setupProgressStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$setupProgressStoreHash();

  @$internal
  @override
  $ProviderElement<SetupProgressStore> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SetupProgressStore create(Ref ref) {
    return setupProgressStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SetupProgressStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SetupProgressStore>(value),
    );
  }
}

String _$setupProgressStoreHash() =>
    r'2708729dc8d71817c2538770de3b9cfafc78e4f5';
