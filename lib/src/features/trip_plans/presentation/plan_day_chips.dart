import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';
import '../domain/plan_labels.dart';
import '../domain/trip_plan.dart';
import 'plan_day_colors.dart';

/// The sticky row of day chips (design 3a, 3b): All days, then "Day 1 · Sat"
/// with the day's colour dot, then "+ Day" for people who can edit. Picking
/// one frames that day on the map and jumps to it in the list.
class PlanDayChipsDelegate extends SliverPersistentHeaderDelegate {
  const PlanDayChipsDelegate({
    required this.plan,
    required this.active,
    required this.onSelect,
    this.onAddDay,
  });

  final TripPlan plan;

  /// The chosen day, or null for All.
  final int? active;
  final ValueChanged<int?> onSelect;

  /// Null hides "+ Day".
  final VoidCallback? onAddDay;

  static const height = 56.0;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  bool shouldRebuild(PlanDayChipsDelegate old) =>
      old.active != active ||
      old.plan != plan ||
      old.onSelect != onSelect ||
      (old.onAddDay == null) != (onAddDay == null);

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => Material(
    color: AppColors.pageBackground,
    elevation: overlapsContent ? 1 : 0,
    child: ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      children: [
        _Chip(
          label: 'All days',
          selected: active == null,
          onTap: () => onSelect(null),
        ),
        for (final day in plan.days)
          _Chip(
            label: _label(day.number, plan.dateOf(day)),
            dot: PlanDayColors.of(day.number),
            selected: active == day.number,
            onTap: () => onSelect(day.number),
          ),
        if (onAddDay != null) _AddDayChip(onTap: onAddDay!),
      ],
    ),
  );

  static String _label(int number, DateTime? date) => date == null
      ? 'Day $number'
      : 'Day $number · ${PlanLabels.day(date).split(' ').first}';
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.dot,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// The day's colour; none on "All days".
  final Color? dot;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: selected ? AppColors.accent : AppColors.exploreSurface,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? AppColors.accent : AppColors.exploreBorder,
          ),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (dot != null) ...[
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: selected ? Colors.white : dot,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: AppTypeScale.action.copyWith(
                    color: selected
                        ? AppColors.accentForeground
                        : AppColors.foreground,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// "+ Day": a dashed outline that adds the next day.
class _AddDayChip extends StatelessWidget {
  const _AddDayChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Add a day',
    child: CustomPaint(
      foregroundPainter: const _DashedStadium(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          child: Text(
            '+ Day',
            style: AppTypeScale.action.copyWith(color: AppColors.accent),
          ),
        ),
      ),
    ),
  );
}

class _DashedStadium extends CustomPainter {
  const _DashedStadium();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = AppColors.infoBorder;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(size.height / 2),
        ),
      );
    for (final PathMetric metric in path.computeMetrics()) {
      for (var at = 0.0; at < metric.length; at += 8) {
        canvas.drawPath(metric.extractPath(at, at + 4), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedStadium old) => false;
}
