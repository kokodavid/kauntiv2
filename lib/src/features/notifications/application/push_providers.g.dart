// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'push_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Firebase for this build's environment (dev and prod each have their own
/// project, from the dart-defines).

@ProviderFor(pushMessagingService)
const pushMessagingServiceProvider = PushMessagingServiceProvider._();

/// Firebase for this build's environment (dev and prod each have their own
/// project, from the dart-defines).

final class PushMessagingServiceProvider
    extends
        $FunctionalProvider<
          PushMessagingService,
          PushMessagingService,
          PushMessagingService
        >
    with $Provider<PushMessagingService> {
  /// Firebase for this build's environment (dev and prod each have their own
  /// project, from the dart-defines).
  const PushMessagingServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pushMessagingServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pushMessagingServiceHash();

  @$internal
  @override
  $ProviderElement<PushMessagingService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PushMessagingService create(Ref ref) {
    return pushMessagingService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PushMessagingService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PushMessagingService>(value),
    );
  }
}

String _$pushMessagingServiceHash() =>
    r'e3f824ba9a1c1cffea34f5d3be308e1e4c373342';

@ProviderFor(pushDeviceRepository)
const pushDeviceRepositoryProvider = PushDeviceRepositoryProvider._();

final class PushDeviceRepositoryProvider
    extends
        $FunctionalProvider<
          PushDeviceRepository?,
          PushDeviceRepository?,
          PushDeviceRepository?
        >
    with $Provider<PushDeviceRepository?> {
  const PushDeviceRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pushDeviceRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pushDeviceRepositoryHash();

  @$internal
  @override
  $ProviderElement<PushDeviceRepository?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PushDeviceRepository? create(Ref ref) {
    return pushDeviceRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PushDeviceRepository? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PushDeviceRepository?>(value),
    );
  }
}

String _$pushDeviceRepositoryHash() =>
    r'3b035292d45ce79f060a64b5184ea9d2121d58b1';

@ProviderFor(pushRegistrar)
const pushRegistrarProvider = PushRegistrarProvider._();

final class PushRegistrarProvider
    extends $FunctionalProvider<PushRegistrar, PushRegistrar, PushRegistrar>
    with $Provider<PushRegistrar> {
  const PushRegistrarProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pushRegistrarProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pushRegistrarHash();

  @$internal
  @override
  $ProviderElement<PushRegistrar> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PushRegistrar create(Ref ref) {
    return pushRegistrar(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PushRegistrar value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PushRegistrar>(value),
    );
  }
}

String _$pushRegistrarHash() => r'8a2fe1cc8c7983c3a5f788559571555bb12cb3ff';
