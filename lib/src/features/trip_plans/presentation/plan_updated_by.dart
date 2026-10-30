import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../domain/plan_labels.dart';
import '../domain/trip_plan.dart';
import 'plan_avatar_stack.dart';

/// "Updated by nyati7 just now" (design 3b), with their avatar. Only on a
/// shared plan, and only when it is known who and when.
class PlanUpdatedBy extends StatelessWidget {
  const PlanUpdatedBy({super.key, required this.plan});

  final TripPlan plan;

  @override
  Widget build(BuildContext context) {
    final handle = plan.updatedByHandle;
    final ago = plan.isShared
        ? PlanLabels.ago(plan.updatedAt, DateTime.now())
        : null;
    if (handle == null || ago == null) return const SizedBox.shrink();
    final who = plan.members.where((m) => m.handle == handle).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 16, 0),
      child: Row(
        children: [
          if (who.isNotEmpty) ...[
            PlanAvatarStack(members: who, size: 22, max: 1),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text('Updated by $handle $ago', style: AppTypeScale.small),
          ),
        ],
      ),
    );
  }
}
