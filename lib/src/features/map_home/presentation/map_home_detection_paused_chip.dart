import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';
import '../../detection/application/detection_controller.dart';

/// Shown on Home's map while background location is off, so detection is
/// paused (copy from v1's manual-mode board). Tapping opens the OS
/// settings; the next resume re-checks and the chip goes away.
/// Nothing shows while detection runs.
class MapHomeDetectionPausedChip extends ConsumerWidget {
  const MapHomeDetectionPausedChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paused = ref.watch(
      detectionControllerProvider.select((s) => s.backgroundLocationOff),
    );
    if (!paused) return const SizedBox.shrink();
    return Semantics(
      button: true,
      label:
          "Automatic detection paused. Badges won't unlock automatically "
          'while detection is off. Tap to turn it back on in Settings.',
      child: Material(
        color: AppColors.mapOverlayBackground,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: () => unawaited(
            ref
                .read(detectionControllerProvider.notifier)
                .openLocationSettings(),
          ),
          borderRadius: BorderRadius.circular(999),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.location_off_rounded,
                  size: 12,
                  color: AppColors.mapOverlayMuted,
                ),
                SizedBox(width: 5),
                Text(
                  'AUTOMATIC DETECTION PAUSED',
                  style: AppTextStyles.mapOverlayChip,
                ),
                SizedBox(width: 8),
                Text('TURN ON', style: AppTextStyles.mapOverlayChip),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
