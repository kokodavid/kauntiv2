import 'package:flutter/material.dart';

import 'src/app/app_bootstrap.dart';
import 'src/config/app_config.dart';

Future<void> main() async {
  const config = AppConfig.dev();

  await bootstrapApp(config);

  runApp(buildAppRoot(config));
}
