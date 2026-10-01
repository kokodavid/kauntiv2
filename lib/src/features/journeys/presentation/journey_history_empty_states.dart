import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';

class JourneyHistoryNoMatches extends StatelessWidget {
  const JourneyHistoryNoMatches({
    super.key,
    required this.query,
    required this.onClear,
  });

  final String query;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final trimmed = query.trim();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const _IconBadge(
            iconAsset: 'assets/icons/search_x.svg',
            iconColor: AppColors.mutedForeground,
            backgroundColor: AppColors.lockedFill,
          ),
          const SizedBox(height: 16),
          Text(
            trimmed.isEmpty
                ? 'No Trips match this filter'
                : 'No Trips match "$trimmed"',
            style: AppTypeScale.cardTitle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          const Text(
            'Try a different search or clear the filter to see everything.',
            textAlign: TextAlign.center,
            style: AppTypeScale.body,
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: onClear,
            style: TextButton.styleFrom(
              backgroundColor: AppColors.lockedFill,
              foregroundColor: AppColors.accent,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('Clear filters'),
          ),
        ],
      ),
    );
  }
}

class JourneyHistoryEmptyState extends StatelessWidget {
  const JourneyHistoryEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Column(
        children: [
          _IconBadge(
            iconAsset: 'assets/icons/route.svg',
            iconColor: AppColors.accent,
            backgroundColor: Color(0x1F0A84FF),
          ),
          SizedBox(height: 16),
          Text('No Trips yet', style: AppTypeScale.cardTitle),
          SizedBox(height: 6),
          Text(
            'Start one above and every county you pass through will show '
            'up here, mapped out as you go.',
            textAlign: TextAlign.center,
            style: AppTypeScale.body,
          ),
        ],
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({
    required this.iconAsset,
    required this.iconColor,
    required this.backgroundColor,
  });

  final String iconAsset;
  final Color iconColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
      child: SvgPicture.asset(
        iconAsset,
        width: 28,
        height: 28,
        colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
      ),
    );
  }
}
