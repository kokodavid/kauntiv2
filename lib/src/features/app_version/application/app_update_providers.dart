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

  /// Quiet check used at start-up and on resume; failures change nothing.
  Future<void> check() async {
    await recheck();
  }

  /// Like [check] but reports whether the release service was reachable, so
  /// the update screens can show an offline state.
  Future<bool> recheck() async {
    try {
      final policy = await ref.read(appUpdateRepositoryProvider).check();
      if (policy != null && ref.mounted) state = policy;
      return true;
    } on Object {
      // Release checking must not strand a user because the network is down.
      return false;
    }
  }

  static const softSnooze = Duration(days: 7);

  /// Whether the soft sheet should open on its own right now.
  Future<bool> softSheetDue() async {
    final policy = state;
    final version = policy?.latestVersion;
    if (policy == null ||
        !policy.available ||
        policy.required ||
        policy.storeUrl == null ||
        version == null) {
      return false;
    }
    return !await ref
        .read(appUpdateRepositoryProvider)
        .isSoftSnoozed(version.toString(), softSnooze);
  }

  /// "Later", tapping the scrim and swiping down all land here. The
  /// Settings row stays; only the sheet stops showing for a week.
  Future<void> snoozeSoft() async {
    final version = state?.latestVersion;
    if (version == null || state?.required == true) return;
    try {
      await ref
          .read(appUpdateRepositoryProvider)
          .snoozeSoft(version.toString());
    } on Object {
      // Offered again next launch at worst.
    }
  }

  Future<bool> openStore() =>
      ref.read(appUpdateRepositoryProvider).openStore(state?.storeUrl);
}
