// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_setup_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The traveller's saved home county. Throws when the build has no
/// Supabase (onboarding only reads it once signed in). Tests override it.

@ProviderFor(profileSetupRepository)
const profileSetupRepositoryProvider = ProfileSetupRepositoryProvider._();

/// The traveller's saved home county. Throws when the build has no
/// Supabase (onboarding only reads it once signed in). Tests override it.

final class ProfileSetupRepositoryProvider
    extends
        $FunctionalProvider<
          ProfileSetupRepository,
          ProfileSetupRepository,
          ProfileSetupRepository
        >
    with $Provider<ProfileSetupRepository> {
  /// The traveller's saved home county. Throws when the build has no
  /// Supabase (onboarding only reads it once signed in). Tests override it.
  const ProfileSetupRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profileSetupRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profileSetupRepositoryHash();

  @$internal
  @override
  $ProviderElement<ProfileSetupRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ProfileSetupRepository create(Ref ref) {
    return profileSetupRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProfileSetupRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProfileSetupRepository>(value),
    );
  }
}

String _$profileSetupRepositoryHash() =>
    r'44196f5a1e4ca71147e0b61dcc46238d337b82d8';
