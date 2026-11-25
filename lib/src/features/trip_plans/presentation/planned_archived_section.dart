import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';
import '../application/trip_plans_providers.dart';
import '../domain/plan_labels.dart';
import '../domain/trip_plan_summary.dart';
import 'plan_archive_actions.dart';
import 'plan_card.dart';
import 'planned_archived_row.dart';

/// Archived plans at the bottom of Planned: a quiet row that opens to
/// dimmed cards, each with Restore. Empty when nothing is archived.
class PlannedArchivedSection extends ConsumerWidget {
  const PlannedArchivedSection({
    super.key,
    required this.plans,
    required this.open,
    required this.onToggle,
    this.onOpenPlan,
    this.homeCode,
  });

  final List<TripPlanSummary> plans;
  final bool open;
  final VoidCallback onToggle;
  final void Function(BuildContext context, String planId)? onOpenPlan;
  final int? homeCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (plans.isEmpty) return const SizedBox.shrink();
    final claimed = ref.watch(planClaimedCountyCodesProvider).value ?? <int>{};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PlannedArchivedRow(count: plans.length, open: open, onTap: onToggle),
        if (open)
          for (final plan in plans)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: PlanCard(
                plan: plan,
                claimed: claimed,
                homeCode: homeCode,
                dateLine: _line(plan),
                dimmed: true,
                onTap: onOpenPlan == null
                    ? null
                    : () => onOpenPlan!(context, plan.id),
                action: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.accentTint,
                    foregroundColor: AppColors.accent,
                    textStyle: AppTypeScale.action,
                    minimumSize: const Size(44, 34),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: const StadiumBorder(),
                  ),
                  onPressed: () => unawaited(
                    PlanArchiveActions(context, ref).restore(plan.id),
                  ),
                  child: const Text('Restore'),
                ),
              ),
            ),
      ],
    );
  }

  /// "Archived 3 d ago", or the trip dates when it was a while back.
  static String _line(TripPlanSummary plan) {
    final ago = PlanLabels.ago(plan.updatedAt, DateTime.now());
    return ago != null
        ? 'Archived $ago'
        : 'Archived · ${PlanLabels.range(plan.startDate, plan.endDate)}';
  }
}
