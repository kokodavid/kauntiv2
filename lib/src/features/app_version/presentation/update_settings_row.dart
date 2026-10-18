import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design/app_colors.dart';
import '../application/app_update_providers.dart';
import 'soft_update_sheet.dart';
import 'update_copy.dart';

/// Whether Profile and Settings should point at a newer release.
bool updateIsAvailable(WidgetRef ref) => ref.watch(
  appUpdateControllerProvider.select((p) => p?.available == true),
);

/// First item in Settings while a newer release exists. Tapping the row
/// reopens the soft sheet with the notes expanded; the pill opens the store.
class UpdateSettingsRow extends ConsumerWidget {
  const UpdateSettingsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final policy = ref.watch(appUpdateControllerProvider);
    if (policy == null || !policy.available) return const SizedBox.shrink();
    final noLink = policy.storeUrl == null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.infoBorder),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => unawaited(
            showSoftUpdateSheet(context, ref, startExpanded: true),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.infoTint,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.download_rounded,
                    size: 20,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        noLink ? 'Update coming soon' : 'Update available',
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.buttonForeground,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        noLink
                            ? 'Version ${policy.latestVersion} is on its way '
                                  'to ${updateStoreName()}'
                            : 'Version ${policy.latestVersion} is ready',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!noLink) ...[
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => unawaited(
                      ref.read(appUpdateControllerProvider.notifier).openStore(),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(64, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: const StadiumBorder(),
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Text('Update'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
