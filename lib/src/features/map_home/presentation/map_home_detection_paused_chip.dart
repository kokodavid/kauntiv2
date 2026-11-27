import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';
import '../../detection/application/detection_controller.dart';

/// Shown on Home's map while detection can't run (copy from v1's
/// manual-mode board): either location is switched off for the whole phone,
/// or background location was taken away from the app. Tapping turns
/// location on (Android asks in place) or opens the OS settings; the next
/// check clears the chip. Nothing shows while detection runs.
class MapHomeDetectionPausedChip extends ConsumerWidget {
  const MapHomeDetectionPausedChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (servicesOff, permissionOff) = ref.watch(
      detectionControllerProvider.select(
        (s) => (s.locationServicesOff, s.backgroundLocationOff),
      ),
    );
    if (!servicesOff && !permissionOff) return const SizedBox.shrink();
    final controller = ref.read(detectionControllerProvider.notifier);
    return Semantics(
      button: true,
      label: servicesOff
          ? "Location is off. Counties won't update until it's back on. "
                'Tap to turn it on.'
          : 'Counties update only while Kaunti47 is open. Tap to allow '
                'location all the time in Settings.',
      child: Material(
        color: AppColors.mapOverlayBackground,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: () => unawaited(
            servicesOff
                ? controller.turnOnLocation()
                : controller.openLocationSettings(),
          ),
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.location_off_rounded,
                  size: 12,
                  color: AppColors.mapOverlayMuted,
                ),
                const SizedBox(width: 5),
                Text(
                  servicesOff
                      ? 'LOCATION IS OFF'
                      : 'BACKGROUND DETECTION OFF',
                  style: AppTextStyles.mapOverlayChip,
                ),
                const SizedBox(width: 8),
                const Text('TURN ON', style: AppTextStyles.mapOverlayChip),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
