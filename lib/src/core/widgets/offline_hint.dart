import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design/app_colors.dart';
import '../services/connectivity_provider.dart';

/// The green-tick reassurance line, shown only while offline: what still
/// works ("Counties you visit are still saved.").
class OfflineHint extends ConsumerWidget {
  const OfflineHint({
    super.key,
    this.text = 'Counties you visit are still saved.',
  });

  final String text;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(connectivityProvider.select((s) => s.isOffline))) {
      return const SizedBox.shrink();
    }
    return OfflineHintBody(text: text);
  }
}

/// The hint itself, for a screen already offline.
class OfflineHintBody extends StatelessWidget {
  const OfflineHintBody({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.check_circle_outline_rounded,
          size: 15,
          color: AppColors.offlineTick,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.offlineBody,
            ),
          ),
        ),
      ],
    );
  }
}

/// An action that needs the network (edit, share, membership): normal
/// online; offline a muted row with the reason, never a dead button.
class UnavailableAction extends ConsumerWidget {
  const UnavailableAction({
    super.key,
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(connectivityProvider.select((s) => s.isOffline))) {
      return child;
    }
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
                color: AppColors.offlinePillIcon,
              ),
            ),
          ),
          const Icon(
            Icons.cloud_off_rounded,
            size: 14,
            color: AppColors.offlinePillIcon,
          ),
          const SizedBox(width: 8),
          const Text(
            'Needs a connection',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }
}
