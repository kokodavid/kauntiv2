import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/config/app_config.dart';
import 'package:kaunti47_v2/src/core/services/app_config_provider.dart';
import 'package:kaunti47_v2/src/counties/county_paths.dart';
import 'package:kaunti47_v2/src/features/auth/application/auth_providers.dart';
import 'package:kaunti47_v2/src/features/auth/application/sign_in_controller.dart';
import 'package:kaunti47_v2/src/features/auth/data/app_auth_service.dart';
import 'package:kaunti47_v2/src/features/auth/domain/auth_failure.dart';
import 'package:kaunti47_v2/src/features/onboarding/application/startup_flow.dart';
import 'package:kaunti47_v2/src/features/onboarding/domain/startup_state.dart';
import 'package:kaunti47_v2/src/features/profile/application/profile_setup_providers.dart';
import 'package:kaunti47_v2/src/features/profile/data/profile_setup_repository.dart';

class _FakeAuth implements AppAuthService {
  AuthFailure? failure;
  final calls = <AppAuthProvider>[];

  @override
  Future<AuthFailure?> signIn(
    AppAuthProvider provider,
    AppConfig config,
  ) async {
    calls.add(provider);
    return failure;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoCounty implements ProfileSetupRepository {
  @override
  Future<CountyPath?> fetchHomeCounty() async => null;

  @override
  Future<void> saveHomeCounty(CountyPath? county) async {}
}

void main() {
  late _FakeAuth auth;
  var signedIn = false;

  ProviderContainer container() {
    final c = ProviderContainer(
      overrides: [
        authServiceProvider.overrideWithValue(auth),
        appConfigProvider.overrideWithValue(const AppConfig.dev()),
        currentUserIdProvider.overrideWithValue(
          () => signedIn ? 'alice' : null,
        ),
        profileSetupRepositoryProvider.overrideWithValue(_NoCounty()),
      ],
    );
    addTearDown(c.dispose);
    // Keep the auto-dispose controller alive between reads.
    c.listen(signInControllerProvider, (_, _) {});
    return c;
  }

  setUp(() {
    auth = _FakeAuth();
    signedIn = false;
  });

  test('a failure shows its message and frees the buttons', () async {
    auth.failure = const AuthFailure(
      AuthFailureKind.cancelled,
      'Sign in was cancelled.',
    );
    final c = container();
    await c
        .read(signInControllerProvider.notifier)
        .signIn(AppAuthProvider.google);
    final state = c.read(signInControllerProvider);
    expect(state.errorMessage, 'Sign in was cancelled.');
    expect(state.providerInProgress, isNull);
  });

  test('success hands over to start-up', () async {
    signedIn = true;
    final c = container();
    await c
        .read(signInControllerProvider.notifier)
        .signIn(AppAuthProvider.apple);
    expect(auth.calls, [AppAuthProvider.apple]);
    expect(c.read(signInControllerProvider).errorMessage, isNull);
    expect(c.read(startupFlowProvider).phase, StartupStep.homeCounty);
  });
}
