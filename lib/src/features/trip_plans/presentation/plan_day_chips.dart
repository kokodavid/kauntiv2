import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';
import 'plan_day_colors.dart';

/// The sticky row of day chips (design 3a): All, then Day 1 to Day N in
/// each day's colour. Picking one frames that day on the map and jumps to
/// it in the list.
class PlanDayChipsDelegate extends SliverPersistentHeaderDelegate {
  const PlanDayChipsDelegate({
    required this.dayNumbers,
    required this.active,
    required this.onSelect,
  });

  final List<int> dayNumbers;

  /// The chosen day, or null for All.
  final int? active;
  final ValueChanged<int?> onSelect;

  static const height = 56.0;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  bool shouldRebuild(PlanDayChipsDelegate old) =>
      old.active != active ||
      old.dayNumbers.length != dayNumbers.length ||
      old.onSelect != onSelect;

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
          color: AppColors.ink,
          selected: active == null,
          onTap: () => onSelect(null),
        ),
        for (final n in dayNumbers)
          _Chip(
            label: 'Day $n',
            color: PlanDayColors.of(n),
            selected: active == n,
            onTap: () => onSelect(n),
          ),
      ],
    ),
  );
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: selected ? color : AppColors.exploreSurface,
        shape: StadiumBorder(
          side: BorderSide(color: selected ? color : AppColors.exploreBorder),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            child: Text(
              label,
              style: AppTypeScale.action.copyWith(
                color: selected ? Colors.white : AppColors.ink,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
