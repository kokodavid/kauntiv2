import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';
import '../domain/plan_labels.dart';
import 'plan_popup_menu.dart';

/// The top of a day card (design 3a): a "DAY 1" pill in the day's colour,
/// the date, the day's own name if it has one, and the fold chevron and
/// "…". Tapping anywhere but the "…" folds the day.
class PlanDayHeader extends StatelessWidget {
  const PlanDayHeader({
    super.key,
    required this.number,
    required this.color,
    required this.collapsed,
    required this.onToggle,
    required this.semanticLabel,
    this.date,
    this.title,
    this.summary,
    this.onRename,
    this.onRemove,
  });

  final int number;
  final Color color;
  final DateTime? date;

  /// The day's own name; null when it is just "Day N".
  final String? title;

  /// Shown under the header while the day is folded.
  final String? summary;
  final bool collapsed;
  final VoidCallback onToggle;
  final String semanticLabel;

  /// Null hides the "…" (read only).
  final VoidCallback? onRename;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    expanded: !collapsed,
    label: semanticLabel,
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 4, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'DAY $number',
                          style: AppTypeScale.pill.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (date != null) ...[
                        const SizedBox(width: 8),
                        Text(PlanLabels.day(date!), style: AppTypeScale.small),
                      ],
                    ],
                  ),
                  if (title != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(title!, style: AppTypeScale.sectionTitle),
                    ),
                  if (collapsed && summary != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(summary!, style: AppTypeScale.small),
                    ),
                ],
              ),
            ),
            Icon(
              collapsed ? Icons.expand_more : Icons.expand_less,
              color: AppColors.mutedForeground,
            ).withTapSize(),
            if (onRename != null)
              PlanPopupMenu<bool>(
                tooltip: 'Day options',
                iconColor: AppColors.mutedForeground,
                onSelected: (rename) => rename ? onRename!() : onRemove?.call(),
                entries: [
                  const PlanMenuEntry(true, 'Rename day'),
                  if (onRemove != null)
                    const PlanMenuEntry(false, 'Remove day', destructive: true),
                ],
              ),
          ],
        ),
      ),
    ),
  );
}

extension on Widget {
  Widget withTapSize() => SizedBox(width: 44, height: 44, child: this);
}
