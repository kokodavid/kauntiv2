import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/config/app_config.dart';
import 'package:kaunti47_v2/src/config/app_environment.dart';

void main() {
  group('AppConfig', () {
    test('dev uses the dev environment, label and redirect', () {
      const config = AppConfig.dev();

      expect(config.environment, AppEnvironment.dev);
      expect(config.appName, 'Kaunti47 Dev');
      expect(config.authRedirectUrl, 'kaunti47-dev://login-callback');
    });

    test('prod uses the prod environment, label and redirect', () {
      const config = AppConfig.prod();

      expect(config.environment, AppEnvironment.prod);
      expect(config.appName, 'Kaunti47');
      expect(config.authRedirectUrl, 'kaunti47-prod://login-callback');
    });

    test('reports missing Supabase config when no defines are passed', () {
      expect(const AppConfig.dev().hasSupabaseConfig, isFalse);
    });

    test('has no Mapbox token without defines, so Home uses the drawn map', () {
      expect(const AppConfig.dev().hasMapboxConfig, isFalse);
      expect(const AppConfig.prod().mapboxAccessToken, isEmpty);
    });
  });
}
