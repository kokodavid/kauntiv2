import 'package:flutter/material.dart';

import '../../../design/app_colors.dart';
import 'plan_popup_menu.dart';

enum PlanStopAction { up, down, moveToDay, note, open, toPlaces, remove }

/// The "…" on a stop (design 3g): move it, give it a note, open the place,
/// or take it off the day. Only shown to people who can edit, and online.
class PlanStopMenu extends StatelessWidget {
  const PlanStopMenu({
    super.key,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.canMoveToDay,
    required this.hasNote,
    required this.onSelected,
  });

  final bool canMoveUp;
  final bool canMoveDown;
  final bool canMoveToDay;
  final bool hasNote;
  final ValueChanged<PlanStopAction> onSelected;

  @override
  Widget build(BuildContext context) => PlanPopupMenu<PlanStopAction>(
    tooltip: 'Stop options',
    iconColor: AppColors.mutedForeground,
    icon: Icons.more_vert,
    onSelected: onSelected,
    entries: [
      if (canMoveToDay)
        const PlanMenuEntry(
          PlanStopAction.moveToDay,
          'Move to Day…',
          chevron: true,
        ),
      if (canMoveUp) const PlanMenuEntry(PlanStopAction.up, 'Move up'),
      if (canMoveDown) const PlanMenuEntry(PlanStopAction.down, 'Move down'),
      PlanMenuEntry(PlanStopAction.note, hasNote ? 'Edit note' : 'Add a note'),
      const PlanMenuEntry(PlanStopAction.open, 'Open place'),
      const PlanMenuEntry(PlanStopAction.toPlaces, 'Remove from day'),
      const PlanMenuEntry(
        PlanStopAction.remove,
        'Remove from plan',
        destructive: true,
      ),
    ],
  );
}
