import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';
import '../domain/plan_member.dart';
import '../domain/trip_plan.dart';
import 'plan_idea_card.dart';
import 'plan_stop_row.dart';

/// "Places to visit" (design 3a, 3b): places picked for the plan but not on
/// a day yet, as cards you scroll sideways, between the day chips and the
/// days. Hidden when there are none and this person can't add any.
class PlanPlacesRow extends StatelessWidget {
  const PlanPlacesRow({
    super.key,
    required this.ideas,
    required this.members,
    this.showAddedBy = false,
    this.onOpenPlace,
    this.onAdd,
    this.onAddToDay,
  });

  final List<PlanIdea> ideas;
  final List<PlanMember> members;
  final bool showAddedBy;
  final OpenPlanPlace? onOpenPlace;

  /// Opens Add places for the list (people who can edit).
  final VoidCallback? onAdd;

  /// Puts an idea on a day (people who can edit).
  final ValueChanged<PlanIdea>? onAddToDay;

  @override
  Widget build(BuildContext context) {
    if (ideas.isEmpty && onAdd == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    ideas.isEmpty
                        ? 'PLACES TO VISIT'
                        : 'PLACES TO VISIT · ${ideas.length}',
                    style: AppTypeScale.sectionLabel,
                  ),
                ),
                if (onAdd != null)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.accent,
                      textStyle: AppTypeScale.action,
                      minimumSize: const Size(44, 44),
                    ),
                    onPressed: onAdd,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add places'),
                  ),
              ],
            ),
          ),
          if (ideas.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                'Save places here, then put them on a day.',
                style: AppTypeScale.small,
              ),
            )
          else
            SizedBox(
              height: onAddToDay == null ? 148 : 204,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                itemCount: ideas.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (_, i) => PlanIdeaCard(
                  idea: ideas[i],
                  adder: showAddedBy
                      ? members
                            .where((m) => m.handle == ideas[i].addedByHandle)
                            .firstOrNull
                      : null,
                  onOpen: onOpenPlace,
                  onAddToDay: onAddToDay == null
                      ? null
                      : () => onAddToDay!(ideas[i]),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
