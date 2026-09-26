import 'package:flutter/material.dart';

import '../../../core/domain/county_tier.dart';
import '../../../core/widgets/app_tier_medal.dart';
import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';
import 'map_home_skeleton.dart';

class MapHomeTopBar extends StatelessWidget {
  const MapHomeTopBar({super.key, required this.loading, required this.tier});

  /// While the board loads the medal spot shows a placeholder.
  final bool loading;

  /// The medal earned so far; none shows until the first (10 counties).
  final CountyTier? tier;

  @override
  Widget build(BuildContext context) {
    final tier = this.tier;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Kaunti47',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 28,
            fontWeight: FontWeight.w600,
            height: 36 / 28,
            color: AppColors.foreground,
          ),
        ),
        Row(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: loading
                  ? const _MedalPlaceholder(key: ValueKey('loading'))
                  : tier == null
                  ? const SizedBox.shrink(key: ValueKey('none'))
                  : Padding(
                      key: ValueKey(tier),
                      padding: const EdgeInsets.only(right: 8),
                      child: AppTierPill(tier: tier),
                    ),
            ),
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
              child: const Text(
                'D',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MedalPlaceholder extends StatelessWidget {
  const _MedalPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(right: 8),
      child: MapHomeSkeletonMask(
        child: Text('Mzururaji', style: AppTextStyles.chipLabel),
      ),
    );
  }
}
