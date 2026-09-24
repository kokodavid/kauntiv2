import 'dart:ui';

import 'package:flutter/material.dart';

import '../../design/app_colors.dart';
import '../../design/app_text_styles.dart';

enum AppNavTab { map, badges, ranks, explore }

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  final AppNavTab selected;
  final ValueChanged<AppNavTab> onSelect;

  static const _tabs = [
    (tab: AppNavTab.map, icon: Icons.home_rounded, label: 'Map'),
    (
      tab: AppNavTab.badges,
      icon: Icons.workspace_premium_outlined,
      label: 'Badges',
    ),
    (tab: AppNavTab.ranks, icon: Icons.bar_chart_rounded, label: 'Ranks'),
    (tab: AppNavTab.explore, icon: Icons.travel_explore, label: 'Explore'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      alignment: Alignment.center,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 300),
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

  final IconData icon;
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
            Icon(icon, size: 16, color: color),
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
