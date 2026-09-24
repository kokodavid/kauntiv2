import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../config/app_environment.dart';
import '../core/services/supabase_client_provider.dart';
import '../features/detection/application/detection_providers.dart';
import '../features/detection/domain/visit_rules.dart';
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
    visitTimingsProvider.overrideWithValue(
      config.environment == AppEnvironment.dev
          ? VisitTimings.dev
          : VisitTimings.production,
    ),
  ],
  child: App(config: config),
);
