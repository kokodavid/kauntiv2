import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';
import '../domain/plan_limits.dart';
import 'planned_example_loop.dart';

/// Planned with no plans yet (design 1a-A): a looping example plan, two
/// things plans add, and the free allowance so the 3-day limit is no
/// surprise.
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
      // Air above the loop so it sits nearer the middle of the page.
      const SizedBox(height: 28),
      const PlannedExampleLoop(),
      const SizedBox(height: 14),
      const Text(
        'No plans yet',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: AppTypeScale.family,
          fontSize: 18,
          height: 24 / 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.18,
          color: AppColors.foreground,
        ),
      ),
      const SizedBox(height: 14),
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
      const SizedBox(height: 18),
      SizedBox(
        height: 52,
        child: FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: AppColors.accentForeground,
            shape: const StadiumBorder(),
            textStyle: const TextStyle(
              fontFamily: AppTypeScale.family,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          onPressed: onPlanTrip,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Plan a trip'),
        ),
      ),
      if (onFindPlaces != null) ...[
        const SizedBox(height: 4),
        TextButton.icon(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.accentDark,
            minimumSize: const Size.fromHeight(44),
            shape: const StadiumBorder(),
            textStyle: const TextStyle(
              fontFamily: AppTypeScale.family,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          onPressed: onFindPlaces,
          icon: const Icon(Icons.search, size: 16),
          label: const Text('Browse places in Explore'),
        ),
      ],
      if (!limits.pro) ...[
        const SizedBox(height: 10),
        Text(
          'Free · ${limits.maxUpcomingPlans ?? 3} plans · '
          'up to ${limits.maxDays} days each',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: AppTypeScale.family,
            fontSize: 11,
            height: 16 / 11,
            letterSpacing: 0.3,
            color: AppColors.faintForeground,
          ),
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
