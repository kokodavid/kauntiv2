import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/app_update_providers.dart';
import '../domain/app_update_policy.dart';

class AppUpdateScreen extends ConsumerWidget {
  const AppUpdateScreen({super.key, this.onLater});

  final VoidCallback? onLater;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final policy = ref.watch(appUpdateControllerProvider);
    if (policy == null) return const Scaffold(body: SizedBox.shrink());
    return _UpdateContent(policy: policy, onLater: onLater);
  }
}

class _UpdateContent extends ConsumerWidget {
  const _UpdateContent({required this.policy, this.onLater});

  final AppUpdatePolicy policy;
  final VoidCallback? onLater;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final message = StringBuffer(
      'Kaunti47 ${policy.latestVersion} is available.',
    );
    if (policy.releaseNotes?.isNotEmpty == true) {
      message.write('\n\n${policy.releaseNotes}');
    }
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.system_update_alt, size: 48),
                  const SizedBox(height: 24),
                  Text(
                    policy.required ? 'Update required' : 'Update available',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Text(message.toString(), textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text(
                    'Installed version ${policy.currentVersion}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 28),
                  FilledButton(
                    onPressed: policy.storeUrl == null
                        ? null
                        : () => ref
                            .read(appUpdateControllerProvider.notifier)
                            .openStore(),
                    child: const Text('Update app'),
                  ),
                  TextButton(
                    onPressed: () => ref
                        .read(appUpdateControllerProvider.notifier)
                        .check(),
                    child: const Text('Check again'),
                  ),
                  if (!policy.required) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () async {
                        await ref
                            .read(appUpdateControllerProvider.notifier)
                            .dismissOptional();
                        if (!context.mounted) return;
                        onLater?.call();
                      },
                      child: const Text('Later'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
