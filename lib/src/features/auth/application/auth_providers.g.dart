// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Google / Apple sign-in against the app's Supabase project.

@ProviderFor(authService)
const authServiceProvider = AuthServiceProvider._();

/// Google / Apple sign-in against the app's Supabase project.

final class AuthServiceProvider
    extends $FunctionalProvider<AppAuthService, AppAuthService, AppAuthService>
    with $Provider<AppAuthService> {
  /// Google / Apple sign-in against the app's Supabase project.
  const AuthServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authServiceHash();

  @$internal
  @override
  $ProviderElement<AppAuthService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppAuthService create(Ref ref) {
    return authService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppAuthService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppAuthService>(value),
    );
  }
}

String _$authServiceHash() => r'5be8a4faf088e325418b2b872b7aac5da6d8aded';

/// Reads the signed-in user's id at call time (null when signed out or
/// when the build has no Supabase). A function, not a value, because the
/// session changes after sign-in without the provider rebuilding. Tests
/// override it.

@ProviderFor(currentUserId)
const currentUserIdProvider = CurrentUserIdProvider._();

/// Reads the signed-in user's id at call time (null when signed out or
/// when the build has no Supabase). A function, not a value, because the
/// session changes after sign-in without the provider rebuilding. Tests
/// override it.

final class CurrentUserIdProvider
    extends
        $FunctionalProvider<
          String? Function(),
          String? Function(),
          String? Function()
        >
    with $Provider<String? Function()> {
  /// Reads the signed-in user's id at call time (null when signed out or
  /// when the build has no Supabase). A function, not a value, because the
  /// session changes after sign-in without the provider rebuilding. Tests
  /// override it.
  const CurrentUserIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentUserIdProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentUserIdHash();

  @$internal
  @override
  $ProviderElement<String? Function()> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  String? Function() create(Ref ref) {
    return currentUserId(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? Function() value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String? Function()>(value),
    );
  }
}

String _$currentUserIdHash() => r'00d63cd86d158009cba163b5cbeaf5a6dd1f56de';
