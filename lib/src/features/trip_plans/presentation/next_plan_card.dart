import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';
import '../application/planned_trips_list.dart';
import '../application/trip_plans_providers.dart';
import 'plan_card.dart';
import 'planned_view.dart';

/// Home's one card for the next plan (design 6a), replacing the old
/// "Your plans" list. Hidden when there is no plan ahead.
class NextPlanCard extends ConsumerWidget {
  const NextPlanCard({
    super.key,
    required this.onOpenPlan,
    this.homeCountyCode,
  });

  final OpenTripPlan onOpenPlan;
  final int? homeCountyCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(plannedTripsListProvider).value?.plans.next;
    if (plan == null) return const SizedBox.shrink();
    final claimed =
        ref.watch(planClaimedCountyCodesProvider).value ?? const <int>{};
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NEXT TRIP',
            style: AppTypeScale.sectionLabel.copyWith(color: AppColors.accent),
          ),
          const SizedBox(height: 8),
          PlanCard(
            plan: plan,
            claimed: claimed,
            homeCode: homeCountyCode,
            onTap: () => onOpenPlan(context, plan.id),
          ),
        ],
      ),
    );
  }
}
