// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_settings_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(profileSettingsRepository)
const profileSettingsRepositoryProvider = ProfileSettingsRepositoryProvider._();

final class ProfileSettingsRepositoryProvider
    extends
        $FunctionalProvider<
          ProfileSettingsRepository?,
          ProfileSettingsRepository?,
          ProfileSettingsRepository?
        >
    with $Provider<ProfileSettingsRepository?> {
  const ProfileSettingsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profileSettingsRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profileSettingsRepositoryHash();

  @$internal
  @override
  $ProviderElement<ProfileSettingsRepository?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ProfileSettingsRepository? create(Ref ref) {
    return profileSettingsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProfileSettingsRepository? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProfileSettingsRepository?>(value),
    );
  }
}

String _$profileSettingsRepositoryHash() =>
    r'4e1b7c3a9f2d6058c4e1b7c3a9f2d6058c4e1b7';

/// Settings screen state: the six preference columns on `profiles`,
/// updated optimistically (each setter flips the toggle immediately, then
/// persists, reverting on failure) so switches feel instant.

@ProviderFor(ProfileSettingsController)
const profileSettingsControllerProvider = ProfileSettingsControllerProvider._();

/// Settings screen state: the six preference columns on `profiles`,
/// updated optimistically (each setter flips the toggle immediately, then
/// persists, reverting on failure) so switches feel instant.
final class ProfileSettingsControllerProvider
    extends $AsyncNotifierProvider<ProfileSettingsController, ProfileSettings> {
  /// Settings screen state: the six preference columns on `profiles`,
  /// updated optimistically (each setter flips the toggle immediately, then
  /// persists, reverting on failure) so switches feel instant.
  const ProfileSettingsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profileSettingsControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profileSettingsControllerHash();

  @$internal
  @override
  ProfileSettingsController create() => ProfileSettingsController();
}

String _$profileSettingsControllerHash() =>
    r'8a5c2e0f6b3d9157a5c2e0f6b3d9157a5c2e0f6';

abstract class _$ProfileSettingsController
    extends $AsyncNotifier<ProfileSettings> {
  FutureOr<ProfileSettings> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<ProfileSettings>, ProfileSettings>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ProfileSettings>, ProfileSettings>,
              AsyncValue<ProfileSettings>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
