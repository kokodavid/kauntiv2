import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../config/app_config.dart';

part 'app_config_provider.g.dart';

/// The build's [AppConfig] (dev or prod). Overridden once at start-up by
/// `buildAppRoot` in `app/app_bootstrap.dart`.
@Riverpod(keepAlive: true)
AppConfig appConfig(Ref ref) => throw UnimplementedError(
  'appConfigProvider is overridden at start-up (buildAppRoot).',
);
