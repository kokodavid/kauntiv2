import 'package:flutter/material.dart';

import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';

/// "MAP | REAL" pill in Home's map slot: switches between the drawn county
/// map and the Mapbox map without leaving Home. SPIKE: shown only when a
/// Mapbox token is configured; a real build gates "Real" on Pro.
class MapHomeMapModeToggle extends StatelessWidget {
  const MapHomeMapModeToggle({
    super.key,
    required this.showRealMap,
    required this.onChanged,
  });

  final bool showRealMap;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.mapOverlayBackground,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Segment(
              label: 'MAP',
              icon: Icons.grid_view_rounded,
              selected: !showRealMap,
              onTap: () => onChanged(false),
            ),
            _Segment(
              label: 'REAL · PRO',
              icon: Icons.public,
              selected: showRealMap,
              onTap: () => onChanged(true),
            ),
          ],
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? AppColors.mapOverlayForeground
        : AppColors.mapOverlayMuted;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: selected ? AppColors.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: AppTextStyles.mapOverlayChip.copyWith(color: color),
              ),
            ],
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
