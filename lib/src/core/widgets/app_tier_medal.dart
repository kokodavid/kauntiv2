import 'package:flutter/material.dart';

import '../../design/app_colors.dart';
import '../design/app_type_scale.dart';
import '../domain/county_tier.dart';

/// A tier's medal artwork (silver, bronze, gold; `assets/images/Tier N.png`,
/// 90 x 107).
class AppTierMedal extends StatelessWidget {
  const AppTierMedal({super.key, required this.tier, this.height = 24});

  final CountyTier tier;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/Tier ${tier.number}.png',
      height: height,
      width: height * 90 / 107,
      fit: BoxFit.contain,
      semanticLabel: '${tier.label} medal',
    );
  }
}

/// The earned tier as a pill: medal and name (Home, Badges). Callers show
/// it only once a tier is earned.
class AppTierPill extends StatelessWidget {
  const AppTierPill({super.key, required this.tier});

  final CountyTier tier;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.fromLTRB(6, 0, 12, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.trackInactive),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTierMedal(tier: tier),
          const SizedBox(width: 6),
          Text(
            tier.label,
            style: const TextStyle(
              fontFamily: AppTypeScale.family,
              fontWeight: FontWeight.w500,
              fontSize: 12,
              height: 20 / 12,
              color: AppColors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }
}
