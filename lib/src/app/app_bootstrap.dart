import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../core/services/app_config_provider.dart';
import '../core/services/fail_fast.dart';
import '../core/services/supabase_client_provider.dart';
import '../services/app_supabase.dart';
import 'app.dart';

/// Riverpod retries a failed provider on its own (up to 10 times, backing
/// off to several seconds), and shows it as loading the whole time. An
/// offline phone must see "You're offline" at once, so a load that failed
/// for lack of a connection isn't retried (the screens retry when the
/// connection returns), and anything else gets two quick retries.
Duration? _retryFailedLoad(int retryCount, Object error) {
  if (error is OfflineException || retryCount >= 2) return null;
  return Duration(milliseconds: 300 * (retryCount + 1));
}

Future<void> bootstrapApp(AppConfig config) async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppSupabase.initialize(config);
}

/// The widget passed to `runApp`: the app inside its [ProviderScope],
/// with infrastructure providers bound to what [bootstrapApp] set up.
Widget buildAppRoot(AppConfig config) => ProviderScope(
  retry: _retryFailedLoad,
  overrides: [
    appConfigProvider.overrideWithValue(config),
    supabaseClientProvider.overrideWithValue(
      AppSupabase.isInitialized ? AppSupabase.client : null,
    ),
  ],
  child: const App(),
);
