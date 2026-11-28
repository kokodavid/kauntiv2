import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design/app_text_styles.dart';
import '../../detection/application/detection_controller.dart';
import '../../detection/domain/detection_status.dart';
import '../application/location_banner_visibility.dart';
import 'map_home_location_copy.dart';

/// What stays on Home once the launch banner has gone: a small pill that
/// says detection is limited; tapping it opens the tiers sheet that explains
/// the options and how to reach "All the time". It rides just above the
/// collapsed bottom sheet (see [MapHomeSheet.aboveSheet]) so it never sits
/// over the map's own controls. Nothing shows when detection is live.
class MapHomeLocationPill extends ConsumerWidget {
  const MapHomeLocationPill({super.key, this.onOpen});

  /// Opens the tiers explainer; null falls back to fixing it directly.
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reason = ref.watch(
      detectionControllerProvider.select((s) => s.status.reason),
    );
    final bannerVisible = ref.watch(locationBannerVisibleProvider);
    // The launch banner holds this spot's message until it has gone.
    if (reason == DetectionReason.none || bannerVisible) {
      return const SizedBox.shrink();
    }
    final controller = ref.read(detectionControllerProvider.notifier);
    final copy = LocationStatusCopy.of(reason);
    void fix() => onOpen != null
        ? onOpen!()
        : unawaited(
            reason == DetectionReason.servicesOff
                ? controller.turnOnLocation()
                : controller.openLocationSettings(),
          );
    return Semantics(
      button: true,
      label: '${copy.title}. ${copy.action}.',
      excludeSemantics: true,
      child: Material(
        color: copy.background,
        shape: StadiumBorder(side: BorderSide(color: copy.border, width: 1.5)),
        child: InkWell(
          onTap: fix,
          customBorder: const StadiumBorder(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 5, 5, 5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_off_outlined, size: 16, color: copy.accent),
                const SizedBox(width: 8),
                Text(
                  copy.pillLabel,
                  style: AppTextStyles.listItemTitle.copyWith(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: copy.ink,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  height: 26,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: copy.accent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Fix',
                    style: AppTextStyles.listItemTitle.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
