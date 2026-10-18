import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/services/app_config_provider.dart';
import '../../../core/services/app_version_provider.dart';
import '../../../core/services/supabase_client_provider.dart';
import '../data/push_device_repository.dart';
import '../data/push_messaging_service.dart';
import '../domain/push_destination.dart';
import 'push_registrar.dart';

part 'push_providers.g.dart';

/// Firebase for this build's environment (dev and prod each have their own
/// project, from the dart-defines).
@Riverpod(keepAlive: true)
PushMessagingService pushMessagingService(Ref ref) {
  final config = ref.watch(appConfigProvider);
  return FirebasePushMessagingService(
    FirebaseSettings(
      projectId: config.firebaseProjectId,
      apiKey: config.firebaseApiKey,
      messagingSenderId: config.firebaseMessagingSenderId,
      androidAppId: config.firebaseAndroidAppId,
      iosAppId: config.firebaseIosAppId,
    ),
  );
}

@riverpod
PushDeviceRepository? pushDeviceRepository(Ref ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? null : SupabasePushDeviceRepository(client);
}

@Riverpod(keepAlive: true)
PushRegistrar pushRegistrar(Ref ref) {
  final config = ref.watch(appConfigProvider);
  return PushRegistrar(
    service: ref.watch(pushMessagingServiceProvider),
    repository: ref.watch(pushDeviceRepositoryProvider),
    flavor: config.isDev ? 'dev' : 'prod',
    appVersion: () => ref.read(appVersionProvider.future),
  );
}
