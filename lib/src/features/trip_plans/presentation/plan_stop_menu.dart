import 'package:flutter/material.dart';

import '../../../design/app_colors.dart';

enum PlanStopAction { up, down, moveToDay, note, toPlaces, remove }

/// The "…" on a stop (design 3d): move it, give it a note, or take it off
/// the day. Only shown to people who can edit, and online.
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
  Widget build(BuildContext context) => PopupMenuButton<PlanStopAction>(
    tooltip: 'Stop options',
    constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
    icon: const Icon(Icons.more_horiz, color: AppColors.mutedForeground),
    onSelected: onSelected,
    itemBuilder: (_) => [
      if (canMoveUp)
        const PopupMenuItem(value: PlanStopAction.up, child: Text('Move up')),
      if (canMoveDown)
        const PopupMenuItem(
          value: PlanStopAction.down,
          child: Text('Move down'),
        ),
      if (canMoveToDay)
        const PopupMenuItem(
          value: PlanStopAction.moveToDay,
          child: Text('Move to another day'),
        ),
      PopupMenuItem(
        value: PlanStopAction.note,
        child: Text(hasNote ? 'Edit note' : 'Add a note'),
      ),
      const PopupMenuItem(
        value: PlanStopAction.toPlaces,
        child: Text('Back to Places to visit'),
      ),
      const PopupMenuItem(
        value: PlanStopAction.remove,
        child: Text('Remove from plan'),
      ),
    ],
  );
}
