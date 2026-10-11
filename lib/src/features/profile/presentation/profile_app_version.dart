import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_environment.dart';
import '../../../core/services/app_config_provider.dart';
import '../../../core/services/app_version_provider.dart';
import '../../../design/app_colors.dart';

/// "Kaunti47 1.0.3 (42)" at the foot of Profile, so a tester can say which
/// build they are on. The dev build is labelled so it is never mistaken for
/// the store release.
class ProfileAppVersion extends ConsumerWidget {
  const ProfileAppVersion({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final version = ref.watch(appVersionProvider).value;
    if (version == null) return const SizedBox.shrink();
    final isDev =
        ref.watch(appConfigProvider).environment == AppEnvironment.dev;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Center(
        child: Text(
          'Kaunti47 $version${isDev ? ' · dev' : ''}',
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.mutedForeground,
          ),
        ),
      ),
    );
  }
}
