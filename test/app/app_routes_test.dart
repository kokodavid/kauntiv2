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
      AppRoutes.redirect(StartupStep.permission, '/county/47'),
      AppRoutes.permission,
    );
    expect(AppRoutes.redirect(StartupStep.signIn, '/sign-in'), isNull);
  });

  test('once ready, gate pages go to Map and the rest stay', () {
    for (final gate in ['/splash', '/sign-in', '/home-county', '/permission']) {
      expect(AppRoutes.redirect(StartupStep.ready, gate), AppRoutes.map);
    }
    expect(AppRoutes.redirect(StartupStep.ready, '/map'), isNull);
    expect(AppRoutes.redirect(StartupStep.ready, '/explore'), isNull);
    expect(AppRoutes.redirect(StartupStep.ready, '/county/47'), isNull);
  });
}
