// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'passport_share_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The dashboard's Passport share switch. Null without Supabase.

@ProviderFor(passportShareFlagRepository)
const passportShareFlagRepositoryProvider =
    PassportShareFlagRepositoryProvider._();

/// The dashboard's Passport share switch. Null without Supabase.

final class PassportShareFlagRepositoryProvider
    extends
        $FunctionalProvider<
          PassportShareFlagRepository?,
          PassportShareFlagRepository?,
          PassportShareFlagRepository?
        >
    with $Provider<PassportShareFlagRepository?> {
  /// The dashboard's Passport share switch. Null without Supabase.
  const PassportShareFlagRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'passportShareFlagRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$passportShareFlagRepositoryHash();

  @$internal
  @override
  $ProviderElement<PassportShareFlagRepository?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PassportShareFlagRepository? create(Ref ref) {
    return passportShareFlagRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PassportShareFlagRepository? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PassportShareFlagRepository?>(value),
    );
  }
}

String _$passportShareFlagRepositoryHash() =>
    r'0fac2da8427d7a21797c8b64781ddd0bcf4c5b75';

/// Whether the dashboard has Passport sharing switched on. A failed read
/// falls back to the last value seen, then to off, so the button never shows
/// by accident and doesn't flicker when the phone is offline. The Passport
/// screen refreshes it when it opens.

@ProviderFor(passportShareFlag)
const passportShareFlagProvider = PassportShareFlagProvider._();

/// Whether the dashboard has Passport sharing switched on. A failed read
/// falls back to the last value seen, then to off, so the button never shows
/// by accident and doesn't flicker when the phone is offline. The Passport
/// screen refreshes it when it opens.

final class PassportShareFlagProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// Whether the dashboard has Passport sharing switched on. A failed read
  /// falls back to the last value seen, then to off, so the button never shows
  /// by accident and doesn't flicker when the phone is offline. The Passport
  /// screen refreshes it when it opens.
  const PassportShareFlagProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'passportShareFlagProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$passportShareFlagHash();

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    return passportShareFlag(ref);
  }
}

String _$passportShareFlagHash() => r'd800bdc19a0ad4886be5d1f62ba98c39530cc285';
