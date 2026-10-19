import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../design/app_colors.dart';
import '../../design/app_text_styles.dart';
import '../../widgets/app_county_shape.dart';
import 'app_glyph_icon.dart';
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
    (tab: AppNavTab.map, icon: null, glyph: null, label: 'Map'),
    // The booklet from the Passport design, not a Material icon.
    (
      tab: AppNavTab.badges,
      icon: null,
      glyph: AppGlyphPaths.passport,
      label: 'Passport',
    ),
    if (AppFeatureFlags.ranks)
      (
        tab: AppNavTab.ranks,
        icon: Icons.bar_chart_rounded,
        glyph: null,
        label: 'Ranks',
      ),
    (
      tab: AppNavTab.explore,
      icon: Icons.travel_explore,
      glyph: null,
      label: 'Explore',
    ),
    if (AppFeatureFlags.journeys)
      (
        tab: AppNavTab.journeys,
        icon: Icons.route_rounded,
        glyph: null,
        label: 'Trips',
      ),
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
      child: RepaintBoundary(
        child: Container(
          // Wider when the fifth (Journeys) tab is on.
          constraints: BoxConstraints(maxWidth: _tabs.length > 4 ? 360 : 300),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            // Keep the glass treatment inexpensive while content scrolls
            // beneath the floating navigation.
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
          child: Stack(
            children: [
              // One pill that glides to the chosen tab, rather than two pills
              // fading in and out in place.
              Positioned.fill(
                child: AnimatedAlign(
                  duration: _slide,
                  curve: Curves.easeInOutCubic,
                  alignment: Alignment(_pillX, 0),
                  child: FractionallySizedBox(
                    widthFactor: 1 / _tabs.length,
                    heightFactor: 1,
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.tabPillBackground,
                            AppColors.tabPillWashEnd,
                          ],
                        ),
                        border: Border.fromBorderSide(
                          BorderSide(color: AppColors.tabPillEdge),
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(999)),
                      ),
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  for (final entry in _tabs)
                    Expanded(
                      child: _NavTabButton(
                        icon: entry.icon,
                        glyph: entry.glyph,
                        label: entry.label,
                        isActive: entry.tab == selected,
                        onTap: () => onSelect(entry.tab),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// How long the pill takes to glide (and the icon and label to follow).
  /// Raise it to slow the whole effect down, lower it to speed it up.
  static const _slide = Duration(milliseconds: 450);

  /// Where the pill sits, from -1 (first tab) to 1 (last).
  double get _pillX {
    final index = _tabs.indexWhere((t) => t.tab == selected);
    if (index < 0 || _tabs.length < 2) return -1;
    return -1 + 2 * index / (_tabs.length - 1);
  }
}

class _NavTabButton extends StatelessWidget {
  const _NavTabButton({
    required this.icon,
    required this.glyph,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData? icon;

  /// A drawn glyph instead of [icon] (the Passport booklet).
  final Path Function()? glyph;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.accent : AppColors.mutedForeground;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // A small lift on the chosen tab, in step with the pill.
            AnimatedScale(
              scale: isActive ? 1.12 : 1,
              duration: AppBottomNav._slide,
              curve: Curves.easeOutBack,
              child: TweenAnimationBuilder<Color?>(
                tween: ColorTween(end: color),
                duration: AppBottomNav._slide,
                builder: (context, tint, _) {
                  final shade = tint ?? color;
                  if (glyph != null) {
                    return AppGlyphIcon(
                      path: glyph!,
                      size: 17,
                      color: shade,
                      strokeWidth: 2,
                    );
                  }
                  return icon == null
                      ? SizedBox.square(
                          dimension: 16,
                          child: AppCountryShape(fill: shade),
                        )
                      : Icon(icon, size: 16, color: shade);
                },
              ),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: AppBottomNav._slide,
              curve: Curves.easeInOutCubic,
              style: isActive
                  ? AppTextStyles.tabBarLabelActive
                  : AppTextStyles.tabBarLabelInactive,
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
