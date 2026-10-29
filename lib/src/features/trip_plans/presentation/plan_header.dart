import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';
import '../domain/plan_labels.dart';
import '../domain/plan_member.dart';
import '../domain/trip_plan.dart';
import 'plan_avatar_stack.dart';

/// The top of the plan screen (design 3a): back, title, dates, days and
/// who is on it, plus the "view only" and offline notes.
class PlanHeader extends StatelessWidget {
  const PlanHeader({
    super.key,
    required this.plan,
    required this.onBack,
    this.offline = false,
    this.savedAt,
  });

  final TripPlan plan;
  final VoidCallback onBack;
  final bool offline;
  final DateTime? savedAt;

  static String _time(DateTime at) =>
      '${at.hour.toString().padLeft(2, '0')}:'
      '${at.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final dates = plan.startDate == null
        ? 'No date yet'
        : PlanLabels.range(plan.startDate, plan.endDate);
    final joined = plan.members.where((m) => m.joined).toList();
    final notes = [
      if (offline)
        savedAt == null
            ? 'Offline · saved copy'
            : 'Offline · saved copy from ${_time(savedAt!.toLocal())}',
      if (plan.role == PlanRole.viewer) 'View only',
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            tooltip: 'Back',
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.title,
                    style: AppTypeScale.sectionTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$dates · ${PlanLabels.days(plan.days.length)}',
                    style: AppTypeScale.small,
                  ),
                  if (notes.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        notes.join(' · '),
                        style: AppTypeScale.meta.copyWith(
                          color: AppColors.warningText,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (joined.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: PlanAvatarStack(members: joined),
            ),
        ],
      ),
    );
  }
}
