import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/services/app_config_provider.dart';
import '../../../core/services/supabase_client_provider.dart';
import '../data/app_update_repository.dart';
import '../domain/app_update_policy.dart';

part 'app_update_providers.g.dart';

@Riverpod(keepAlive: true)
AppUpdateRepository appUpdateRepository(Ref ref) => AppUpdateRepository(
  ref.watch(supabaseClientProvider),
  ref.watch(appConfigProvider).appReleaseChannel,
);

@Riverpod(keepAlive: true)
class AppUpdateController extends _$AppUpdateController {
  @override
  AppUpdatePolicy? build() => null;

  Future<void> check() async {
    try {
      final repository = ref.read(appUpdateRepositoryProvider);
      final policy = await repository.check();
      if (policy == null) return;
      final dismissed =
          policy.available &&
          !policy.required &&
          policy.latestVersion != null &&
          await repository.wasOptionalDismissed(
            policy.latestVersion.toString(),
          );
      if (ref.mounted) state = dismissed ? null : policy;
    } on Object {
      // Release checking must not strand a user because the network is down.
    }
  }

  Future<void> dismissOptional() async {
    final current = state;
    final version = current?.latestVersion;
    if (current == null || current.required || version == null) return;
    state = null;
    try {
      await ref
          .read(appUpdateRepositoryProvider)
          .dismissOptional(version.toString());
    } on Object {
      // Keep the in-memory dismissal; it can be offered again next launch.
    }
  }

  Future<bool> openStore() =>
      ref.read(appUpdateRepositoryProvider).openStore(state?.storeUrl);
}
