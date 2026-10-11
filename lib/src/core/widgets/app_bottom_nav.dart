import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../design/app_colors.dart';
import '../../design/app_text_styles.dart';
import '../../widgets/app_county_shape.dart';
import '../domain/app_feature_flags.dart';

enum AppNavTab { map, badges, ranks, explore, journeys }

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  final AppNavTab selected;
  final ValueChanged<AppNavTab> onSelect;

  static const _tabs = [
    // Null icon: the Map tab draws Kenya's outline.
    (tab: AppNavTab.map, icon: null, label: 'Map'),
    (
      tab: AppNavTab.badges,
      icon: Icons.workspace_premium_outlined,
      label: 'Badges',
    ),
    if (AppFeatureFlags.ranks)
      (tab: AppNavTab.ranks, icon: Icons.bar_chart_rounded, label: 'Ranks'),
    (tab: AppNavTab.explore, icon: Icons.travel_explore, label: 'Explore'),
    if (AppFeatureFlags.journeys)
      (tab: AppNavTab.journeys, icon: Icons.route_rounded, label: 'Trips'),
  ];

  /// Gap under the floating bar. The app draws edge to edge (no
  /// SafeArea), so on Android the bar has to lift itself above the system
  /// navigation bar (buttons or gesture pill). iPhones already sit clear of
  /// the home indicator at the design's 24.
  static double bottomGap(BuildContext context) {
    if (defaultTargetPlatform != TargetPlatform.android) return 24;
    return math.max(24, MediaQuery.viewPaddingOf(context).bottom + 8);
  }

  /// The pill itself: 4 padding, a 45 tab, 4 padding.
  static const barHeight = 53.0;

  /// Room a screen's own bottom content must leave for the bar: the gap
  /// under it, the bar, and a little air. Sheets and lists read this
  /// rather than a fixed number, so they follow the nav on every phone.
  static double clearance(BuildContext context) =>
      bottomGap(context) + barHeight + 7;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 16, 24, bottomGap(context)),
      alignment: Alignment.center,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            // Wider when the fifth (Journeys) tab is on.
            constraints: BoxConstraints(maxWidth: _tabs.length > 4 ? 360 : 300),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.tabBarShell,
              borderRadius: BorderRadius.circular(999),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A000000),
                  offset: Offset(0, 2),
                  blurRadius: 17,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final entry in _tabs)
                  Expanded(
                    child: _NavTabButton(
                      icon: entry.icon,
                      label: entry.label,
                      isActive: entry.tab == selected,
                      onTap: () => onSelect(entry.tab),
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

class _NavTabButton extends StatelessWidget {
  const _NavTabButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData? icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.accent : AppColors.mutedForeground;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.tabPillBackground : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon case final icon?)
              Icon(icon, size: 16, color: color)
            else
              SizedBox.square(
                dimension: 16,
                child: AppCountryShape(fill: color),
              ),
            const SizedBox(height: 2),
            Text(
              label,
              style: isActive
                  ? AppTextStyles.tabBarLabelActive
                  : AppTextStyles.tabBarLabelInactive,
            ),
          ],
        ),
      ),
    );
  }
}
