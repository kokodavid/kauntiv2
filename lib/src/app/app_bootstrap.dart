import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../core/services/supabase_client_provider.dart';
import '../services/app_supabase.dart';
import 'app.dart';

Future<void> bootstrapApp(AppConfig config) async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppSupabase.initialize(config);
}

/// The widget passed to `runApp`: the app inside its [ProviderScope],
/// with infrastructure providers bound to what [bootstrapApp] set up.
Widget buildAppRoot(AppConfig config) => ProviderScope(
  overrides: [
    supabaseClientProvider.overrideWithValue(
      AppSupabase.isInitialized ? AppSupabase.client : null,
    ),
  ],
  child: App(config: config),
);
