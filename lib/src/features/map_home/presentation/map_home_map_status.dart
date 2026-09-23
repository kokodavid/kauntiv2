import 'package:flutter/material.dart';

import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';

/// Shown on the drawn map when the real (Mapbox) map couldn't load: says
/// Home is on the offline map and offers a retry. Home never swaps maps on
/// its own mid-session; only this retry (or reopening Home) tries again.
class MapHomeOfflineMapChip extends StatelessWidget {
  const MapHomeOfflineMapChip({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Offline map. Tap to load the full map again.',
      child: Material(
        color: AppColors.mapOverlayBackground,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: onRetry,
          borderRadius: BorderRadius.circular(999),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.cloud_off_rounded,
                  size: 12,
                  color: AppColors.mapOverlayMuted,
                ),
                SizedBox(width: 5),
                Text('OFFLINE MAP', style: AppTextStyles.mapOverlayChip),
                SizedBox(width: 8),
                Icon(
                  Icons.refresh_rounded,
                  size: 12,
                  color: AppColors.mapOverlayForeground,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Soft fade behind the status bar and top bar when the real map runs
/// edge to edge, so "Kaunti47" and the tier chip stay readable on terrain
/// and satellite imagery. Must sit directly in the board's Stack.
class MapHomeHeaderScrim extends StatelessWidget {
  const MapHomeHeaderScrim({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: MediaQuery.paddingOf(context).top + 96,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.pageBackground.withValues(alpha: 0.95),
                AppColors.pageBackground.withValues(alpha: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
