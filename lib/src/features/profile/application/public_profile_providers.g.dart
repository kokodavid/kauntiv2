// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'public_profile_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The account's public identity in the cloud, or null when the build has
/// no Supabase.

@ProviderFor(publicProfileRepository)
const publicProfileRepositoryProvider = PublicProfileRepositoryProvider._();

/// The account's public identity in the cloud, or null when the build has
/// no Supabase.

final class PublicProfileRepositoryProvider
    extends
        $FunctionalProvider<
          PublicProfileRepository?,
          PublicProfileRepository?,
          PublicProfileRepository?
        >
    with $Provider<PublicProfileRepository?> {
  /// The account's public identity in the cloud, or null when the build has
  /// no Supabase.
  const PublicProfileRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'publicProfileRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$publicProfileRepositoryHash();

  @$internal
  @override
  $ProviderElement<PublicProfileRepository?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PublicProfileRepository? create(Ref ref) {
    return publicProfileRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PublicProfileRepository? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PublicProfileRepository?>(value),
    );
  }
}

String _$publicProfileRepositoryHash() =>
    r'3a8f6c1d9e2b4057a6c1f0e3d8b7a5c4f1e0d9b2';

/// The signed-in account's display name, handle and avatar. Reloads when
/// the account changes; Edit Profile invalidates this after a successful
/// save or avatar upload.

@ProviderFor(myPublicProfile)
const myPublicProfileProvider = MyPublicProfileProvider._();

/// The signed-in account's display name, handle and avatar. Reloads when
/// the account changes; Edit Profile invalidates this after a successful
/// save or avatar upload.

final class MyPublicProfileProvider
    extends
        $FunctionalProvider<
          AsyncValue<PublicProfile?>,
          PublicProfile?,
          FutureOr<PublicProfile?>
        >
    with $FutureModifier<PublicProfile?>, $FutureProvider<PublicProfile?> {
  /// The signed-in account's display name, handle and avatar. Reloads when
  /// the account changes; Edit Profile invalidates this after a successful
  /// save or avatar upload.
  const MyPublicProfileProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myPublicProfileProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myPublicProfileHash();

  @$internal
  @override
  $FutureProviderElement<PublicProfile?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PublicProfile?> create(Ref ref) {
    return myPublicProfile(ref);
  }
}

String _$myPublicProfileHash() =>
    r'7d2e9a4c6f1b3058d4a7c2e9f6b1038a5c2e9f4b';
