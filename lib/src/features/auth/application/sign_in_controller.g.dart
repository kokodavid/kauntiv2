// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sign_in_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Google / Apple sign-in for the onboarding page. On success it hands
/// over to [StartupFlow], which checks the saved home county and moves the
/// app on.

@ProviderFor(SignInController)
const signInControllerProvider = SignInControllerProvider._();

/// Google / Apple sign-in for the onboarding page. On success it hands
/// over to [StartupFlow], which checks the saved home county and moves the
/// app on.
final class SignInControllerProvider
    extends $NotifierProvider<SignInController, SignInState> {
  /// Google / Apple sign-in for the onboarding page. On success it hands
  /// over to [StartupFlow], which checks the saved home county and moves the
  /// app on.
  const SignInControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'signInControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$signInControllerHash();

  @$internal
  @override
  SignInController create() => SignInController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SignInState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SignInState>(value),
    );
  }
}

String _$signInControllerHash() => r'5ba6bc0344da651d2dbb92c2ddf39b1433465dc5';

/// Google / Apple sign-in for the onboarding page. On success it hands
/// over to [StartupFlow], which checks the saved home county and moves the
/// app on.

abstract class _$SignInController extends $Notifier<SignInState> {
  SignInState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<SignInState, SignInState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SignInState, SignInState>,
              SignInState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
