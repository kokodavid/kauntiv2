// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'public_trip_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The public-trips repository, or null when the build has no Supabase.

@ProviderFor(publicTripRepository)
const publicTripRepositoryProvider = PublicTripRepositoryProvider._();

/// The public-trips repository, or null when the build has no Supabase.

final class PublicTripRepositoryProvider
    extends
        $FunctionalProvider<
          PublicTripRepository?,
          PublicTripRepository?,
          PublicTripRepository?
        >
    with $Provider<PublicTripRepository?> {
  /// The public-trips repository, or null when the build has no Supabase.
  const PublicTripRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'publicTripRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$publicTripRepositoryHash();

  @$internal
  @override
  $ProviderElement<PublicTripRepository?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PublicTripRepository? create(Ref ref) {
    return publicTripRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PublicTripRepository? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PublicTripRepository?>(value),
    );
  }
}

String _$publicTripRepositoryHash() =>
    r'ef0d0ff893463828f28d734f80b873be67a26982';

/// How often to look again while photos are being prepared. Overridden in
/// tests.

@ProviderFor(publicTripPhotoPollInterval)
const publicTripPhotoPollIntervalProvider =
    PublicTripPhotoPollIntervalProvider._();

/// How often to look again while photos are being prepared. Overridden in
/// tests.

final class PublicTripPhotoPollIntervalProvider
    extends $FunctionalProvider<Duration, Duration, Duration>
    with $Provider<Duration> {
  /// How often to look again while photos are being prepared. Overridden in
  /// tests.
  const PublicTripPhotoPollIntervalProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'publicTripPhotoPollIntervalProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$publicTripPhotoPollIntervalHash();

  @$internal
  @override
  $ProviderElement<Duration> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Duration create(Ref ref) {
    return publicTripPhotoPollInterval(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Duration value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Duration>(value),
    );
  }
}

String _$publicTripPhotoPollIntervalHash() =>
    r'f08cb176118788ea623caba67309ccc3924e1408';

/// Whether the owner may be offered "Make public": the server's publish
/// switch is on. Pro and suspension are still checked by the server when
/// preparing, so a refusal there is shown as its own message.

@ProviderFor(publicTripPublishingEnabled)
const publicTripPublishingEnabledProvider =
    PublicTripPublishingEnabledProvider._();

/// Whether the owner may be offered "Make public": the server's publish
/// switch is on. Pro and suspension are still checked by the server when
/// preparing, so a refusal there is shown as its own message.

final class PublicTripPublishingEnabledProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// Whether the owner may be offered "Make public": the server's publish
  /// switch is on. Pro and suspension are still checked by the server when
  /// preparing, so a refusal there is shown as its own message.
  const PublicTripPublishingEnabledProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'publicTripPublishingEnabledProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$publicTripPublishingEnabledHash();

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    return publicTripPublishingEnabled(ref);
  }
}

String _$publicTripPublishingEnabledHash() =>
    r'68bc487851f2fb9f2310e8e0470b3ae22e939492';

/// This trip's public copy as its owner sees it, or null if it was never
/// made public.

@ProviderFor(myPublicTrip)
const myPublicTripProvider = MyPublicTripFamily._();

/// This trip's public copy as its owner sees it, or null if it was never
/// made public.

