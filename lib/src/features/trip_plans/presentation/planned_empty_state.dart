import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';
import '../domain/plan_limits.dart';
import 'planned_example_day.dart';

/// Planned with no plans yet (design 1a): what a plan looks like, two
/// things it adds, and the free allowance so the 3-day limit is no surprise.
class PlannedEmptyState extends StatelessWidget {
  const PlannedEmptyState({
    super.key,
    required this.limits,
    required this.onPlanTrip,
    this.onFindPlaces,
  });

  final PlanLimits limits;
  final VoidCallback onPlanTrip;
  final VoidCallback? onFindPlaces;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text(
        'Plan your next trip, day by day',
        style: TextStyle(
          fontFamily: AppTypeScale.family,
          fontSize: 22,
          height: 28 / 22,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.22,
          color: AppColors.foreground,
        ),
      ),
      const SizedBox(height: 6),
      const Text(
        'Line up stops, see driving times, and find out which counties '
        "you'll pass for the first time.",
        style: AppTypeScale.body,
      ),
      const SizedBox(height: 16),
      const PlannedExampleDay(),
      const SizedBox(height: 16),
      const _FeatureRow(
        icon: Icons.badge_outlined,
        title: 'New counties, before you go',
        body:
            'Each day shows the counties on the route that would be new in '
            'your Passport.',
      ),
      const SizedBox(height: 12),
      const _FeatureRow(
        icon: Icons.person_add_alt_outlined,
        title: 'Plan with a travel buddy',
        body: 'Invite friends with a link. Everyone edits the same plan.',
      ),
      const SizedBox(height: 20),
      SizedBox(
        height: 52,
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: AppColors.accentForeground,
            shape: const StadiumBorder(),
            textStyle: const TextStyle(
              fontFamily: AppTypeScale.family,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          onPressed: onPlanTrip,
          child: const Text('Plan a trip'),
        ),
      ),
      if (onFindPlaces != null) ...[
        const SizedBox(height: 8),
        SizedBox(
          height: 44,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.foreground,
              backgroundColor: AppColors.exploreSurface,
              side: const BorderSide(color: AppColors.exploreBorder),
              shape: const StadiumBorder(),
              textStyle: const TextStyle(
                fontFamily: AppTypeScale.family,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            onPressed: onFindPlaces,
            child: const Text('Find places in Explore'),
          ),
        ),
      ],
      if (!limits.pro) ...[
        const SizedBox(height: 12),
        Text(
          'Free: ${limits.maxUpcomingPlans ?? 3} upcoming plans, '
          'up to ${limits.maxDays} days each.',
          textAlign: TextAlign.center,
          style: AppTypeScale.meta,
        ),
      ],
    ],
  );
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.accentTint,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: AppColors.accent),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTypeScale.itemTitle),
            Text(body, style: AppTypeScale.small),
          ],
        ),
      ),
    ],
  );
}
