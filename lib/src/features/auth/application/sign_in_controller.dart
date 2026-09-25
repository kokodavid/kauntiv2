import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/services/app_config_provider.dart';
import '../../onboarding/application/startup_flow.dart';
import '../domain/auth_failure.dart';
import 'auth_providers.dart';

part 'sign_in_controller.g.dart';

/// What the sign-in page shows: which button is busy, and the last error.
class SignInState {
  const SignInState({this.providerInProgress, this.failure});

  /// Busy from the tap until the home-county check after sign-in is done,
  /// so the spinner never drops back to an idle button mid-flow.
  final AppAuthProvider? providerInProgress;
  final AuthFailure? failure;

  String? get errorMessage => failure?.message;
}

/// Google / Apple sign-in for the onboarding page. On success it hands
/// over to [StartupFlow], which checks the saved home county and moves the
/// app on.
@riverpod
class SignInController extends _$SignInController {
  @override
  SignInState build() => const SignInState();

  Future<void> signIn(AppAuthProvider provider) async {
    if (state.providerInProgress != null) return;
    state = SignInState(providerInProgress: provider);

    final failure = await ref
        .read(authServiceProvider)
        .signIn(provider, ref.read(appConfigProvider));
    if (!ref.mounted) return;
    if (failure != null || ref.read(currentUserIdProvider)() == null) {
      state = SignInState(failure: failure);
      return;
    }

    await ref.read(startupFlowProvider.notifier).onSignedIn();
    if (ref.mounted) state = const SignInState();
  }
}