final class MyPublicTripProvider
    extends
        $FunctionalProvider<
          AsyncValue<PublicTripOwnerView?>,
          PublicTripOwnerView?,
          FutureOr<PublicTripOwnerView?>
        >
    with
        $FutureModifier<PublicTripOwnerView?>,
        $FutureProvider<PublicTripOwnerView?> {
  /// This trip's public copy as its owner sees it, or null if it was never
  /// made public.
  const MyPublicTripProvider._({
    required MyPublicTripFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'myPublicTripProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$myPublicTripHash();

  @override
  String toString() {
    return r'myPublicTripProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<PublicTripOwnerView?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PublicTripOwnerView?> create(Ref ref) {
    final argument = this.argument as String;
    return myPublicTrip(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MyPublicTripProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$myPublicTripHash() => r'e6e4f17b972c403abd85e761bf37d818ba0e664b';

/// This trip's public copy as its owner sees it, or null if it was never
/// made public.

final class MyPublicTripFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<PublicTripOwnerView?>, String> {
  const MyPublicTripFamily._()
    : super(
        retry: null,
        name: r'myPublicTripProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// This trip's public copy as its owner sees it, or null if it was never
  /// made public.

  MyPublicTripProvider call(String journeyId) =>
      MyPublicTripProvider._(argument: journeyId, from: this);

  @override
  String toString() => r'myPublicTripProvider';
}

/// The owner's share defaults, saved optimistically.

@ProviderFor(PublicTripSharePreferencesController)
const publicTripSharePreferencesControllerProvider =
    PublicTripSharePreferencesControllerProvider._();

/// The owner's share defaults, saved optimistically.
final class PublicTripSharePreferencesControllerProvider
    extends
        $AsyncNotifierProvider<
          PublicTripSharePreferencesController,
          PublicTripSharePreferences
        > {
  /// The owner's share defaults, saved optimistically.
  const PublicTripSharePreferencesControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'publicTripSharePreferencesControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() =>
      _$publicTripSharePreferencesControllerHash();

  @$internal
  @override
  PublicTripSharePreferencesController create() =>
      PublicTripSharePreferencesController();
}

String _$publicTripSharePreferencesControllerHash() =>
    r'ea8a7793cd65f2d8f69696d6780697a6ba62ac2d';

/// The owner's share defaults, saved optimistically.

abstract class _$PublicTripSharePreferencesController
    extends $AsyncNotifier<PublicTripSharePreferences> {
  FutureOr<PublicTripSharePreferences> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref
            as $Ref<
              AsyncValue<PublicTripSharePreferences>,
              PublicTripSharePreferences
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<PublicTripSharePreferences>,
                PublicTripSharePreferences
              >,
              AsyncValue<PublicTripSharePreferences>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// Withdraws a trip's public copy. Each trip has its own state so the
/// confirm sheet can show progress and a failure.

@ProviderFor(PublicTripWithdrawal)
const publicTripWithdrawalProvider = PublicTripWithdrawalFamily._();

/// Withdraws a trip's public copy. Each trip has its own state so the
/// confirm sheet can show progress and a failure.
final class PublicTripWithdrawalProvider
    extends $NotifierProvider<PublicTripWithdrawal, AsyncValue<void>> {
  /// Withdraws a trip's public copy. Each trip has its own state so the
  /// confirm sheet can show progress and a failure.
  const PublicTripWithdrawalProvider._({
    required PublicTripWithdrawalFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'publicTripWithdrawalProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$publicTripWithdrawalHash();

  @override
  String toString() {
    return r'publicTripWithdrawalProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  PublicTripWithdrawal create() => PublicTripWithdrawal();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<void> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<void>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PublicTripWithdrawalProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$publicTripWithdrawalHash() =>
    r'25098ec31a78513405643b4f891195809dad26da';

/// Withdraws a trip's public copy. Each trip has its own state so the
/// confirm sheet can show progress and a failure.

final class PublicTripWithdrawalFamily extends $Family
    with
        $ClassFamilyOverride<
          PublicTripWithdrawal,
          AsyncValue<void>,
          AsyncValue<void>,
          AsyncValue<void>,
          String
        > {
  const PublicTripWithdrawalFamily._()
    : super(
        retry: null,
        name: r'publicTripWithdrawalProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Withdraws a trip's public copy. Each trip has its own state so the
  /// confirm sheet can show progress and a failure.

  PublicTripWithdrawalProvider call(String journeyId) =>
      PublicTripWithdrawalProvider._(argument: journeyId, from: this);

  @override
  String toString() => r'publicTripWithdrawalProvider';
}

/// Withdraws a trip's public copy. Each trip has its own state so the
/// confirm sheet can show progress and a failure.

abstract class _$PublicTripWithdrawal extends $Notifier<AsyncValue<void>> {
  late final _$args = ref.$arg as String;
  String get journeyId => _$args;

  AsyncValue<void> build(String journeyId);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args);
    final ref = this.ref as $Ref<AsyncValue<void>, AsyncValue<void>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, AsyncValue<void>>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
