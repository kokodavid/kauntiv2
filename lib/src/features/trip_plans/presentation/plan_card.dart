import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';
import '../domain/plan_counties.dart';
import '../domain/plan_labels.dart';
import '../domain/trip_plan_summary.dart';
import 'plan_avatar_stack.dart';
import 'plan_route_thumbnail.dart';

/// A plan in the Planned list (design 1b, 1c): route shape, title, dates
/// and days, the counties the saved routes pass through, members on a
/// shared plan, and the muted or past state.
class PlanCard extends StatelessWidget {
  const PlanCard({
    super.key,
    required this.plan,
    required this.claimed,
    this.homeCode,
    this.onTap,
  });

  final TripPlanSummary plan;
  final Set<int> claimed;
  final int? homeCode;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final counties = PlanCounties.of(
      plan.countyCodes,
      claimed: claimed,
      homeCode: homeCode,
    );
    final newCount = counties.where((c) => c.isNew).length;
    final countiesLine = PlanLabels.counties(counties.length, newCount);
    final owner = plan.owner;
    return Material(
      color: AppColors.exploreSurface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.exploreBorder),
          ),
          child: Row(
            children: [
              PlanRouteThumbnail(plan: plan),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            plan.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypeScale.cardTitle,
                          ),
                        ),
                        if (plan.muted)
                          const Padding(
                            padding: EdgeInsets.only(left: 6),
                            child: Icon(
                              Icons.notifications_off_outlined,
                              size: 16,
                              color: AppColors.mutedForeground,
                            ),
                          ),
                      ],
                    ),
                    Text(
                      '${PlanLabels.range(plan.startDate, plan.endDate)}'
                      ' · ${PlanLabels.days(plan.dayCount)}',
                      style: AppTypeScale.small,
                    ),
                    if (countiesLine != null)
                      _CountiesLine(text: countiesLine, newCount: newCount),
                    if (plan.isShared) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          PlanAvatarStack(members: plan.members),
                          const SizedBox(width: 8),
                          Flexible(
                            child: _Tag(
                              text: plan.isOwn || owner?.handle == null
                                  ? '${plan.members.length} planning'
                                  : 'From ${owner!.handle}',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 20,
                color: AppColors.faintForeground,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountiesLine extends StatelessWidget {
  const _CountiesLine({required this.text, required this.newCount});

  final String text;
  final int newCount;

  @override
  Widget build(BuildContext context) {
    final suffix = ' · $newCount new';
    final hasNew = newCount > 0 && text.endsWith(suffix);
    final base = hasNew ? text.substring(0, text.length - suffix.length) : text;
    return Text.rich(
      TextSpan(
        style: AppTypeScale.small,
        children: [
          TextSpan(text: base),
          if (hasNew) ...[
            const TextSpan(text: ' · '),
            TextSpan(
              text: '$newCount new',
              style: const TextStyle(color: AppColors.newCountyText),
            ),
          ],
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: AppColors.accentTint,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTypeScale.meta.copyWith(color: AppColors.accentDark),
    ),
  );
}
