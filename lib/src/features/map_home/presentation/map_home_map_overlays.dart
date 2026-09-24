import 'package:flutter/material.dart';

import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';
import '../domain/map_home_models.dart';

/// Shown while zoomed in: animates the map back to its default projection.
class MapHomeMapResetChip extends StatelessWidget {
  const MapHomeMapResetChip({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Reset the map to its default zoom',
      child: Material(
        color: AppColors.mapOverlayBackground,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.close_fullscreen_rounded,
                  size: 11,
                  color: AppColors.mapOverlayForeground,
                ),
                SizedBox(width: 5),
                Text('RESET', style: AppTextStyles.mapOverlayChip),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Name and status of the county currently pressed (or hovered on desktop).
class MapHomeCountyLabel extends StatelessWidget {
  const MapHomeCountyLabel({super.key, required this.badge});

  final MapHomeCountyBadge badge;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.mapOverlayBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(badge.county.name, style: AppTextStyles.mapOverlayTitle),
            const SizedBox(height: 1),
            Text(
              _statusLabelFor(badge.state),
              style: AppTextStyles.mapOverlayMeta,
            ),
          ],
        ),
      ),
    );
  }
}

String _statusLabelFor(MapHomeCountyBadgeState state) => switch (state) {
  MapHomeCountyBadgeState.earned => 'EARNED',
  MapHomeCountyBadgeState.locked => 'UNCLAIMED',
  MapHomeCountyBadgeState.passedThrough => 'PASSED THROUGH',
  MapHomeCountyBadgeState.pending => 'PENDING',
  MapHomeCountyBadgeState.justUnlocked => 'JUST UNLOCKED',
};
