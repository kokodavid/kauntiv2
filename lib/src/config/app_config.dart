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
    this.firebaseProjectId = '',
    this.firebaseApiKey = '',
    this.firebaseMessagingSenderId = '',
    this.firebaseAndroidAppId = '',
    this.firebaseIosAppId = '',
    this.firebaseIosApiKey = '',
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
      mapboxAccessToken = const String.fromEnvironment('MAPBOX_ACCESS_TOKEN'),
      firebaseProjectId = const String.fromEnvironment('FIREBASE_PROJECT_ID'),
      firebaseApiKey = const String.fromEnvironment('FIREBASE_API_KEY'),
      firebaseMessagingSenderId = const String.fromEnvironment(
        'FIREBASE_MESSAGING_SENDER_ID',
      ),
      firebaseAndroidAppId = const String.fromEnvironment(
        'FIREBASE_ANDROID_APP_ID',
      ),
      firebaseIosAppId = const String.fromEnvironment('FIREBASE_IOS_APP_ID'),
      firebaseIosApiKey = const String.fromEnvironment('FIREBASE_IOS_API_KEY');

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
      mapboxAccessToken = const String.fromEnvironment('MAPBOX_ACCESS_TOKEN'),
      firebaseProjectId = const String.fromEnvironment('FIREBASE_PROJECT_ID'),
      firebaseApiKey = const String.fromEnvironment('FIREBASE_API_KEY'),
      firebaseMessagingSenderId = const String.fromEnvironment(
        'FIREBASE_MESSAGING_SENDER_ID',
      ),
      firebaseAndroidAppId = const String.fromEnvironment(
        'FIREBASE_ANDROID_APP_ID',
      ),
      firebaseIosAppId = const String.fromEnvironment('FIREBASE_IOS_APP_ID'),
      firebaseIosApiKey = const String.fromEnvironment('FIREBASE_IOS_API_KEY');

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

  /// The Firebase project for this environment, used only for push
  /// notifications. All empty means push is off in this build.
  final String firebaseProjectId;
  final String firebaseApiKey;
  final String firebaseMessagingSenderId;
  final String firebaseAndroidAppId;
  final String firebaseIosAppId;

  /// Firebase issues a separate key per platform; empty falls back to
  /// [firebaseApiKey].
  final String firebaseIosApiKey;

  bool get hasMapboxConfig => mapboxAccessToken.isNotEmpty;

  bool get isDev => environment == AppEnvironment.dev;

  bool get hasSupabaseConfig =>
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;
}
