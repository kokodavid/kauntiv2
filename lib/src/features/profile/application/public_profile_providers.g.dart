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
    r'80c4eee6f85080de7a063f33dcba088b2dc3ac16';

/// The signed-in account's display name, handle and avatar. Reloads when
/// the account changes; Edit Profile invalidates this after a successful
/// save or avatar upload. Kept alive so Home's avatar and Profile read one
/// loaded copy instead of fetching again (and flashing the initial) each
/// time either screen appears.

@ProviderFor(myPublicProfile)
const myPublicProfileProvider = MyPublicProfileProvider._();

/// The signed-in account's display name, handle and avatar. Reloads when
/// the account changes; Edit Profile invalidates this after a successful
/// save or avatar upload. Kept alive so Home's avatar and Profile read one
/// loaded copy instead of fetching again (and flashing the initial) each
/// time either screen appears.

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
  /// save or avatar upload. Kept alive so Home's avatar and Profile read one
  /// loaded copy instead of fetching again (and flashing the initial) each
  /// time either screen appears.
  const MyPublicProfileProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myPublicProfileProvider',
        isAutoDispose: false,
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

String _$myPublicProfileHash() => r'ce3c0f1835afe72040bf7d60d9f69d045967d288';

/// When the Profile values on screen were last saved, for the "Saved"
/// chip while offline. Re-reads whenever either value reloads.

@ProviderFor(profileSavedAt)
const profileSavedAtProvider = ProfileSavedAtProvider._();

/// When the Profile values on screen were last saved, for the "Saved"
/// chip while offline. Re-reads whenever either value reloads.

final class ProfileSavedAtProvider
    extends
        $FunctionalProvider<
          AsyncValue<DateTime?>,
          DateTime?,
          FutureOr<DateTime?>
        >
    with $FutureModifier<DateTime?>, $FutureProvider<DateTime?> {
  /// When the Profile values on screen were last saved, for the "Saved"
  /// chip while offline. Re-reads whenever either value reloads.
  const ProfileSavedAtProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profileSavedAtProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profileSavedAtHash();

  @$internal
  @override
  $FutureProviderElement<DateTime?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<DateTime?> create(Ref ref) {
    return profileSavedAt(ref);
  }
}

String _$profileSavedAtHash() => r'70a9c84182bf7d6b582487b98fcba59db1afbda5';
