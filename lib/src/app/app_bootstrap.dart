import 'package:flutter/widgets.dart';

import '../config/app_config.dart';
import '../services/app_supabase.dart';

Future<void> bootstrapApp(AppConfig config) async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppSupabase.initialize(config);
}
