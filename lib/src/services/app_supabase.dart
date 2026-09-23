import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';

class AppSupabase {
  const AppSupabase._();

  static bool _isInitialized = false;

  static bool get isInitialized => _isInitialized;

  static Future<void> initialize(AppConfig config) async {
    if (!config.hasSupabaseConfig) {
      return;
    }

    await Supabase.initialize(
      url: config.supabaseUrl,
      publishableKey: config.supabasePublishableKey,
    );

    _isInitialized = true;
  }

  static SupabaseClient get client {
    if (!_isInitialized) {
      throw StateError(
        'Supabase is not initialized. Provide SUPABASE_URL and '
        'SUPABASE_PUBLISHABLE_KEY at build time.',
      );
    }

    return Supabase.instance.client;
  }
}
