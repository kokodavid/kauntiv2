import 'app_environment.dart';

class AppConfig {
  const AppConfig({
    required this.environment,
    required this.appName,
    required this.supabaseUrl,
    required this.supabasePublishableKey,
    required this.authRedirectUrl,
    required this.googleWebClientId,
    required this.googleIosClientId,
    this.mapboxAccessToken = '',
  });

  const AppConfig.dev()
    : environment = AppEnvironment.dev,
      appName = 'Kaunti47 Dev',
      supabaseUrl = const String.fromEnvironment('SUPABASE_URL'),
      supabasePublishableKey = const String.fromEnvironment(
        'SUPABASE_PUBLISHABLE_KEY',
        defaultValue: String.fromEnvironment('SUPABASE_ANON_KEY'),
      ),
      authRedirectUrl = 'kaunti47-dev://login-callback',
      googleWebClientId = const String.fromEnvironment('GOOGLE_WEB_CLIENT_ID'),
      googleIosClientId = const String.fromEnvironment('GOOGLE_IOS_CLIENT_ID'),
      mapboxAccessToken = const String.fromEnvironment('MAPBOX_ACCESS_TOKEN');

  const AppConfig.prod()
    : environment = AppEnvironment.prod,
      appName = 'Kaunti47',
      supabaseUrl = const String.fromEnvironment('SUPABASE_URL'),
      supabasePublishableKey = const String.fromEnvironment(
        'SUPABASE_PUBLISHABLE_KEY',
        defaultValue: String.fromEnvironment('SUPABASE_ANON_KEY'),
      ),
      authRedirectUrl = 'kaunti47-prod://login-callback',
      googleWebClientId = const String.fromEnvironment('GOOGLE_WEB_CLIENT_ID'),
      googleIosClientId = const String.fromEnvironment('GOOGLE_IOS_CLIENT_ID'),
      mapboxAccessToken = const String.fromEnvironment('MAPBOX_ACCESS_TOKEN');

  final AppEnvironment environment;
  final String appName;
  final String supabaseUrl;
  final String supabasePublishableKey;
  final String authRedirectUrl;
  final String googleWebClientId;
  final String googleIosClientId;

  /// Public Mapbox token for Home's real map. Empty means Home uses the
  /// drawn county map.
  final String mapboxAccessToken;

  bool get hasMapboxConfig => mapboxAccessToken.isNotEmpty;

  bool get hasSupabaseConfig =>
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;
}
