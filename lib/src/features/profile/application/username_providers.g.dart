// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'username_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The username RPCs, or null when the build has no Supabase.

@ProviderFor(usernameRepository)
const usernameRepositoryProvider = UsernameRepositoryProvider._();

/// The username RPCs, or null when the build has no Supabase.

final class UsernameRepositoryProvider
    extends
        $FunctionalProvider<
          UsernameRepository?,
          UsernameRepository?,
          UsernameRepository?
        >
    with $Provider<UsernameRepository?> {
  /// The username RPCs, or null when the build has no Supabase.
  const UsernameRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'usernameRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$usernameRepositoryHash();

  @$internal
  @override
  $ProviderElement<UsernameRepository?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  UsernameRepository? create(Ref ref) {
    return usernameRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UsernameRepository? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UsernameRepository?>(value),
    );
  }
}

String _$usernameRepositoryHash() =>
    r'5de4540df32b5feb7003acc7e6d057237bb924f3';

/// The username chooser behind setup step 3 and Edit Profile: four
/// suggestions to pick from, "Show me more", or the user's own text checked
/// against the server as they type.

@ProviderFor(UsernameChooser)
const usernameChooserProvider = UsernameChooserProvider._();

/// The username chooser behind setup step 3 and Edit Profile: four
/// suggestions to pick from, "Show me more", or the user's own text checked
/// against the server as they type.
final class UsernameChooserProvider
    extends $NotifierProvider<UsernameChooser, UsernameChooserState> {
  /// The username chooser behind setup step 3 and Edit Profile: four
  /// suggestions to pick from, "Show me more", or the user's own text checked
  /// against the server as they type.
  const UsernameChooserProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'usernameChooserProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$usernameChooserHash();

  @$internal
  @override
  UsernameChooser create() => UsernameChooser();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UsernameChooserState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UsernameChooserState>(value),
    );
  }
}

String _$usernameChooserHash() => r'689f04c6d7a64758328201ee4e27d96ee696d8a2';

/// The username chooser behind setup step 3 and Edit Profile: four
/// suggestions to pick from, "Show me more", or the user's own text checked
/// against the server as they type.

abstract class _$UsernameChooser extends $Notifier<UsernameChooserState> {
  UsernameChooserState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<UsernameChooserState, UsernameChooserState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<UsernameChooserState, UsernameChooserState>,
              UsernameChooserState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
