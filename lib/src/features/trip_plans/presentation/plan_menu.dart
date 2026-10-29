import 'package:flutter/material.dart';

enum PlanMenuAction { rename, dates, archive, delete }

/// The plan's "…" (design 3a): rename, change dates, and for the owner
/// archive or delete.
class PlanMenu extends StatelessWidget {
  const PlanMenu({super.key, required this.isOwner, required this.onSelected});

  final bool isOwner;
  final ValueChanged<PlanMenuAction> onSelected;

  @override
  Widget build(BuildContext context) => PopupMenuButton<PlanMenuAction>(
    tooltip: 'Plan options',
    constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
    onSelected: onSelected,
    itemBuilder: (_) => [
      const PopupMenuItem(
        value: PlanMenuAction.rename,
        child: Text('Rename plan'),
      ),
      const PopupMenuItem(
        value: PlanMenuAction.dates,
        child: Text('Change start date'),
      ),
      if (isOwner)
        const PopupMenuItem(
          value: PlanMenuAction.archive,
          child: Text('Archive plan'),
        ),
      if (isOwner)
        const PopupMenuItem(
          value: PlanMenuAction.delete,
          child: Text('Delete plan'),
        ),
    ],
  );
}
