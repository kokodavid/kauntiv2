import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/app/app_routes.dart';
import 'package:kaunti47_v2/src/features/onboarding/domain/startup_state.dart';

void main() {
  test('each start-up step owns its page', () {
    expect(AppRoutes.redirect(StartupStep.splash, '/map'), AppRoutes.splash);
    expect(AppRoutes.redirect(StartupStep.signIn, '/splash'), AppRoutes.signIn);
    expect(
      AppRoutes.redirect(StartupStep.homeCounty, '/sign-in'),
      AppRoutes.homeCounty,
    );
    expect(
      AppRoutes.redirect(StartupStep.preferences, '/home-county'),
      AppRoutes.preferences,
    );
    expect(
      AppRoutes.redirect(StartupStep.permission, '/county/47'),
      AppRoutes.permission,
    );
    expect(AppRoutes.redirect(StartupStep.signIn, '/sign-in'), isNull);
  });

  test('only the three setup steps are numbered', () {
    expect(StartupStep.homeCounty.setupNumber, 1);
    expect(StartupStep.preferences.setupNumber, 2);
    expect(StartupStep.permission.setupNumber, 3);
    expect(StartupStep.signIn.setupNumber, isNull);
    expect(StartupStep.ready.setupNumber, isNull);
  });

  test('once ready, gate pages go to Map and the rest stay', () {
    for (final gate in [
      '/splash',
      '/sign-in',
      '/home-county',
      '/preferences',
      '/permission',
    ]) {
      expect(AppRoutes.redirect(StartupStep.ready, gate), AppRoutes.map);
    }
    expect(AppRoutes.redirect(StartupStep.ready, '/map'), isNull);
    expect(AppRoutes.redirect(StartupStep.ready, '/explore'), isNull);
    expect(AppRoutes.redirect(StartupStep.ready, '/county/47'), isNull);
  });

  test('a required update overrides sign-in and setup gates', () {
    expect(
      AppRoutes.redirect(
        StartupStep.preferences,
        AppRoutes.preferences,
        updateRequired: true,
      ),
      AppRoutes.updateRequired,
    );
  });

  test('optional updates prompt only after onboarding is ready', () {
    expect(
      AppRoutes.redirect(
        StartupStep.preferences,
        AppRoutes.preferences,
        updateAvailable: true,
      ),
      isNull,
    );
    expect(
      AppRoutes.redirect(
        StartupStep.ready,
        AppRoutes.map,
        updateAvailable: true,
      ),
      AppRoutes.updateAvailable,
    );
    expect(
      AppRoutes.redirect(
        StartupStep.ready,
        AppRoutes.updateAvailable,
        updateAvailable: true,
      ),
      isNull,
    );
    expect(
      AppRoutes.redirect(StartupStep.ready, AppRoutes.updateAvailable),
      AppRoutes.map,
    );
  });
}
