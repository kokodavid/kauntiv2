import 'package:flutter/material.dart';

import '../../../design/app_colors.dart';
import 'plan_pro_sheet.dart';

/// One row of a planner "…" menu.
class PlanMenuEntry<T> {
  const PlanMenuEntry(
    this.value,
    this.label, {
    this.enabled = true,
    this.pro = false,
    this.destructive = false,
    this.chevron = false,
  });

  final T value;
  final String label;
  final bool enabled;

  /// Shows the PRO tag.
  final bool pro;

  /// Red text.
  final bool destructive;

  /// A ">" at the end: the row opens a choice.
  final bool chevron;
}

/// The planner's "…" menu (design 3g): a white card of plain rows with
/// thin dividers. Plan, day and stop menus all use it.
class PlanPopupMenu<T> extends StatelessWidget {
  const PlanPopupMenu({
    super.key,
    required this.tooltip,
    required this.entries,
    required this.onSelected,
    this.iconColor = AppColors.foreground,
  });

  final String tooltip;
  final List<PlanMenuEntry<T>> entries;
  final ValueChanged<T> onSelected;
  final Color iconColor;

  @override
  Widget build(BuildContext context) => PopupMenuButton<T>(
    tooltip: tooltip,
    constraints: const BoxConstraints(minWidth: 220, maxWidth: 280),
    padding: EdgeInsets.zero,
    offset: const Offset(0, 40),
    color: AppColors.exploreSurface,
    surfaceTintColor: Colors.transparent,
    elevation: 8,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    icon: SizedBox(
      width: 44,
      height: 44,
      child: Icon(Icons.more_horiz, color: iconColor),
    ),
    onSelected: onSelected,
    itemBuilder: (_) => [
      for (var i = 0; i < entries.length; i++)
        PopupMenuItem<T>(
          value: entries[i].value,
          enabled: entries[i].enabled,
          padding: EdgeInsets.zero,
          height: 52,
          child: _Row(entries[i], last: i == entries.length - 1),
        ),
    ],
  );
}

class _Row extends StatelessWidget {
  const _Row(this.entry, {required this.last});

  final PlanMenuEntry<dynamic> entry;
  final bool last;

  @override
  Widget build(BuildContext context) => Container(
    height: 52,
    padding: const EdgeInsets.symmetric(horizontal: 20),
    decoration: BoxDecoration(
      border: last
          ? null
          : const Border(bottom: BorderSide(color: AppColors.exploreBorder)),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            entry.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: entry.destructive
                  ? AppColors.danger
                  : AppColors.foreground,
            ),
          ),
        ),
        if (entry.pro) const PlanProTag(),
        if (entry.chevron)
          const Icon(
            Icons.chevron_right,
            size: 20,
            color: AppColors.mutedForeground,
          ),
      ],
    ),
  );
}
